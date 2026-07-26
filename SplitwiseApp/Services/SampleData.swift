import Foundation
import SwiftData

@MainActor
public enum SampleData {

    public static func populateIfEmpty(context: ModelContext) {
        let descriptor = FetchDescriptor<User>()
        let existingUsers = (try? context.fetch(descriptor)) ?? []

        guard existingUsers.isEmpty else { return }

        // 1. Create Users
        let currentUser = User(
            name: "Alex Johnson",
            email: "alex@example.com",
            phone: "+1 555-0192",
            avatarName: "person.crop.circle.fill",
            defaultCurrency: "USD",
            isCurrentUser: true
        )

        let sarah = User(name: "Sarah Chen", email: "sarah@example.com", phone: "+1 555-0143", avatarName: "person.circle.fill")
        let michael = User(name: "Michael Brown", email: "michael@example.com", phone: "+1 555-0188", avatarName: "person.circle.fill")
        let emma = User(name: "Emma Watson", email: "emma@example.com", phone: "+1 555-0122", avatarName: "person.circle.fill")
        let david = User(name: "David Kim", email: "david@example.com", phone: "+1 555-0177", avatarName: "person.circle.fill")

        context.insert(currentUser)
        context.insert(sarah)
        context.insert(michael)
        context.insert(emma)
        context.insert(david)

        // 2. Create Groups
        let aptGroup = Group(
            name: "Apartment 4B",
            groupType: .home,
            coverImageName: "house.fill",
            memberIds: [currentUser.id, sarah.id, michael.id],
            defaultCurrency: "USD",
            simplifyDebts: true
        )

        let tripGroup = Group(
            name: "Tokyo Summer Trip 🇯🇵",
            groupType: .trip,
            coverImageName: "airplane",
            memberIds: [currentUser.id, sarah.id, emma.id, david.id],
            defaultCurrency: "USD",
            simplifyDebts: true
        )

        let bbqGroup = Group(
            name: "Weekend BBQ Party",
            groupType: .other,
            coverImageName: "flame.fill",
            memberIds: [currentUser.id, michael.id, david.id],
            defaultCurrency: "USD",
            simplifyDebts: false
        )

        context.insert(aptGroup)
        context.insert(tripGroup)
        context.insert(bbqGroup)

        // 3. Create Sample Expenses for Apartment 4B
        let rentSplits = [
            ExpenseSplit(userId: currentUser.id, userName: currentUser.name, amount: 800.0, paidShare: 2400.0),
            ExpenseSplit(userId: sarah.id, userName: sarah.name, amount: 800.0, paidShare: 0.0),
            ExpenseSplit(userId: michael.id, userName: michael.name, amount: 800.0, paidShare: 0.0)
        ]
        let rentExpense = Expense(
            title: "July Apartment Rent",
            amount: 2400.0,
            currency: "USD",
            payerId: currentUser.id,
            groupId: aptGroup.id,
            splitMethod: .equal,
            category: .rent,
            splits: rentSplits,
            notes: "Wire transfer to landlord",
            date: Calendar.current.date(byAdding: .day, value: -12, to: Date()) ?? Date()
        )

        let wifiSplits = [
            ExpenseSplit(userId: currentUser.id, userName: currentUser.name, amount: 20.0, paidShare: 0.0),
            ExpenseSplit(userId: sarah.id, userName: sarah.name, amount: 20.0, paidShare: 60.0),
            ExpenseSplit(userId: michael.id, userName: michael.name, amount: 20.0, paidShare: 0.0)
        ]
        let wifiExpense = Expense(
            title: "High-Speed Internet (Fiber)",
            amount: 60.0,
            currency: "USD",
            payerId: sarah.id,
            groupId: aptGroup.id,
            splitMethod: .equal,
            category: .utilities,
            splits: wifiSplits,
            notes: "Monthly bill",
            date: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
        )

        let grocerySplits = [
            ExpenseSplit(
                userId: currentUser.id,
                userName: currentUser.name,
                amount: 45.0,
                paidShare: 0.0,
                itemizedItems: [ItemizedSplit(title: "Organic Milk", price: 5.0), ItemizedSplit(title: "Steak", price: 40.0)]
            ),
            ExpenseSplit(
                userId: sarah.id,
                userName: sarah.name,
                amount: 30.0,
                paidShare: 0.0,
                itemizedItems: [ItemizedSplit(title: "Salad Greens", price: 10.0), ItemizedSplit(title: "Berries", price: 20.0)]
            ),
            ExpenseSplit(
                userId: michael.id,
                userName: michael.name,
                amount: 60.0,
                paidShare: 135.0,
                itemizedItems: [ItemizedSplit(title: "Craft Beers", price: 60.0)]
            )
        ]
        let groceryExpense = Expense(
            title: "Whole Foods Grocery Run",
            amount: 135.0,
            currency: "USD",
            payerId: michael.id,
            groupId: aptGroup.id,
            splitMethod: .itemized,
            category: .food,
            splits: grocerySplits,
            notes: "Shared kitchen staples & snacks",
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        )

        context.insert(rentExpense)
        context.insert(wifiExpense)
        context.insert(groceryExpense)

        // 4. Create Sample Expenses for Tokyo Trip
        let ramenSplits = [
            ExpenseSplit(userId: currentUser.id, userName: currentUser.name, amount: 30.0, paidShare: 120.0),
            ExpenseSplit(userId: sarah.id, userName: sarah.name, amount: 30.0, paidShare: 0.0),
            ExpenseSplit(userId: emma.id, userName: emma.name, amount: 30.0, paidShare: 0.0),
            ExpenseSplit(userId: david.id, userName: david.name, amount: 30.0, paidShare: 0.0)
        ]
        let ramenExpense = Expense(
            title: "Ichiran Ramen Dinner in Shinjuku",
            amount: 120.0,
            currency: "USD",
            payerId: currentUser.id,
            groupId: tripGroup.id,
            splitMethod: .equal,
            category: .food,
            splits: ramenSplits,
            notes: "Matcha beer and extra noodles included!",
            date: Calendar.current.date(byAdding: .day, value: -8, to: Date()) ?? Date()
        )

        context.insert(ramenExpense)

        // 5. Settlement sample
        let settlement = Settlement(
            payerId: sarah.id,
            payeeId: currentUser.id,
            amount: 300.0,
            currency: "USD",
            groupId: aptGroup.id,
            paymentMethod: "Venmo",
            notes: "Partial rent payment"
        )
        context.insert(settlement)

        // 6. Activity logs
        let act1 = ActivityLog(
            type: .addedExpense,
            actorId: currentUser.id,
            actorName: currentUser.name,
            title: "Alex added \"July Apartment Rent\"",
            details: "Total $2,400.00 in Apartment 4B",
            groupId: aptGroup.id
        )
        let act2 = ActivityLog(
            type: .settledUp,
            actorId: sarah.id,
            actorName: sarah.name,
            title: "Sarah paid Alex $300.00 via Venmo",
            details: "Settled up in Apartment 4B",
            groupId: aptGroup.id
        )

        context.insert(act1)
        context.insert(act2)

        try? context.save()
    }
}
