//
//  AstronomicManager.swift
//  COLDFRAME
//
//  Created by Mo on 17/12/2025.
//


import Foundation
import CoreLocation
import SwiftAA // Le package doit être importé

class AstronomicManager {
	
	// Fonction principale appelée par QiblaManager
	static func getSolarData(for location: CLLocation, date: Date = Date()) -> [PrayerTime] {
		
		// 1. Configuration SwiftAA
		// SwiftAA utilise le jour Julien pour une précision astronomique
		let julianDay = JulianDay(date)
		let sun = Sun(julianDay: julianDay)
		
		// 2. Données précises du Soleil fournies par la NASA/SwiftAA
		// Déclinaison : Angle du soleil par rapport à l'équateur céleste
		let declination = sun.equatorialCoordinates.declination.value // en degrés
		// Equation du temps : La différence entre le "temps solaire vrai" et le temps de la montre
		let equationOfTime = sun.equationOfTime().value // en minutes
		
		// 3. Variables locales
		let lat = location.coordinate.latitude
		let lon = location.coordinate.longitude
		// Fuseau horaire actuel en heures décimales (ex: +1.0 ou +2.0 pour la France)
		let timeZone = Double(TimeZone.current.secondsFromGMT()) / 3600.0
		
		// 4. Calcul du DHUHR (Zénith / Midi Solaire)
		// Formule : 12 + Zone - Longitude - EquationDuTemps
		// C'est le pivot central de tous les autres calculs
		let dhuhrDecimal = 12.0 + timeZone - (lon / 15.0) - (equationOfTime / 60.0)
		
		// 5. Fonction Trigonométrique (Jean Meeus)
		// Calcule le décalage horaire par rapport à midi pour atteindre une certaine altitude
		func getHourOffset(altitude: Double) -> Double? {
			let latRad = lat.deg2rad
			let decRad = declination.deg2rad
			let altRad = altitude.deg2rad
			
			// Formule de l'angle horaire (cos H)
			let cosH = (sin(altRad) - sin(latRad) * sin(decRad)) / (cos(latRad) * cos(decRad))
			
			// Vérification physique : le soleil atteint-il cette altitude ?
			if cosH > 1 || cosH < -1 { return nil }
			
			let angle = acos(cosH).rad2deg
			return angle / 15.0 // Conversion degrés -> heures
		}
		
		// 6. Calcul des Horaires
		var results: [PrayerTime] = []
		let formatter = DateFormatter()
		formatter.dateFormat = "HH:mm"
		
		// Helper pour convertir l'heure décimale (18.5) en String ("18:30")
        // Retourne le tuple (String, Date)
		func format(_ decimalTime: Double) -> (String, Date) {
			var t = decimalTime
			// Normalisation 0-24h
			if t < 0 { t += 24 }
			if t >= 24 { t -= 24 }
			
			let hours = Int(t)
			let minutes = Int((t - Double(hours)) * 60)

            var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
            components.hour = hours
            components.minute = minutes

            let prayerDate = Calendar.current.date(from: components) ?? date

			let formattedHours = hours.formatted(.number.precision(.integerLength(2...)))
			let formattedMinutes = minutes.formatted(.number.precision(.integerLength(2...)))
			return ("\(formattedHours):\(formattedMinutes)", prayerDate)
		}
		
		// --- FAJR ---
		// Angle standard : -18° (Ligue Islamique Mondiale)
		if let offset = getHourOffset(altitude: -18.0) {
            let f = format(dhuhrDecimal - offset)
			results.append(PrayerTime(name: "Fajr", time: f.0, date: f.1, icon: "sun.haze.fill"))
		}
		
		// --- DHUHR ---
		// On ajoute 2 minutes de précaution par rapport au zénith exact
        let dhuhrF = format(dhuhrDecimal + (2.0/60.0))
		results.append(PrayerTime(name: "Dhuhr", time: dhuhrF.0, date: dhuhrF.1, icon: "sun.max.fill"))
		
		// --- ASR ---
		// Altitude Asr = arccot(1 + tan(|lat - decl|))
		// Facteur d'ombre : 1.0 (Majorité) ou 2.0 (Hanafi)
		let shadowFactor = 1.0
		let delta = abs(lat - declination)
		let asrAltitudeRad = atan(1.0 / (shadowFactor + tan(delta.deg2rad)))
		let asrAltitude = asrAltitudeRad.rad2deg
		
		if let offset = getHourOffset(altitude: asrAltitude) {
            let f = format(dhuhrDecimal + offset)
			results.append(PrayerTime(name: "Asr", time: f.0, date: f.1, icon: "sun.min.fill"))
		}
		
		// --- MAGHRIB ---
		// Coucher du soleil théorique à 0°, mais -0.833° avec la réfraction atmosphérique
		if let offset = getHourOffset(altitude: -0.833) {
			// On ajoute souvent 3 min de précaution après le coucher théorique
            let f = format(dhuhrDecimal + offset + (3.0/60.0))
			results.append(PrayerTime(name: "Maghrib", time: f.0, date: f.1, icon: "sunset.fill"))
		}
		
		// --- ISHA ---
		// Angle standard : -17° ou -18°
		if let offset = getHourOffset(altitude: -17.0) {
            let f = format(dhuhrDecimal + offset)
			results.append(PrayerTime(name: "Isha", time: f.0, date: f.1, icon: "moon.stars.fill"))
		}
		
		return results
	}

