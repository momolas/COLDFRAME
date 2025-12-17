//
//  NotificationManager.swift
//  COLDFRAME
//
//  Created by Mo on 17/12/2025.
//


import Foundation
import UserNotifications

class NotificationManager {
	static let shared = NotificationManager()
	
	func requestAuthorization() {
		UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
			if granted { print("Notifications autorisées") }
		}
	}
	
	func scheduleNotification(for prayer: PrayerTime) {
		let content = UNMutableNotificationContent()
		content.title = "Heure de la prière"
		content.body = "C'est l'heure de \(prayer.name)."
		// Assurez-vous d'avoir ajouté un fichier 'adhan.mp3' au projet
		content.sound = UNNotificationSound(named: UNNotificationSoundName("adhan.mp3"))
		
		let timeParts = prayer.time.split(separator: ":").compactMap { Int($0) }
		guard timeParts.count == 2 else { return }
		
		var dateComponents = DateComponents()
		dateComponents.hour = timeParts[0]
		dateComponents.minute = timeParts[1]
		
		let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
		let request = UNNotificationRequest(identifier: prayer.name, content: content, trigger: trigger)
		
		UNUserNotificationCenter.current().add(request)
	}
	
	func cancelAllNotifications() {
		UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
	}
}
