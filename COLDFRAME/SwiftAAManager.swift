//
//  SwiftAAManager.swift
//  COLDFRAME
//
//  Created by Mo on 17/12/2025.
//


import Foundation
import CoreLocation
import SwiftAA // Le package doit être importé

class SwiftAAManager {
	
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
		func format(_ decimalTime: Double) -> String {
			var t = decimalTime
			// Normalisation 0-24h
			if t < 0 { t += 24 }
			if t >= 24 { t -= 24 }
			
			let hours = Int(t)
			let minutes = Int((t - Double(hours)) * 60)
			return String(format: "%02d:%02d", hours, minutes)
		}
		
		// --- FAJR ---
		// Angle standard : -18° (Ligue Islamique Mondiale)
		if let offset = getHourOffset(altitude: -18.0) {
			results.append(PrayerTime(name: "Fajr", time: format(dhuhrDecimal - offset), icon: "sun.haze.fill"))
		}
		
		// --- DHUHR ---
		// On ajoute 2 minutes de précaution par rapport au zénith exact
		results.append(PrayerTime(name: "Dhuhr", time: format(dhuhrDecimal + (2.0/60.0)), icon: "sun.max.fill"))
		
		// --- ASR ---
		// Altitude Asr = arccot(1 + tan(|lat - decl|))
		// Facteur d'ombre : 1.0 (Majorité) ou 2.0 (Hanafi)
		let shadowFactor = 1.0
		let delta = abs(lat - declination)
		let asrAltitudeRad = atan(1.0 / (shadowFactor + tan(delta.deg2rad)))
		let asrAltitude = asrAltitudeRad.rad2deg
		
		if let offset = getHourOffset(altitude: asrAltitude) {
			results.append(PrayerTime(name: "Asr", time: format(dhuhrDecimal + offset), icon: "sun.min.fill"))
		}
		
		// --- MAGHRIB ---
		// Coucher du soleil théorique à 0°, mais -0.833° avec la réfraction atmosphérique
		if let offset = getHourOffset(altitude: -0.833) {
			// On ajoute souvent 3 min de précaution après le coucher théorique
			results.append(PrayerTime(name: "Maghrib", time: format(dhuhrDecimal + offset + (3.0/60.0)), icon: "sunset.fill"))
		}
		
		// --- ISHA ---
		// Angle standard : -17° ou -18°
		if let offset = getHourOffset(altitude: -17.0) {
			results.append(PrayerTime(name: "Isha", time: format(dhuhrDecimal + offset), icon: "moon.stars.fill"))
		}
		
		return results
	}
}
