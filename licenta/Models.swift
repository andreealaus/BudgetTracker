import Foundation

// MARK: - Enum-uri
enum UserRole: String{
    case admin
    case regular
}

enum CategoryType: Hashable, Equatable {
    case expense
    case income
}

// MARK: - Modele
class User: Hashable, Equatable {
    var id = UUID()
    var username: String
    var role: UserRole
    var familyID: String?
    var createdBy: String?
    
    init(username: String, role: UserRole) {
        self.username = username
        self.role = role
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class Category: Hashable {
    static func == (lhs: Category, rhs: Category) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var id = UUID()
    var name: String
    var type: CategoryType
    
    init(name: String, type: CategoryType) {
        self.name = name
        self.type = type
    }
}

class BudgetPlan {
    var month: Date
    var categoryAllocations: [Category: Double]
    var userAllocations: [User: Double]
    
    init(month: Date,
         categoryAllocations: [Category: Double],
         userAllocations: [User: Double]) {
        self.month = month
        self.categoryAllocations = categoryAllocations
        self.userAllocations = userAllocations
    }
}

class Transaction {
    var id = UUID()
    var user: User
    var date: Date
    var totalAmount: Double
    var categoryAllocations: [Category: Double]
    
    init(user: User,
         date: Date,
         totalAmount: Double,
         categoryAllocations: [Category: Double]) {
        self.user = user
        self.date = date
        self.totalAmount = totalAmount
        self.categoryAllocations = categoryAllocations
    }
}
