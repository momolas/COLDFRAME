//
//  IslamicAstronomy.swift
//  COLDFRAME
//
//  Created by Mo on 17/12/2025.
//


import Foundation

struct IslamicAstronomy {
    
    // 1. Conversion Date -> Jour Julien (Julian Day)
    static func getJulianDay(date: Date) -> Double {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        var Y = Double(components.year!)
        var M = Double(components.month!)
        let D = Double(components.day!)
        let H = Double(components.hour!) + Double(components.minute!)/60.0 + Double(components.second!)/3600.0
        
        if M <= 2 { Y -= 1; M += 12 }
        
        let A = floor(Y / 100)
        let B = 2 - A + floor(A / 4)
        
        return floor(365.25 * (Y + 4716)) + floor(30.6001 * (M + 1)) + D + B - 1524.5 + (H / 24.0)
    }
    
    // 2. Position du Soleil (Déclinaison & Equation du Temps)
    // Algorithme simplifié VSOP87 pour une bonne précision sans charger de gros fichiers
    static func calculateSunPosition(jd: Double) -> (declination: Double, equationOfTime: Double) {
        let D = jd - 2451545.0
        let g = (357.529 + 0.98560028 * D).truncatingRemainder(dividingBy: 360)
        let q = (280.459 + 0.98564736 * D).truncatingRemainder(dividingBy: 360)
        let L = (q + 1.915 * sin(g.deg2rad) + 0.020 * sin((2 * g).deg2rad)).truncatingRemainder(dividingBy: 360)
        
        let e = 23.439 - 0.00000036 * D
        let RA = atan2(cos(e.deg2rad) * sin(L.deg2rad), cos(L.deg2rad)).rad2deg
        
        let RA_corr = (RA / 15).rounded(.down) * 15 + (L / 15).rounded(.down) * 15 + (L/15 - RA/15) * 15
        
        let declination = asin(sin(e.deg2rad) * sin(L.deg2rad)).rad2deg
        let equationOfTime = q/15 - RA/15 // En heures
        
        return (declination, equationOfTime * 60) // EoT renvoyé en minutes
    }
    
    // 3. Calcul de l'angle horaire (t) pour une altitude donnée du soleil
    static func calculateHourAngle(altitude: Double, lat: Double, declination: Double) -> Double? {
        let num = sin(altitude.deg2rad) - sin(lat.deg2rad) * sin(declination.deg2rad)
        let den = cos(lat.deg2rad) * cos(declination.deg2rad)
        let val = num / den
        
        if val > 1 || val < -1 { return nil } // Le soleil n'atteint jamais cette altitude
        return acos(val).rad2deg / 15.0 // Retourne des heures
    }
    
    // 4. Calcul spécifique pour Asr (basé sur l'ombre)
    static func calculateAsrAltitude(lat: Double, declination: Double) -> Double {
        // Madhab standard (Shafi, Maliki, Hanbali) : Ombre = 1x
        // Pour Hanafi, changer shadowLength à 2.0
        let shadowLength = 1.0 
        let angleAtNoon = abs(lat - declination)
        let altitudeRad = atan(1.0 / (shadowLength + tan(angleAtNoon.deg2rad)))
        return altitudeRad.rad2deg
    }
}