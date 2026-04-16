//
//  MileageTracker.swift
//  Fleet-Tracker
//

import Foundation
import CoreLocation
import Combine

enum DriveStatus {
    case notStarted   // clocked in, never started driving
    case driving      // actively moving, mileage tracking on
    case onBreak      // was driving, manually paused — will resume driving
    case notDriving   // clocked in but chose not to drive today
    case stopped      // auto-paused — vehicle not moving
}

final class MileageTracker: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var status:        DriveStatus = .notStarted
    @Published var totalMiles:    Double      = 0.0
    @Published var sessionMiles:  Double      = 0.0
    @Published var breakCount:    Int         = 0
    @Published var driveStarted:  Date?       = nil

    // Route path — stored as flat array of lat/lon pairs for persistence
    @Published var routeCoordinates: [(Double, Double)] = []

    private let stopSpeedMPH:     Double      = 2.0
    private let stopTimeout:      TimeInterval = 30.0
    private let minAccuracyMeters: Double     = 50.0

    private var lastLocation:     CLLocation?
    private var stoppedSince:     Date?
    private var hasMovedOnce:     Bool = false   // don't auto-stop until first real movement
    private var segments: [(start: Date, end: Date?, miles: Double, type: String)] = []
    private var segmentStart:     Date?
    private var segmentMiles:     Double = 0.0

    // ── Persistence keys ──────────────────────────────────────────────────────
    private let kStatus       = "tracker_status"
    private let kTotalMiles   = "tracker_totalMiles"
    private let kBreakCount   = "tracker_breakCount"
    private let kDriveStarted = "tracker_driveStarted"
    private let kRoute        = "tracker_route"

    override init() {
        super.init()
        restoreFromDefaults()
    }

    private func restoreFromDefaults() {
        let ud = UserDefaults.standard
        if let s = ud.string(forKey: kStatus) {
            switch s {
            case "driving":    status = .driving
            case "onBreak":    status = .onBreak
            case "notDriving": status = .notDriving
            case "stopped":    status = .stopped
            default:           status = .notStarted
            }
        }
        totalMiles   = ud.double(forKey: kTotalMiles)
        breakCount   = ud.integer(forKey: kBreakCount)
        driveStarted = ud.object(forKey: kDriveStarted) as? Date
        if let raw = ud.array(forKey: kRoute) as? [[Double]] {
            routeCoordinates = raw.compactMap {
                guard $0.count == 2 else { return nil }
                return ($0[0], $0[1])
            }
        }
    }

    private func saveToDefaults() {
        let ud = UserDefaults.standard
        let s: String
        switch status {
        case .driving:    s = "driving"
        case .onBreak:    s = "onBreak"
        case .notDriving: s = "notDriving"
        case .stopped:    s = "stopped"
        case .notStarted: s = "notStarted"
        }
        ud.set(s, forKey: kStatus)
        ud.set(totalMiles,   forKey: kTotalMiles)
        ud.set(breakCount,   forKey: kBreakCount)
        ud.set(driveStarted, forKey: kDriveStarted)
        let raw = routeCoordinates.map { [$0.0, $0.1] }
        ud.set(raw, forKey: kRoute)
    }

    // ── Control ───────────────────────────────────────────────────────────────

    func startTracking() {
        guard status == .notStarted else { return }
        status       = .driving
        driveStarted = Date()
        segmentStart = Date()
        segmentMiles = 0
        saveToDefaults()
    }

    func takeBreak() {
        guard status == .driving || status == .stopped else { return }
        endCurrentSegment(type: "drive")
        status = .onBreak
        breakCount += 1
        segmentStart = Date()
        segmentMiles = 0
        saveToDefaults()
    }

    func resumeDriving() {
        guard status == .onBreak || status == .notDriving else { return }
        if status == .onBreak { endCurrentSegment(type: "break") }
        status       = .driving
        segmentStart = Date()
        segmentMiles = 0
        lastLocation = nil
        saveToDefaults()
    }

    func stopDriving() {
        // Employee is clocked in but not driving — mileage tracking paused
        guard status == .driving || status == .stopped else { return }
        endCurrentSegment(type: "drive")
        status = .notDriving
        lastLocation = nil
        saveToDefaults()
    }

    func stopTracking() -> MileageSummary {
        if status == .driving || status == .stopped {
            endCurrentSegment(type: "drive")
        } else if status == .onBreak {
            endCurrentSegment(type: "break")
        }
        status = .notStarted

        let driveSegments = segments.filter { $0.type == "drive" }
        let breakSegments = segments.filter { $0.type == "break" }
        let totalBreakMin = breakSegments.reduce(0.0) { sum, seg in
            let end = seg.end ?? Date()
            return sum + end.timeIntervalSince(seg.start) / 60
        }

        return MileageSummary(
            totalMiles:       totalMiles,
            driveSegments:    driveSegments.count,
            breakCount:       breakCount,
            totalBreakMinutes: Int(totalBreakMin),
            startedAt:        driveStarted,
            endedAt:          Date()
        )
    }

    func reset() {
        status           = .notStarted
        totalMiles       = 0
        sessionMiles     = 0
        breakCount       = 0
        driveStarted     = nil
        lastLocation     = nil
        stoppedSince     = nil
        hasMovedOnce     = false
        segments         = []
        segmentStart     = nil
        segmentMiles     = 0
        routeCoordinates = []
        let ud = UserDefaults.standard
        ud.removeObject(forKey: kStatus)
        ud.removeObject(forKey: kTotalMiles)
        ud.removeObject(forKey: kBreakCount)
        ud.removeObject(forKey: kDriveStarted)
        ud.removeObject(forKey: kRoute)
    }

    // ── Location update ───────────────────────────────────────────────────────

    func processLocation(_ location: CLLocation) {
        // Ignore inaccurate pings
        guard location.horizontalAccuracy <= minAccuracyMeters,
              location.horizontalAccuracy >= 0 else { return }

        let speedMPH = max(0, location.speed * 2.23694)

        // Auto-start if clocked in but tracker hasn't started yet
        if status == .notStarted {
            startTracking()
        }

        if status == .driving || status == .stopped {
            // Track first real movement
            if speedMPH >= stopSpeedMPH { hasMovedOnce = true }

            // Auto-stop detection — only after employee has moved at least once
            if hasMovedOnce {
                if speedMPH < stopSpeedMPH {
                    if stoppedSince == nil { stoppedSince = Date() }
                    if let since = stoppedSince, Date().timeIntervalSince(since) > stopTimeout {
                        if status == .driving { status = .stopped }
                    }
                } else {
                    stoppedSince = nil
                    if status == .stopped { status = .driving }
                }
            }

            // Calculate distance only when driving and speed is meaningful
            if status == .driving, speedMPH >= stopSpeedMPH, let last = lastLocation {
                let distanceMeters = location.distance(from: last)
                let distanceMiles  = distanceMeters / 1609.344

                // Sanity check — ignore jumps over 0.5 miles between pings
                if distanceMiles < 0.5 {
                    totalMiles   += distanceMiles
                    sessionMiles += distanceMiles
                    segmentMiles += distanceMiles
                }
            }
        }

        // Track route for map drawing
        routeCoordinates.append((location.coordinate.latitude, location.coordinate.longitude))
        lastLocation = location
        saveToDefaults()
    }

    // ── Segment helpers ───────────────────────────────────────────────────────

    private func endCurrentSegment(type: String) {
        let start = segmentStart ?? Date()
        segments.append((start: start, end: Date(), miles: segmentMiles, type: type))
    }
}

// ── Summary model ─────────────────────────────────────────────────────────────

struct MileageSummary {
    let totalMiles:        Double
    let driveSegments:     Int
    let breakCount:        Int
    let totalBreakMinutes: Int
    let startedAt:         Date?
    let endedAt:           Date

    var totalMilesRounded: String { String(format: "%.1f", totalMiles) }
}
