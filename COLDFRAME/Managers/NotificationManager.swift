//
//  NotificationManager.swift
//  COLDFRAME
//
//  Created by Mo on 17/12/2025.
//


import Foundation
import UserNotifications
import os

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let logger = Logger(subsystem: "com.coldframe.app", category: "NotificationManager")

    private init() {}
	
	func requestAuthorization() {
		Task {
			do {
				let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
				if granted {
					self.logger.info("Notifications autorisées")
				} else {
                    self.logger.warning("Notifications refusées par l'utilisateur")
                }
			} catch {
				self.logger.error("Erreur d'autorisation de notification: \(error.localizedDescription)")
			}
		}
	}
	
	func scheduleNotification(for prayer: PrayerTime) {
		Task {
			let settings = await UNUserNotificationCenter.current().notificationSettings()
			guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
				return // Ne pas tenter de programmer si l'utilisateur a refusé ou n'a pas autorisé les notifications
			}

			let content = UNMutableNotificationContent()
			content.title = String(localized: "notif_prayer_title")
			content.body = String(localized: "notif_prayer_body", defaultValue: "C'est l'heure de \(prayer.name).")
			content.sound = .default
			
			let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: prayer.date)
			let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
			let request = UNNotificationRequest(identifier: prayer.name, content: content, trigger: trigger)
			
			do {
				try await UNUserNotificationCenter.current().add(request)
			} catch {
				self.logger.error("Erreur lors de la programmation de la notification: \(error.localizedDescription)")
			}
		}
	}
	
	func cancelAllNotifications() {
		UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
	}
}
