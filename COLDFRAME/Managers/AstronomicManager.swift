//
//  AstronomicManager.swift
//  COLDFRAME
//
//  Created by Mo on 17/12/2025.
//

import Foundation
import CoreLocation
import SwiftAA

enum AstronomicManager {
    
    static func getSolarData(for location: CLLocation, date: Date = Date()) async -> [PrayerTime] {
        let geo = GeographicCoordinates(
            positivelyWestwardLongitude: Degree(-location.coordinate.longitude),
            latitude: Degree(location.coordinate.latitude)
        )
        
        let sun = Sun(julianDay: JulianDay(date))
        let earth = Earth(julianDay: JulianDay(date))
        
        func format(_ date: Date) -> (String, Date) {
            let timeString = date.formatted(date: .omitted, time: .shortened)
            return (timeString, date)
        }
        
        var results: [PrayerTime] = []
        
        // 1. Dhuhr : Transit (Point le plus haut)
        let transitRts = sun.riseTransitSetTimes(for: geo)
        if let dhuhrDate = transitRts.transitTime?.date {
            results.append(PrayerTime(name: String(localized: "prayer_dhuhr"), time: format(dhuhrDate).0, date: dhuhrDate, icon: "sun.max.fill"))
        }
        
        // 2. Fajr (-18°) - Heure de lever correspondante (crépuscule)
        let fajrRts = earth.twilights(forSunAltitude: Degree(-18.0), coordinates: geo)
        if let fajrDate = fajrRts.riseTime?.date {
            results.append(PrayerTime(name: String(localized: "prayer_fajr"), time: format(fajrDate).0, date: fajrDate, icon: "sun.haze.fill"))
        }
        
        // 3. Asr (Ombre = Ombre à midi + 1)
        let declination = sun.equatorialCoordinates.declination.value
        let latitude = geo.latitude.value
        
        // Calcul de l'altitude requise pour Asr (Shafi'i/Maliki/Hanbali)
        let shadowAtNoon = tan(abs(latitude - declination) * .pi / 180.0)
        let asrAltitude = atan(1.0 / (shadowAtNoon + 1.0)) * 180.0 / .pi
        
        let asrRts = earth.twilights(forSunAltitude: Degree(asrAltitude), coordinates: geo)
        if let asrDate = asrRts.setTime?.date {
            results.append(PrayerTime(name: String(localized: "prayer_asr"), time: format(asrDate).0, date: asrDate, icon: "sun.min.fill"))
        }
        
        // 4. Maghrib (-0.833°) - Couché du soleil
        let maghribRts = earth.twilights(forSunAltitude: Degree(-0.833), coordinates: geo)
        if let maghribDate = maghribRts.setTime?.date {
            results.append(PrayerTime(name: String(localized: "prayer_maghrib"), time: format(maghribDate).0, date: maghribDate, icon: "sunset.fill"))
        }
        
        // 5. Isha (-17°) - Fin du crépuscule
        let ishaRts = earth.twilights(forSunAltitude: Degree(-17.0), coordinates: geo)
        if let ishaDate = ishaRts.setTime?.date {
            results.append(PrayerTime(name: String(localized: "prayer_isha"), time: format(ishaDate).0, date: ishaDate, icon: "moon.stars.fill"))
        }
        
        return results.sorted { $0.date < $1.date }
    }

    static func getMoonPhase(for date: Date = Date()) async -> (name: String, icon: String, phaseDays: Double, illuminatedFraction: Double) {
        let moon = Moon(julianDay: JulianDay(date))
        
        // Calcul manuel de l'âge de la lune en jours (Date actuelle - Dernière nouvelle lune)
        let lastNewMoon = moon.time(of: .newMoon, forward: false)
        let phaseDays = moon.julianDay.value - lastNewMoon.value
        
        let name: String
        let icon: String
        
        switch phaseDays {
        case 0..<1.84: name = String(localized: "moon_new_moon"); icon = "moonphase.new.moon"
        case 1.84..<5.53: name = String(localized: "moon_waxing_crescent"); icon = "moonphase.waxing.crescent"
        case 5.53..<9.22: name = String(localized: "moon_first_quarter"); icon = "moonphase.first.quarter"
        case 9.22..<12.91: name = String(localized: "moon_waxing_gibbous"); icon = "moonphase.waxing.gibbous"
        case 12.91..<16.61: name = String(localized: "moon_full_moon"); icon = "moonphase.full.moon"
        case 16.61..<20.30: name = String(localized: "moon_waning_gibbous"); icon = "moonphase.waning.gibbous"
        case 20.30..<23.99: name = String(localized: "moon_last_quarter"); icon = "moonphase.last.quarter"
        case 23.99..<27.68: name = String(localized: "moon_waning_crescent"); icon = "moonphase.waning.crescent"
        default: name = String(localized: "moon_new_moon"); icon = "moonphase.new.moon"
        }

        return (name, icon, phaseDays, moon.illuminatedFraction())
    }

