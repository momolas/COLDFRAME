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
// import SwiftAA // Plus nécessaire ici, utilisé uniquement dans SwiftAAManager

class QiblaManager: NSObject, ObservableObject, CLLocationManagerDelegate {
	private let locationManager = CLLocationManager()
	private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
	
	@Published var heading: Double = 0.0
	@Published var qiblaAngle: Double = 0.0
	@Published var isAligned: Bool = false
	@Published var userLocation: CLLocationCoordinate2D?
	@Published var prayerTimes: [PrayerTime] = []
	
	// Coordonnées de la Kaaba (La Mecque)
	let meccaCoordinate = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)
	
	override init() {
		super.init()
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		locationManager.requestWhenInUseAuthorization()
		locationManager.startUpdatingLocation()
		locationManager.startUpdatingHeading()
		NotificationManager.shared.requestAuthorization()
	}
	
	// MARK: - CoreLocation Delegate
	func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
		// Utiliser le Vrai Nord (True Heading) si disponible, sinon le Magnétique
		let h = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
		self.heading = h
		checkAlignment()
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let location = locations.last else { return }
		self.userLocation = location.coordinate
		
		// 1. Calcul Qibla (Formule Mathématique Orthodromique)
		self.qiblaAngle = calculateBearingToMecca(from: location)
		
		// 2. Calcul Horaires via SwiftAA (appel au SwiftAAManager)
		// On évite de recalculer trop souvent
		if prayerTimes.isEmpty {
			calculatePrayersLocally(for: location)
		}
	}
	
	// MARK: - Calcul Qibla (Correctif)
	// Cette fonction remplace l'appel erroné à SwiftAA.
	// Elle utilise la formule standard de navigation (Great Circle Bearing).
	private func calculateBearingToMecca(from location: CLLocation) -> Double {
		let lat1 = location.coordinate.latitude.deg2rad
		let lon1 = location.coordinate.longitude.deg2rad
		
		let lat2 = meccaCoordinate.latitude.deg2rad
		let lon2 = meccaCoordinate.longitude.deg2rad
		
		let dLon = lon2 - lon1
		
		let y = sin(dLon) * cos(lat2)
		let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
		
		let radiansBearing = atan2(y, x)
		
		// Conversion en degrés et normalisation (0 à 360)
		return (radiansBearing.rad2deg + 360).truncatingRemainder(dividingBy: 360)
	}
	
	// MARK: - Calcul Horaires (SwiftAA)
	func calculatePrayersLocally(for location: CLLocation) {
		// On délègue le travail astronomique complexe à notre Manager dédié
		let calculatedTimes = SwiftAAManager.getSolarData(for: location)
		
		DispatchQueue.main.async {
			self.prayerTimes = calculatedTimes
			
			// Notifications
			NotificationManager.shared.cancelAllNotifications()
			for prayer in calculatedTimes {
				NotificationManager.shared.scheduleNotification(for: prayer)
			}
		}
	}
	
	// MARK: - Haptic & UI Logic
	private func checkAlignment() {
		let diff = abs(qiblaAngle - heading)
		// Tolérance de 2 degrés pour la vibration
		if diff <= 2.0 || diff >= 358.0 {
			if !isAligned {
				isAligned = true
				feedbackGenerator.impactOccurred()
			}
		} else {
			isAligned = false
		}
	}
}
