//
//  QiblaManager.swift
//  COLDFRAME
//
//  Created by Mo on 17/12/2025.
//


import Foundation
import CoreLocation
import Combine
import UIKit

class QiblaManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    @Published var heading: Double = 0.0
    @Published var qiblaAngle: Double = 0.0
    @Published var isAligned: Bool = false
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var prayerTimes: [PrayerTime] = []
    
    // Coordonnées de la Kaaba
    let meccaCoordinate = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
        // Init Notifications
        NotificationManager.shared.requestAuthorization()
    }
    
    // MARK: - Location & Compass
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // -90 pour corriger l'orientation par défaut de SwiftUI si nécessaire, sinon brut
        self.heading = newHeading.magneticHeading
        checkAlignment()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.userLocation = location.coordinate
        self.qiblaAngle = calculateQiblaAngle(from: location)
        
        if prayerTimes.isEmpty {
            fetchPrayerTimes(for: location)
        }
    }
    
    // MARK: - Calcul Mathématique
    private func calculateQiblaAngle(from location: CLLocation) -> Double {
        let lat1 = location.coordinate.latitude * .pi / 180
        let lon1 = location.coordinate.longitude * .pi / 180
        let lat2 = 21.4225 * .pi / 180
        let lon2 = 39.8262 * .pi / 180
        let dLon = lon2 - lon1
        
        let y = sin(dLon)
        let x = cos(lat1) * tan(lat2) - sin(lat1) * cos(dLon)
        var angle = atan2(y, x) * 180 / .pi
        return (angle + 360).truncatingRemainder(dividingBy: 360)
    }
    
    // MARK: - Haptic Feedback
    private func checkAlignment() {
        let diff = abs(qiblaAngle - heading)
        let tolerance = 2.0
        
        if diff <= tolerance || diff >= (360 - tolerance) {
            if !isAligned {
                isAligned = true
                feedbackGenerator.impactOccurred()
            }
        } else {
            isAligned = false
        }
    }
    
    // MARK: - API Fetching
    func fetchPrayerTimes(for location: CLLocation) {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        // Method 2 = ISNA. Vous pouvez changer selon la région.
        let urlString = "https://api.aladhan.com/v1/timings?latitude=\(lat)&longitude=\(lon)&method=2"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode(PrayerResponse.self, from: data)
                let rawTimings = decoded.data.timings
                
                let orderedKeys = [
                    ("Fajr", "sun.haze.fill"), ("Dhuhr", "sun.max.fill"),
                    ("Asr", "sun.min.fill"), ("Maghrib", "sunset.fill"),
                    ("Isha", "moon.stars.fill")
                ]
                
                let formattedTimes = orderedKeys.compactMap { key, icon in
                    return PrayerTime(name: key, time: rawTimings[key] ?? "--:--", icon: icon)
                }
                
                DispatchQueue.main.async {
                    self.prayerTimes = formattedTimes
                    // Reprogrammer les notifications
                    NotificationManager.shared.cancelAllNotifications()
                    for prayer in formattedTimes {
                        NotificationManager.shared.scheduleNotification(for: prayer)
                    }
                }
            } catch {
                print("Erreur JSON: \(error)")
            }
        }.resume()
    }
}