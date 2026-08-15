import Foundation

/// Cuerpo de POST/PUT de categoria. Igual que con producto, el `id` no va en el
/// cuerpo: lo asigna el backend en el POST y viaja en la URL en el PUT.
struct CategoriaRequest: Encodable {
    let nombre: String
    let descripcion: String?

    init(entidad: CategoriaEntity) {
        nombre = entidad.nombre ?? ""
        descripcion = entidad.descripcion
    }
}

/// Cuerpo de POST/PUT de proveedor.
///
/// `logoUrl` y `logoPublicId` quedan afuera a proposito: los escribe el backend
/// cuando se sube el logo por `POST /api/proveedores/{id}/logo`. Mandarlos desde
/// aca pisaria el valor real del servidor con lo que tenga la copia local, que
/// puede estar desactualizada.
struct ProveedorRequest: Encodable {
    let nombre: String
    let telefono: String?
    let direccion: String?

    init(entidad: ProveedorEntity) {
        nombre = entidad.nombre ?? ""
        telefono = entidad.telefono
        direccion = entidad.direccion
    }
}
