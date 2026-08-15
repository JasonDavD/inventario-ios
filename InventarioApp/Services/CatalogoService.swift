import Foundation
import CoreData

/// CRUD local de categorias y proveedores.
///
/// Mismo contrato que `ProductoService`: **Core Data es la fuente de verdad de
/// la UI** y toda escritura deja la fila en `estadoSync = 0`, para que el
/// `SyncManager` la levante en la proxima sincronizacion. Hasta entonces el
/// cambio existe solo en el dispositivo.
///
/// Los dos servicios viven en el mismo archivo porque comparten el helper de
/// abajo: son la misma mecanica sobre dos entidades distintas.
struct CategoriaService {

    private var contexto: NSManagedObjectContext { PersistenceController.shared.viewContext }

    func todas() -> [CategoriaEntity] {
        Catalogo.ordenadoPorNombre("CategoriaEntity", en: contexto)
    }

    @discardableResult
    func crear(nombre: String, descripcion: String?) -> CategoriaEntity {
        let categoria = CategoriaEntity(context: contexto)
        Catalogo.inicializarComoNueva(categoria)
        aplicar(nombre: nombre, descripcion: descripcion, a: categoria)
        PersistenceController.shared.saveContext()
        return categoria
    }

    func actualizar(_ categoria: CategoriaEntity, nombre: String, descripcion: String?) {
        aplicar(nombre: nombre, descripcion: descripcion, a: categoria)
        PersistenceController.shared.saveContext()
    }

    func marcarParaEliminar(_ categoria: CategoriaEntity) {
        Catalogo.marcarParaEliminar(categoria, en: contexto)
    }

    private func aplicar(nombre: String, descripcion: String?, a categoria: CategoriaEntity) {
        categoria.nombre = nombre
        categoria.descripcion = descripcion
        categoria.estadoSync = 0
    }
}

struct ProveedorService {

    private var contexto: NSManagedObjectContext { PersistenceController.shared.viewContext }

    func todos() -> [ProveedorEntity] {
        Catalogo.ordenadoPorNombre("ProveedorEntity", en: contexto)
    }

    @discardableResult
    func crear(nombre: String, telefono: String?, direccion: String?) -> ProveedorEntity {
        let proveedor = ProveedorEntity(context: contexto)
        Catalogo.inicializarComoNueva(proveedor)
        aplicar(nombre: nombre, telefono: telefono, direccion: direccion, a: proveedor)
        PersistenceController.shared.saveContext()
        return proveedor
    }

    func actualizar(_ proveedor: ProveedorEntity, nombre: String, telefono: String?, direccion: String?) {
        aplicar(nombre: nombre, telefono: telefono, direccion: direccion, a: proveedor)
        PersistenceController.shared.saveContext()
    }

    func marcarParaEliminar(_ proveedor: ProveedorEntity) {
        Catalogo.marcarParaEliminar(proveedor, en: contexto)
    }

    private func aplicar(nombre: String, telefono: String?, direccion: String?, a proveedor: ProveedorEntity) {
        proveedor.nombre = nombre
        proveedor.telefono = telefono
        proveedor.direccion = direccion
        proveedor.estadoSync = 0
    }
}

// MARK: - Mecanica comun

/// Lo que categorias y proveedores hacen igual. Se accede por KVC porque las dos
/// entidades comparten los atributos de control pero no un tipo comun: las
/// clases las genera `momc` desde el `.xcdatamodeld` y no hay donde meter un
/// protocolo a mano.
enum Catalogo {

    static func ordenadoPorNombre<T: NSManagedObject>(
        _ nombreEntidad: String,
        en contexto: NSManagedObjectContext
    ) -> [T] {
        let request = NSFetchRequest<T>(entityName: nombreEntidad)
        // Lo marcado para eliminar ya no existe para el usuario, aunque la fila
        // siga local hasta que el DELETE se confirme contra el servidor.
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

    /// `apiId` queda nil: la fila todavia no existe en el servidor. El
    /// `SyncManager` lo completa cuando el POST devuelve el id asignado.
    static func inicializarComoNueva(_ entidad: NSManagedObject) {
        entidad.setValue(UUID().uuidString, forKey: "localId")
        entidad.setValue(nil, forKey: "apiId")
        entidad.setValue(Int16(0), forKey: "estadoSync")
        entidad.setValue(false, forKey: "pendienteEliminar")
    }

    /// Borrado logico: la fila se marca y sigue local hasta que el DELETE se
    /// confirme contra el servidor. Lo que nunca llego al servidor
    /// (`apiId == nil`) no tiene nada que borrar alla, asi que se elimina ya.
    static func marcarParaEliminar(_ entidad: NSManagedObject, en contexto: NSManagedObjectContext) {
        if entidad.value(forKey: "apiId") == nil {
            contexto.delete(entidad)
        } else {
            entidad.setValue(true, forKey: "pendienteEliminar")
            entidad.setValue(Int16(0), forKey: "estadoSync")
        }
        PersistenceController.shared.saveContext()
    }
}
