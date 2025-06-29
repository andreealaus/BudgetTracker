import CoreData

class CoreDataUtils {
    static func fetchCurrentUserEntity(context: NSManagedObjectContext, username: String?) -> UserEntity? {
        guard let username = username else { return nil }
        let req: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        req.predicate = NSPredicate(format: "username == %@", username)
        return (try? context.fetch(req))?.first
    }

    static func monthName(for month: Int) -> String {
        let dateFormatter = DateFormatter()
        return dateFormatter.monthSymbols[month - 1]
    }

    static func validateUserInput(newUserName: String, newUserPassword: String, coreDataUsers: [UserEntity]) -> String? {
        guard !newUserName.isEmpty, !newUserPassword.isEmpty else {
            return "Toate câmpurile sunt obligatorii."
        }
        guard newUserPassword.count >= 8 else {
            return "Parola trebuie să aibă minim 8 caractere."
        }
        if coreDataUsers.contains(where: { $0.username?.lowercased() == newUserName.lowercased() }) {
            return "Utilizator deja existent."
        }
        return nil
    }
}
