//
//  WeatherService.swift
//  COLDFRAME
//
//  Created by Mo on 26/08/2026.
//

import Foundation
import CoreLocation

actor WeatherService {
    static let shared = WeatherService()

    private var cache: [String: (conditions: WeatherConditions, timestamp: Date)] = [:]
    private let cacheValiditySeconds: TimeInterval = 1800 // 30 minutes

    private init() {}

    func fetchObservationWeather(
        for location: CLLocationCoordinate2D,
        targetTime: Date = Date()
    ) async -> WeatherConditions? {
        let cacheKey = "\(location.latitude.formatted(.number.precision(.fractionLength(2))))_\(location.longitude.formatted(.number.precision(.fractionLength(2))))"
        if let cached = cache[cacheKey], Date().timeIntervalSince(cached.timestamp) < cacheValiditySeconds {
            return cached.conditions
        }

        let latStr = location.latitude.formatted(.number.precision(.fractionLength(4)).locale(Locale(identifier: "en_US")))
        let lonStr = location.longitude.formatted(.number.precision(.fractionLength(4)).locale(Locale(identifier: "en_US")))

        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latStr)&longitude=\(lonStr)&hourly=cloud_cover,cloud_cover_low,cloud_cover_mid,cloud_cover_high,visibility,relative_humidity_2m,temperature_2m&timezone=UTC&forecast_days=2"

        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            let decoder = JSONDecoder()
            let forecast = try decoder.decode(OpenMeteoResponse.self, from: data)

            // Trouver l'index de l'heure la plus proche de targetTime
            let targetTimestamp = targetTime.timeIntervalSince1970
            var closestIndex = 0
            var minDiff: TimeInterval = .greatestFiniteMagnitude

            for (index, timeStr) in forecast.hourly.time.enumerated() {
                // Open-Meteo renvoie "2026-08-26T20:00"
                let date = (try? Date(timeStr + ":00Z", strategy: .iso8601)) ?? (try? Date(timeStr, strategy: .iso8601))
                if let date = date {
                    let diff = abs(date.timeIntervalSince1970 - targetTimestamp)
                    if diff < minDiff {
                        minDiff = diff
                        closestIndex = index
                    }
                }
            }

            let conditions = WeatherConditions(
                cloudCoverTotalPercent: forecast.hourly.cloudCover[safe: closestIndex] ?? 0,
                cloudCoverLowPercent: forecast.hourly.cloudCoverLow[safe: closestIndex] ?? 0,
                cloudCoverMidPercent: forecast.hourly.cloudCoverMid[safe: closestIndex] ?? 0,
                cloudCoverHighPercent: forecast.hourly.cloudCoverHigh[safe: closestIndex] ?? 0,
                visibilityMeters: forecast.hourly.visibility[safe: closestIndex] ?? 10000.0,
                relativeHumidityPercent: forecast.hourly.relativeHumidity2m[safe: closestIndex] ?? 50,
                temperatureCelsius: forecast.hourly.temperature2m[safe: closestIndex] ?? 20.0,
                observationTargetTime: targetTime
            )

            cache[cacheKey] = (conditions, Date())
            return conditions
        } catch {
            return nil
        }
    }
}

// MARK: - Décodage Open-Meteo
private nonisolated struct OpenMeteoResponse: Decodable, Sendable {
    let hourly: OpenMeteoHourly
}

private nonisolated struct OpenMeteoHourly: Decodable, Sendable {
    let time: [String]
    let cloudCover: [Int]
    let cloudCoverLow: [Int]
    let cloudCoverMid: [Int]
    let cloudCoverHigh: [Int]
    let visibility: [Double]
    let relativeHumidity2m: [Int]
    let temperature2m: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case cloudCover = "cloud_cover"
        case cloudCoverLow = "cloud_cover_low"
        case cloudCoverMid = "cloud_cover_mid"
        case cloudCoverHigh = "cloud_cover_high"
        case visibility
        case relativeHumidity2m = "relative_humidity_2m"
        case temperature2m = "temperature_2m"
    }
}

private extension Array {
    nonisolated subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
