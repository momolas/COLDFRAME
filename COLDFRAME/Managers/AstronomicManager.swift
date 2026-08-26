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
            results.append(PrayerTime(name: "Dhuhr", time: format(dhuhrDate).0, date: dhuhrDate, icon: "sun.max.fill"))
        }
        
        // 2. Fajr (-18°) - Heure de lever correspondante (crépuscule)
        let fajrRts = earth.twilights(forSunAltitude: Degree(-18.0), coordinates: geo)
        if let fajrDate = fajrRts.riseTime?.date {
            results.append(PrayerTime(name: "Fajr", time: format(fajrDate).0, date: fajrDate, icon: "sun.haze.fill"))
        }
        
        // 3. Asr (Ombre = Ombre à midi + 1)
        let declination = sun.equatorialCoordinates.declination.value
        let latitude = geo.latitude.value
        
        // Calcul de l'altitude requise pour Asr (Shafi'i/Maliki/Hanbali)
        let shadowAtNoon = tan(abs(latitude - declination) * .pi / 180.0)
        let asrAltitude = atan(1.0 / (shadowAtNoon + 1.0)) * 180.0 / .pi
        
        let asrRts = earth.twilights(forSunAltitude: Degree(asrAltitude), coordinates: geo)
        if let asrDate = asrRts.setTime?.date {
            results.append(PrayerTime(name: "Asr", time: format(asrDate).0, date: asrDate, icon: "sun.min.fill"))
        }
        
        // 4. Maghrib (-0.833°) - Couché du soleil
        let maghribRts = earth.twilights(forSunAltitude: Degree(-0.833), coordinates: geo)
        if let maghribDate = maghribRts.setTime?.date {
            results.append(PrayerTime(name: "Maghrib", time: format(maghribDate).0, date: maghribDate, icon: "sunset.fill"))
        }
        
        // 5. Isha (-17°) - Fin du crépuscule
        let ishaRts = earth.twilights(forSunAltitude: Degree(-17.0), coordinates: geo)
        if let ishaDate = ishaRts.setTime?.date {
            results.append(PrayerTime(name: "Isha", time: format(ishaDate).0, date: ishaDate, icon: "moon.stars.fill"))
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
        case 0..<1.84: name = "Nouvelle Lune"; icon = "moonphase.new.moon"
        case 1.84..<5.53: name = "Premier Croissant"; icon = "moonphase.waxing.crescent"
        case 5.53..<9.22: name = "Premier Quartier"; icon = "moonphase.first.quarter"
        case 9.22..<12.91: name = "Lune Gibbeuse Croissante"; icon = "moonphase.waxing.gibbous"
        case 12.91..<16.61: name = "Pleine Lune"; icon = "moonphase.full.moon"
        case 16.61..<20.30: name = "Lune Gibbeuse Décroissante"; icon = "moonphase.waning.gibbous"
        case 20.30..<23.99: name = "Dernier Quartier"; icon = "moonphase.last.quarter"
        case 23.99..<27.68: name = "Dernier Croissant"; icon = "moonphase.waning.crescent"
        default: name = "Nouvelle Lune"; icon = "moonphase.new.moon"
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
            latitude: Degree(location.coordinate.latitude)
        )

        let targetDate = maghribDate ?? date
        let sun = Sun(julianDay: JulianDay(targetDate))
        let moon = Moon(julianDay: JulianDay(targetDate))

        // 1. Calcul précis des heures de coucher du Soleil et de la Lune
        let sunRts = sun.riseTransitSetTimes(for: geo)
        let moonRts = moon.riseTransitSetTimes(for: geo)

        let sunsetDate = sunRts.setTime?.date ?? maghribDate ?? date
        let moonsetDate = moonRts.setTime?.date

        // Moon Lag (différence de coucher Soleil - Lune en minutes)
        var moonLagMinutes = 0.0
        if let moonset = moonsetDate {
            moonLagMinutes = moonset.timeIntervalSince(sunsetDate) / 60.0
        }

        // Instant optimal d'observation : Sunset + 4/9 * Moonlag
        let bestTime: Date?
        if moonLagMinutes > 0 {
            bestTime = sunsetDate.addingTimeInterval(moonLagMinutes * 60.0 * (4.0 / 9.0))
        } else {
            bestTime = sunsetDate
        }

        // 2. Calculs astronomiques topocentriques au moment du coucher du Soleil / Best Time
        let evalDate = bestTime ?? sunsetDate
        let evalJd = JulianDay(evalDate)
        let evalMoon = Moon(julianDay: evalJd)
        let evalSun = Sun(julianDay: evalJd)

        let elongation = evalMoon.equatorialCoordinates.angularSeparation(with: evalSun.equatorialCoordinates).value
        let moonHoriz = evalMoon.makeHorizontalCoordinates(with: geo)
        let sunHoriz = evalSun.makeHorizontalCoordinates(with: geo)

        // Dépression d'horizon (dip) due à l'altitude de l'observateur
        let observerAlt = location.altitude > -100 ? location.altitude : 0.0
        let horizonDip = 0.0293 * sqrt(max(0.0, observerAlt))
        let moonAltitude = moonHoriz.altitude.value + horizonDip
        let sunAltitude = sunHoriz.altitude.value

        // Azimut en cap boussole conventionnel
        let astronomicalAzimuth = moonHoriz.azimuth.value
        let compassAzimuth = (astronomicalAzimuth + 180.0).truncatingRemainder(dividingBy: 360.0)

        let astronomicalSunAzimuth = sunHoriz.azimuth.value
        let sunCompassAzimuth = (astronomicalSunAzimuth + 180.0).truncatingRemainder(dividingBy: 360.0)

        // ARCV (Arc of Vision) & DAZ (Difference in Azimuth)
        let arcOfVision = moonAltitude - sunAltitude
        var daz = abs(compassAzimuth - sunCompassAzimuth)
        if daz > 180.0 { daz = 360.0 - daz }

        // Largeur du croissant W en minutes d'arc (SD standard ~ 15.5')
        let moonSemiDiameter = 15.5
        let crescentWidth = moonSemiDiameter * (1.0 - cos(elongation * .pi / 180.0))

        // Âge de la Lune en heures
        let lastNewMoon = evalMoon.time(of: .newMoon, forward: false)
        let ageInHours = (evalMoon.julianDay.value - lastNewMoon.value) * 24.0

        // 3. Modèle scientifique de visibilité Yallop (valeur q)
        // Formule de référence Yallop (1997) :
        // q = (ARCV - (11.8371 - 6.3226 * W + 0.7319 * W^2 - 0.1018 * W^3)) / 10.0
        let w = crescentWidth
        let yallopPolynomial = 11.8371 - (6.3226 * w) + (0.7319 * pow(w, 2)) - (0.1018 * pow(w, 3))
        let qValue = (arcOfVision - yallopPolynomial) / 10.0

        let yallopZone: String
        let baseVisibility: HilalVisibility

        // Limite de Danjon : en-dessous de 7° d'élongation, la Lune est invisible à cause de la rugosité de la surface lunaire
        if elongation < 7.0 || moonAltitude <= 0.0 || moonLagMinutes <= 0.0 || ageInHours < 12.0 {
            yallopZone = "F"
            baseVisibility = .impossible
        } else if qValue > 0.216 {
            yallopZone = "A"
            baseVisibility = .easilyVisibleNakedEye
        } else if qValue > -0.060 {
            yallopZone = "B"
            baseVisibility = .visibleNakedEyePerfectConditions
        } else if qValue > -0.160 {
            yallopZone = "C"
            baseVisibility = .opticalAidThenNakedEye
        } else if qValue > -0.232 {
            yallopZone = "D"
            baseVisibility = .opticalAidOnly
        } else {
            yallopZone = "E"
            baseVisibility = .impossible
        }

        return HilalObservationData(
            visibility: baseVisibility,
            azimuthDegrees: compassAzimuth,
            moonAltitudeDegrees: moonAltitude,
            moonAgeHours: ageInHours,
            elongationDegrees: elongation,
            observerAltitudeMeters: observerAlt,
            yallopQValue: qValue,
            yallopZone: yallopZone,
            arcOfVisionDegrees: arcOfVision,
            azimuthDifferenceDegrees: daz,
            crescentWidthArcminutes: crescentWidth,
            moonLagMinutes: moonLagMinutes,
            sunsetTime: sunsetDate,
            moonsetTime: moonsetDate,
            bestObservationTime: bestTime,
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
