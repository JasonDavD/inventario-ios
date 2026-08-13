import Foundation

/// Reflejo del JSON que devuelve la API. Distinto de `ProductoEntity`, que es la
/// entidad local de Core Data: el DTO no tiene `localId` ni estado de sync.
///
/// `categoria` y `proveedor` pueden venir `null` (ver el contrato en PLAN.md).
struct ProductoDTO: Decodable {
    let id: Int64
    let nombre: String
    let precio: Double
    let stock: Int32
    let fechaRegistro: Date?
    let categoria: CategoriaDTO?
    let proveedor: ProveedorDTO?
    let imagenes: [ImagenDTO]?
}

struct CategoriaDTO: Decodable {
    let id: Int64
    let nombre: String
    let descripcion: String?
}

struct ProveedorDTO: Decodable {
    let id: Int64
    let nombre: String
    let telefono: String?
    let direccion: String?
    let logoUrl: String?
    let logoPublicId: String?
}

struct ImagenDTO: Decodable {
    let id: Int64
    let url: String
    let publicId: String?
    let orden: Int16?
}
