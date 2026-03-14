//
//  AstronomicManager.swift
//  COLDFRAME
//
//  Created by Mo on 17/12/2025.
//

import Foundation
import CoreLocation
import SwiftAA

class AstronomicManager {
    
    static func getSolarData(for location: CLLocation, date: Date = Date()) -> [PrayerTime] {
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

    static func getMoonPhase(for date: Date = Date()) -> (name: String, icon: String, phaseDays: Double) {
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

        return (name, icon, phaseDays)
    }

    static func getHilalVisibility(for date: Date = Date(), maghribDate: Date?, location: CLLocationCoordinate2D?) -> HilalVisibility {
        guard let location = location else { return .notObservationDay }
        
        // Le Hilal est cherché uniquement le 29 du mois lunaire
        let islamicCalendar = Calendar(identifier: .islamicUmmAlQura)
        let day = islamicCalendar.component(.day, from: date)
        if day != 29 {
            return .notObservationDay
        }
        
        let geo = GeographicCoordinates(
            positivelyWestwardLongitude: Degree(-location.longitude),
            latitude: Degree(location.latitude)
        )
        
        // Utiliser l'heure du maghrib si disponible, sinon l'heure courante
        let jd = JulianDay(maghribDate ?? date)
        let moon = Moon(julianDay: jd)
        let sun = Sun(julianDay: jd)
        
        let elongation = moon.equatorialCoordinates.angularSeparation(with: sun.equatorialCoordinates)
        // La méthode attend désormais explicitement 'with:' comme seul argument
        let horizontal = moon.makeHorizontalCoordinates(with: geo)
        
        let moonAltitude = horizontal.altitude.value
        
        // Calcul de l'âge de la lune en heures
        let lastNewMoon = moon.time(of: .newMoon, forward: false)
        let ageInDays = moon.julianDay.value - lastNewMoon.value
        let ageInHours = ageInDays * 24.0

        if ageInHours < 15.0 || elongation.value < 8.0 || moonAltitude <= 0.0 {
            return .impossible
        }

        return (ageInHours < 24.0 || elongation.value < 10.0 || moonAltitude < 5.0) ? .difficult : .visible
    }
}
