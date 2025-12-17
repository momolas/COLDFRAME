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
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error { print("Erreur notif: \(error)") }
        }
    }
    
    func scheduleNotification(for prayer: PrayerTime) {
        let content = UNMutableNotificationContent()
        content.title = "Heure de la prière"
        content.body = "C'est l'heure de \(prayer.name). Hayya 'ala-s-Salah."
        // Assurez-vous d'avoir un fichier 'adhan.mp3' dans votre projet, sinon mettez .default
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