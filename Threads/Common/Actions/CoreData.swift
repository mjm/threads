import CoreData
import UserActions

private let managedObjectContextKey = UserActions.ContextKey<NSManagedObjectContext>()

extension UserActions.Context {
    var managedObjectContext: NSManagedObjectContext {
        get {
            self[managedObjectContextKey]!
        }
        set {
            self[managedObjectContextKey] = newValue
        }
    }
}