	// MARK: - Phase de la Lune

	/// Calcule la phase approximative de la lune en jours (0 à 29.53) et retourne une icône SF Symbol appropriée ainsi qu'un nom.
	static func getMoonPhase(for date: Date = Date()) -> (name: String, icon: String, phaseDays: Double) {
		// On utilise un calcul mathématique simplifié basé sur une Nouvelle Lune connue (ex: 6 Jan 2000, 18:14 UTC)
		let newMoonReference = Date(timeIntervalSince1970: 947182440)
		let lunarCycle = 29.53058867 // Durée moyenne d'un cycle lunaire

		let timeSinceNewMoon = date.timeIntervalSince(newMoonReference)
		let daysSinceNewMoon = timeSinceNewMoon / 86400.0

		var phaseDays = daysSinceNewMoon.truncatingRemainder(dividingBy: lunarCycle)
		if phaseDays < 0 {
			phaseDays += lunarCycle
		}

		let name: String
		let icon: String

		switch phaseDays {
		case 0..<1.84:
			name = "Nouvelle Lune"
			icon = "moonphase.new.moon"
		case 1.84..<5.53:
			name = "Premier Croissant"
			icon = "moonphase.waxing.crescent"
		case 5.53..<9.22:
			name = "Premier Quartier"
			icon = "moonphase.first.quarter"
		case 9.22..<12.91:
			name = "Lune Gibbeuse Croissante"
			icon = "moonphase.waxing.gibbous"
		case 12.91..<16.61:
			name = "Pleine Lune"
			icon = "moonphase.full.moon"
		case 16.61..<20.30:
			name = "Lune Gibbeuse Décroissante"
			icon = "moonphase.waning.gibbous"
		case 20.30..<23.99:
			name = "Dernier Quartier"
			icon = "moonphase.last.quarter"
		case 23.99..<27.68:
			name = "Dernier Croissant"
			icon = "moonphase.waning.crescent"
		default:
			name = "Nouvelle Lune"
			icon = "moonphase.new.moon"
		}

		return (name, icon, phaseDays)
	}

	// MARK: - Observation du Hilal

	/// Détermine la probabilité d'observation du Hilal (nouveau croissant de lune) le soir du Maghrib.
	/// Cette fonction vérifie si on est le 29ème jour du mois islamique.
	static func getHilalVisibility(for date: Date = Date(), maghribDate: Date?) -> HilalVisibility {
		let islamicCalendar = Calendar(identifier: .islamicUmmAlQura)
		let components = islamicCalendar.dateComponents([.day, .month], from: date)

		guard let islamicDay = components.day else { return .notObservationDay }

		// Le Hilal est typiquement observé le soir du 29ème jour pour déterminer
		// si le lendemain est le 1er du nouveau mois ou le 30ème de l'actuel.
		if islamicDay != 29 {
			return .notObservationDay
		}

		// Heure d'observation (Maghrib). Si non disponible, on utilise l'heure actuelle + qqs heures
		let observationTime = maghribDate ?? date.addingTimeInterval(12 * 3600)

		// Calcul de l'âge de la lune en heures
		let moonData = getMoonPhase(for: observationTime)

		// phaseDays = nombre de jours depuis la Nouvelle Lune
		// Si phaseDays est très grand (ex: 29.3), on est encore avant la Nouvelle Lune (fin du mois lunaire)
		// Si phaseDays est petit (ex: 0.5 à 2.0), on a passé la Nouvelle Lune (début du nouveau mois).

		let lunarCycle = 29.53058867

		var ageInHours: Double
		if moonData.phaseDays > (lunarCycle - 2.0) {
			// La conjonction (Nouvelle Lune) n'a pas encore eu lieu, la lune est "négative" en âge
			ageInHours = (moonData.phaseDays - lunarCycle) * 24.0
		} else {
			// La lune est née
			ageInHours = moonData.phaseDays * 24.0
		}

		// L'observation est impossible si la lune est née il y a moins de 15h
		// (le record mondial d'observation à l'œil nu est ~15h32, télescope ~11h40)
		if ageInHours < 15.0 {
			return .impossible
		} else if ageInHours < 24.0 {
			return .difficult
		} else {
			return .visible
		}
	}
}
