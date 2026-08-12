import CoreData

@objc(ProductoImagenEntity)
public class ProductoImagenEntity: NSManagedObject {
}

extension ProductoImagenEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProductoImagenEntity> {
        NSFetchRequest<ProductoImagenEntity>(entityName: "ProductoImagenEntity")
    }

    @NSManaged public var localId: String
    @NSManaged public var apiId: NSNumber?
    @NSManaged public var url: String
    @NSManaged public var publicId: String
    @NSManaged public var orden: Int16
    @NSManaged public var producto: ProductoEntity?
}
