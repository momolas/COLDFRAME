//
//  NotificationManager.swift
//  COLDFRAME
//
//  Created by Mo on 17/12/2025.
//


import Foundation
import UserNotifications
import os

class NotificationManager {
	static let shared = NotificationManager()

    private let logger = Logger(subsystem: "com.coldframe.app", category: "NotificationManager")
	
	func requestAuthorization() {
		UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                self.logger.info("Notifications autorisées")
            } else if let error = error {
                self.logger.error("Erreur d'autorisation de notification: \(error.localizedDescription)")
            }
		}
	}
	
	func scheduleNotification(for prayer: PrayerTime) {
		let content = UNMutableNotificationContent()
		content.title = "Heure de la prière"
		content.body = "C'est l'heure de \(prayer.name)."
		// Utilisation du son par défaut car 'adhan.mp3' est manquant
		content.sound = .default
		
		let timeParts = prayer.time.split(separator: ":").compactMap { Int($0) }
		guard timeParts.count == 2 else { return }
		
		var dateComponents = DateComponents()
		dateComponents.hour = timeParts[0]
		dateComponents.minute = timeParts[1]
		
		let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
		let request = UNNotificationRequest(identifier: prayer.name, content: content, trigger: trigger)
		
		UNUserNotificationCenter.current().add(request)
	}
	
	func cancelAllNotifications() {
		UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
	}
}
