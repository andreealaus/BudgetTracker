import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    
    func scheduleReminder(on date: Date, with message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = message
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                          from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Eroare la programarea notificării: \(error.localizedDescription)")
            }
        }
    }
    
    func notifyAdmin(for transaction: Transaction) {
        let message = "Utilizatorul \(transaction.user.username) a adăugat o tranzacție de \(transaction.totalAmount)."
        scheduleReminder(on: Date().addingTimeInterval(1), with: message)
    }
}
