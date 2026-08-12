import CoreData

// Modelo armado 100% en codigo, sin archivo .xcdatamodeld (ver nota tecnica en PLAN.md:
// se evita el editor visual de Xcode porque no se puede validar sin abrir Xcode).
final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "InventarioModel", managedObjectModel: PersistenceController.makeModel())
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

    // MARK: - Modelo

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let categoria = makeCategoriaEntity()
        let proveedor = makeProveedorEntity()
        let producto = makeProductoEntity()
        let imagen = makeProductoImagenEntity()

        let (productoToCategoria, categoriaToProductos) = makeRelationshipPair(
            toOneName: "categoria", toOneSource: producto, toOneDestination: categoria,
            toManyName: "productos", deleteRule: .nullifyDeleteRule
        )
        let (productoToProveedor, proveedorToProductos) = makeRelationshipPair(
            toOneName: "proveedor", toOneSource: producto, toOneDestination: proveedor,
            toManyName: "productos", deleteRule: .nullifyDeleteRule
        )
        let (imagenToProducto, productoToImagenes) = makeRelationshipPair(
            toOneName: "producto", toOneSource: imagen, toOneDestination: producto,
            toManyName: "imagenes", deleteRule: .nullifyDeleteRule
        )
        // Borrar un producto borra sus imagenes en cascada (la relacion inversa, del lado producto, es la que manda el cascade).
        productoToImagenes.deleteRule = .cascadeDeleteRule

        producto.properties.append(contentsOf: [productoToCategoria, productoToProveedor, productoToImagenes])
        categoria.properties.append(categoriaToProductos)
        proveedor.properties.append(proveedorToProductos)
        imagen.properties.append(imagenToProducto)

        model.entities = [categoria, proveedor, producto, imagen]
        return model
    }

    /// Crea un par de relaciones inversas: una to-one (source -> destination) y su inversa to-many (destination -> source).
    private static func makeRelationshipPair(
        toOneName: String, toOneSource: NSEntityDescription, toOneDestination: NSEntityDescription,
        toManyName: String, deleteRule: NSDeleteRule
    ) -> (toOne: NSRelationshipDescription, toMany: NSRelationshipDescription) {
        let toOne = NSRelationshipDescription()
        toOne.name = toOneName
        toOne.destinationEntity = toOneDestination
        toOne.minCount = 0
        toOne.maxCount = 1
        toOne.deleteRule = deleteRule

        let toMany = NSRelationshipDescription()
        toMany.name = toManyName
        toMany.destinationEntity = toOneSource
        toMany.minCount = 0
        toMany.maxCount = 0 // 0 = sin limite (to-many)
        toMany.deleteRule = .nullifyDeleteRule

        toOne.inverseRelationship = toMany
        toMany.inverseRelationship = toOne

        return (toOne, toMany)
    }

    private static func attribute(_ name: String, _ type: NSAttributeType, optional: Bool = false) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        return attribute
    }

    private static func makeCategoriaEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CategoriaEntity"
        entity.managedObjectClassName = "CategoriaEntity"
        entity.properties = [
            attribute("localId", .stringAttributeType),
            attribute("apiId", .integer64AttributeType, optional: true),
            attribute("nombre", .stringAttributeType),
            attribute("descripcion", .stringAttributeType, optional: true),
            attribute("estadoSync", .integer16AttributeType),
            attribute("pendienteEliminar", .booleanAttributeType)
        ]
        return entity
    }

    private static func makeProveedorEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "ProveedorEntity"
        entity.managedObjectClassName = "ProveedorEntity"
        entity.properties = [
            attribute("localId", .stringAttributeType),
            attribute("apiId", .integer64AttributeType, optional: true),
            attribute("nombre", .stringAttributeType),
            attribute("telefono", .stringAttributeType, optional: true),
            attribute("direccion", .stringAttributeType, optional: true),
            attribute("logoUrl", .stringAttributeType, optional: true),
            attribute("logoPublicId", .stringAttributeType, optional: true),
            attribute("estadoSync", .integer16AttributeType),
            attribute("pendienteEliminar", .booleanAttributeType)
        ]
        return entity
    }

    private static func makeProductoEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "ProductoEntity"
        entity.managedObjectClassName = "ProductoEntity"
        entity.properties = [
            attribute("localId", .stringAttributeType),
            attribute("apiId", .integer64AttributeType, optional: true),
            attribute("nombre", .stringAttributeType),
            attribute("precio", .doubleAttributeType),
            attribute("stock", .integer32AttributeType),
            attribute("fechaRegistro", .dateAttributeType, optional: true),
            attribute("estadoSync", .integer16AttributeType),
            attribute("pendienteEliminar", .booleanAttributeType)
        ]
        return entity
    }

    private static func makeProductoImagenEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "ProductoImagenEntity"
        entity.managedObjectClassName = "ProductoImagenEntity"
        entity.properties = [
            attribute("localId", .stringAttributeType),
            attribute("apiId", .integer64AttributeType, optional: true),
            attribute("url", .stringAttributeType),
            attribute("publicId", .stringAttributeType),
            attribute("orden", .integer16AttributeType)
        ]
        return entity
    }
}
