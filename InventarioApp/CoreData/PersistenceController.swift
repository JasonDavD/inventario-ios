import CoreData

// El modelo (entidades/atributos/relaciones) se arma con el editor visual de Xcode
// en InventarioModel.xcdatamodeld — ver el esquema exacto a replicar en PLAN.md,
// seccion "Esquema de Core Data (armar en el editor visual)".
final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "InventarioModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("No se pudo cargar Core Data: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func saveContext() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            assertionFailure("Error guardando Core Data: \(error)")
        }
    }
}
