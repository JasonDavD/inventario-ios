import CoreData

@objc(CategoriaEntity)
public class CategoriaEntity: NSManagedObject {
}

extension CategoriaEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CategoriaEntity> {
        NSFetchRequest<CategoriaEntity>(entityName: "CategoriaEntity")
    }

    @NSManaged public var localId: String
    @NSManaged public var apiId: NSNumber?
    @NSManaged public var nombre: String
    @NSManaged public var descripcion: String?
    @NSManaged public var estadoSync: Int16
    @NSManaged public var pendienteEliminar: Bool
    @NSManaged public var productos: NSSet?
}
