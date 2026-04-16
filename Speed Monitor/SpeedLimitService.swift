//
//  SpeedLimitService.swift
//  Fleet-Tracker
//
//  Uses the Google Roads API to fetch the posted speed limit for a coordinate.
//  Results are cached by grid cell (0.001 degree ≈ 100m) to avoid hammering the API.
//  Falls back to 50 mph if the API call fails or returns no data.
//
//  SETUP: Add your Google API key to Info.plist as "GoogleMapsAPIKey"
//  Make sure the "Roads API" is enabled in your Google Cloud Console project.
//

import Foundation
import CoreLocation

final class SpeedLimitService {

    static let shared = SpeedLimitService()

    // Fallback when API has no data for a road
    static let fallbackLimitMPH: Double = 50

    // Cache: grid key → speed limit in MPH
    // Grid cells are ~100m squares — good enough for speed limit zones
    private var cache: [String: Double] = [:]

    // Pending requests keyed by grid cell — prevents duplicate API calls
    private var pendingKeys: Set<String> = []

    private var apiKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String
    }

    private init() {}

    // ── Grid key ──────────────────────────────────────────────────────────────
    // Rounds coordinates to 3 decimal places (~100m precision)

    private func gridKey(lat: Double, lon: Double) -> String {
        let gridLat = (lat * 1000).rounded() / 1000
        let gridLon = (lon * 1000).rounded() / 1000
        return "\(gridLat),\(gridLon)"
    }

    // ── Public fetch ──────────────────────────────────────────────────────────

    /// Returns cached limit immediately if available, otherwise fetches from API.
    /// Calls `completion` on the main thread with the limit in MPH.
    func speedLimit(at location: CLLocationCoordinate2D,
                    completion: @escaping (Double) -> Void) {
        let key = gridKey(lat: location.latitude, lon: location.longitude)

        // Return cached value instantly
        if let cached = cache[key] {
            completion(cached)
            return
        }

        // Don't fire duplicate requests for the same cell
        guard !pendingKeys.contains(key) else { return }
        pendingKeys.insert(key)

        fetchFromAPI(lat: location.latitude, lon: location.longitude) { [weak self] limit in
            guard let self else { return }
            let result = limit ?? Self.fallbackLimitMPH
            self.cache[key] = result
            self.pendingKeys.remove(key)
            DispatchQueue.main.async { completion(result) }
        }
    }

    // ── Cached lookup (sync, no API call) ─────────────────────────────────────
    /// Returns cached limit or fallback without triggering a fetch.
    func cachedLimit(at location: CLLocationCoordinate2D) -> Double {
        let key = gridKey(lat: location.latitude, lon: location.longitude)
        return cache[key] ?? Self.fallbackLimitMPH
    }

    // ── Google Roads API ──────────────────────────────────────────────────────

    private func fetchFromAPI(lat: Double, lon: Double,
                               completion: @escaping (Double?) -> Void) {
        guard let key = apiKey, !key.isEmpty else {
            print("SpeedLimitService: No GoogleMapsAPIKey in Info.plist — using fallback")
            completion(nil)
            return
        }

        // Snap to roads first, then get speed limit
        // The Roads API requires points to be on a road — snapToRoads handles this
        let urlStr = "https://roads.googleapis.com/v1/speedLimits"
            + "?path=\(lat),\(lon)"
            + "&key=\(key)"

        guard let url = URL(string: urlStr) else { completion(nil); return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data, error == nil else { completion(nil); return }

            do {
                if let json     = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let limits   = json["speedLimits"] as? [[String: Any]],
                   let first    = limits.first,
                   let limitVal = first["speedLimit"] as? Double,
                   let units    = first["units"] as? String {

                    // Always return MPH — convert KPH to MPH if needed
                    let mph = units == "MPH" ? limitVal : limitVal / 1.60934
                    completion(mph)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }.resume()
    }
}
