import Foundation
import CoreData

/// Lee y escribe productos en Core Data. **Core Data es la fuente de verdad de
/// la UI**: la pantalla nunca lee de la red directo, asi que funciona sin
/// conexion siempre que haya habido una sincronizacion previa.
///
/// Toda escritura deja la fila en `estadoSync = 0`. El `SyncManager` levanta
/// despues lo que quedo pendiente; hasta entonces el cambio existe solo local.
struct ProductoService {

    private var contexto: NSManagedObjectContext { PersistenceController.shared.viewContext }

    // MARK: - Lectura

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

    func categoriasLocales() -> [CategoriaEntity] {
        buscarOrdenadoPorNombre("CategoriaEntity")
    }

    func proveedoresLocales() -> [ProveedorEntity] {
        buscarOrdenadoPorNombre("ProveedorEntity")
    }

    private func buscarOrdenadoPorNombre<T: NSManagedObject>(_ entidad: String) -> [T] {
        let request = NSFetchRequest<T>(entityName: entidad)
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

    // MARK: - Escritura

    @discardableResult
    func crear(
        nombre: String,
        precio: Double,
        stock: Int32,
        categoria: CategoriaEntity?,
        proveedor: ProveedorEntity?
    ) -> ProductoEntity {
        let producto = ProductoEntity(context: contexto)
        producto.localId = UUID().uuidString
        // apiId queda nil: todavia no existe en el servidor. El SyncManager lo
        // completa cuando el POST devuelve el id asignado.
        producto.apiId = nil
        producto.estadoSync = 0
        producto.pendienteEliminar = false
        producto.fechaRegistro = Date()

        aplicar(nombre: nombre, precio: precio, stock: stock, categoria: categoria, proveedor: proveedor, a: producto)
        PersistenceController.shared.saveContext()
        return producto
    }

    func actualizar(
        _ producto: ProductoEntity,
        nombre: String,
        precio: Double,
        stock: Int32,
        categoria: CategoriaEntity?,
        proveedor: ProveedorEntity?
    ) {
        aplicar(nombre: nombre, precio: precio, stock: stock, categoria: categoria, proveedor: proveedor, a: producto)
        PersistenceController.shared.saveContext()
    }

    private func aplicar(
        nombre: String,
        precio: Double,
        stock: Int32,
        categoria: CategoriaEntity?,
        proveedor: ProveedorEntity?,
        a producto: ProductoEntity
    ) {
        producto.nombre = nombre
        producto.precio = precio
        producto.stock = stock
        producto.categoria = categoria
        producto.proveedor = proveedor
        // Marca la fila como pendiente de subir. Tambien protege el cambio: el
        // upsert de la bajada saltea todo lo que tenga estadoSync == 0.
        producto.estadoSync = 0
    }

    /// Borrado logico: la fila se marca y sigue local hasta que el DELETE se
    /// confirme contra el servidor. Recien ahi el `SyncManager` la borra.
    ///
    /// Un producto que nunca llego al servidor (`apiId == nil`) no tiene nada
    /// que borrar remoto, asi que se elimina directo.
    func marcarParaEliminar(_ producto: ProductoEntity) {
        if producto.apiId == nil {
            contexto.delete(producto)
        } else {
            producto.pendienteEliminar = true
            producto.estadoSync = 0
        }
        PersistenceController.shared.saveContext()
    }
}