    static func getHilalObservation(
        for date: Date = Date(),
        maghribDate: Date?,
        location: CLLocation?
    ) async -> HilalObservationData {
        guard let location = location else {
            return HilalObservationData(visibility: .impossible)
        }
        
        let geo = GeographicCoordinates(
            positivelyWestwardLongitude: Degree(-location.coordinate.longitude),
            latitude: Degree(location.coordinate.latitude),
            altitude: Meter(location.altitude > -100 ? location.altitude : 0.0)
        )

        let targetDate = maghribDate ?? date
        let jd = JulianDay(targetDate)
        let moon = Moon(julianDay: jd)

        // 1. Calcul via le module complet Hilal.swift de SwiftAA
        let odehResult = moon.crescentVisibility(for: geo, criterion: .odeh)
        let yallopResult = moon.crescentVisibility(for: geo, criterion: .yallop)

        // 2. Coordonnées horizontales et azimut
        let bestMoon = Moon(julianDay: odehResult.bestObservationTime)
        let moonHoriz = bestMoon.makeHorizontalCoordinates(with: geo)

        let observerAlt = location.altitude > -100 ? location.altitude : 0.0
        let horizonDip = 0.0293 * sqrt(max(0.0, observerAlt))
        let moonAltitude = odehResult.moonTopocentricAltitude.value + horizonDip

        let astronomicalAzimuth = moonHoriz.azimuth.value
        let compassAzimuth = (astronomicalAzimuth + 180.0).truncatingRemainder(dividingBy: 360.0)

        let baseVisibility = HilalVisibility(zone: odehResult.zone)

        return HilalObservationData(
            visibility: baseVisibility,
            azimuthDegrees: compassAzimuth,
            moonAltitudeDegrees: moonAltitude,
            moonAgeHours: odehResult.moonAge.value,
            elongationDegrees: odehResult.elongation.value,
            observerAltitudeMeters: observerAlt,
            odehVValue: odehResult.qValue,
            odehZone: odehResult.zone.rawValue,
            yallopQValue: yallopResult.qValue,
            yallopZone: yallopResult.zone.rawValue,
            arcOfVisionDegrees: odehResult.arcOfVision.value,
            azimuthDifferenceDegrees: odehResult.differenceInAzimuth.value,
            crescentWidthArcminutes: odehResult.crescentWidth.value,
            moonLagMinutes: odehResult.lagTime.value,
            sunsetTime: odehResult.sunsetTime.date,
            moonsetTime: odehResult.moonsetTime.date,
            bestObservationTime: odehResult.bestObservationTime.date,
            weatherConditions: nil,
            terrainProfile: nil,
            isAnalyzingTerrain: false,
            isFetchingWeather: false
        )
    }

    static func getLiveMoonPosition(for date: Date = Date(), location: CLLocation) async -> LiveMoonPosition {
        let geo = GeographicCoordinates(
            positivelyWestwardLongitude: Degree(-location.coordinate.longitude),
            latitude: Degree(location.coordinate.latitude)
        )
        let jd = JulianDay(date)
        let moon = Moon(julianDay: jd)
        let sun = Sun(julianDay: jd)

        let moonHorizontal = moon.makeHorizontalCoordinates(with: geo)
        let sunHorizontal = sun.makeHorizontalCoordinates(with: geo)

        let observerAlt = location.altitude > -100 ? location.altitude : 0.0
        let horizonDip = 0.0293 * sqrt(max(0.0, observerAlt))

        let moonAltitude = moonHorizontal.altitude.value + horizonDip
        let astronomicalMoonAzimuth = moonHorizontal.azimuth.value
        let moonCompassAzimuth = (astronomicalMoonAzimuth + 180.0).truncatingRemainder(dividingBy: 360.0)

        let sunAltitude = sunHorizontal.altitude.value
        let astronomicalSunAzimuth = sunHorizontal.azimuth.value
        let sunCompassAzimuth = (astronomicalSunAzimuth + 180.0).truncatingRemainder(dividingBy: 360.0)

        let elongation = moon.equatorialCoordinates.angularSeparation(with: sun.equatorialCoordinates).value
        let illumination = moon.illuminatedFraction()

        let trajectory = await getMoonTrajectory(for: date, location: location)

        return LiveMoonPosition(
            azimuthDegrees: moonCompassAzimuth,
            altitudeDegrees: moonAltitude,
            sunAzimuthDegrees: sunCompassAzimuth,
            sunAltitudeDegrees: sunAltitude,
            elongationDegrees: elongation,
            illuminatedFraction: illumination,
            trajectory: trajectory,
            skyline: []
        )
    }

    static func getMoonTrajectory(for date: Date = Date(), location: CLLocation) async -> [MoonTrajectoryPoint] {
        let geo = GeographicCoordinates(
            positivelyWestwardLongitude: Degree(-location.coordinate.longitude),
            latitude: Degree(location.coordinate.latitude)
        )
        let observerAlt = location.altitude > -100 ? location.altitude : 0.0
        let horizonDip = 0.0293 * sqrt(max(0.0, observerAlt))

        var points: [MoonTrajectoryPoint] = []
        let calendar = Calendar.current
        for offsetMinutes in stride(from: -180, through: 360, by: 30) {
            guard let sampleDate = calendar.date(byAdding: .minute, value: offsetMinutes, to: date) else { continue }
            let jd = JulianDay(sampleDate)
            let moon = Moon(julianDay: jd)
            let horiz = moon.makeHorizontalCoordinates(with: geo)
            let alt = horiz.altitude.value + horizonDip
            let astroAz = horiz.azimuth.value
            let compAz = (astroAz + 180.0).truncatingRemainder(dividingBy: 360.0)
            let timeStr = sampleDate.formatted(date: .omitted, time: .shortened)
            points.append(
                MoonTrajectoryPoint(
                    date: sampleDate,
                    azimuthDegrees: compAz,
                    altitudeDegrees: alt,
                    formattedTime: timeStr
                )
            )
        }
        return points
    }
}
