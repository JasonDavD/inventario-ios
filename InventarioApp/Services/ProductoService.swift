import Foundation
import CoreData

/// Lee productos de Core Data. **Core Data es la fuente de verdad de la UI**: la
/// pantalla nunca lee de la red directo, asi que funciona sin conexion siempre
/// que haya habido una sincronizacion previa.
struct ProductoService {

    private var contexto: NSManagedObjectContext { PersistenceController.shared.viewContext }

    /// Productos visibles, ordenados por nombre.
    ///
    /// Excluye los marcados con `pendienteEliminar`: para el usuario ya estan
    /// borrados, aunque la fila siga local hasta que el DELETE se confirme
    /// contra el servidor.
    func productosLocales() -> [ProductoEntity] {
        let request = NSFetchRequest<ProductoEntity>(entityName: "ProductoEntity")
        request.predicate = NSPredicate(format: "pendienteEliminar == NO")
        request.sortDescriptors = [
            NSSortDescriptor(
                key: "nombre",
                ascending: true,
                selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
            )
        ]
        return (try? contexto.fetch(request)) ?? []
    }

    func cantidadLocal() -> Int {
        let request = NSFetchRequest<ProductoEntity>(entityName: "ProductoEntity")
        request.predicate = NSPredicate(format: "pendienteEliminar == NO")
        return (try? contexto.count(for: request)) ?? 0
    }
}
