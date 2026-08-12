import CoreData

@objc(ProductoEntity)
public class ProductoEntity: NSManagedObject {
}

extension ProductoEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductoEntity> {
        NSFetchRequest<ProductoEntity>(entityName: "ProductoEntity")
    }

    @NSManaged public var localId: String
    @NSManaged public var apiId: NSNumber?
    @NSManaged public var nombre: String
    @NSManaged public var precio: Double
    @NSManaged public var stock: Int32
    @NSManaged public var fechaRegistro: Date?
    @NSManaged public var estadoSync: Int16
    @NSManaged public var pendienteEliminar: Bool
    @NSManaged public var categoria: CategoriaEntity?
    @NSManaged public var proveedor: ProveedorEntity?
    @NSManaged public var imagenes: NSSet?
}
