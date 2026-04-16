//
//  MileageTracker.swift
//  Fleet-Tracker
//

import Foundation
import CoreLocation
import Combine

enum DriveStatus {
    case notStarted   // before first movement
    case driving      // actively moving
    case onBreak      // manually paused by employee
    case stopped      // auto-paused due to no movement
}

final class MileageTracker: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var status:        DriveStatus = .notStarted
    @Published var totalMiles:    Double      = 0.0
    @Published var sessionMiles:  Double      = 0.0   // miles since last break
    @Published var breakCount:    Int         = 0
    @Published var driveStarted:  Date?       = nil

    // Auto-stop threshold — if speed drops below this for stopTimeout seconds, mark as stopped
    private let stopSpeedMPH:     Double      = 2.0
    private let stopTimeout:      TimeInterval = 30.0
    private let minAccuracyMeters: Double     = 20.0   // ignore low-accuracy pings

    private var lastLocation:     CLLocation?
    private var stoppedSince:     Date?
    private var segments: [(start: Date, end: Date?, miles: Double, type: String)] = []
    private var segmentStart:     Date?
    private var segmentMiles:     Double = 0.0

    // ── Control ───────────────────────────────────────────────────────────────

    func startTracking() {
        guard status == .notStarted else { return }
        status       = .driving
        driveStarted = Date()
        segmentStart = Date()
        segmentMiles = 0
    }

    func takeBreak() {
        guard status == .driving || status == .stopped else { return }
        endCurrentSegment(type: "drive")
        status = .onBreak
        breakCount += 1
        segmentStart = Date()
        segmentMiles = 0
    }

    func resumeDriving() {
        guard status == .onBreak else { return }
        endCurrentSegment(type: "break")
        status       = .driving
        segmentStart = Date()
        segmentMiles = 0
        lastLocation = nil  // reset so we don't count distance during break
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
        status        = .notStarted
        totalMiles    = 0
        sessionMiles  = 0
        breakCount    = 0
        driveStarted  = nil
        lastLocation  = nil
        stoppedSince  = nil
        segments      = []
        segmentStart  = nil
        segmentMiles  = 0
    }

    // ── Location update ───────────────────────────────────────────────────────

    func processLocation(_ location: CLLocation) {
        // Ignore inaccurate pings
        guard location.horizontalAccuracy <= minAccuracyMeters,
              location.horizontalAccuracy >= 0 else { return }

        let speedMPH = max(0, location.speed * 2.23694)

        if status == .driving || status == .stopped {
            // Auto-stop detection
            if speedMPH < stopSpeedMPH {
                if stoppedSince == nil { stoppedSince = Date() }
                if let since = stoppedSince, Date().timeIntervalSince(since) > stopTimeout {
                    if status == .driving { status = .stopped }
                }
            } else {
                stoppedSince = nil
                if status == .stopped { status = .driving }
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

        lastLocation = location
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
