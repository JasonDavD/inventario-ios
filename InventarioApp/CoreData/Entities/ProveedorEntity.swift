import CoreData

@objc(ProveedorEntity)
public class ProveedorEntity: NSManagedObject {
}

extension ProveedorEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProveedorEntity> {
        NSFetchRequest<ProveedorEntity>(entityName: "ProveedorEntity")
    }

    @NSManaged public var localId: String
    @NSManaged public var apiId: NSNumber?
    @NSManaged public var nombre: String
    @NSManaged public var telefono: String?
    @NSManaged public var direccion: String?
    @NSManaged public var logoUrl: String?
    @NSManaged public var logoPublicId: String?
    @NSManaged public var estadoSync: Int16
    @NSManaged public var pendienteEliminar: Bool
    @NSManaged public var productos: NSSet?
}
