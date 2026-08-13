import Foundation

/// Cuerpo de POST/PUT de producto. **No es el mismo shape que `ProductoDTO`**:
/// al crear o editar, el backend solo espera `nombre`, `precio`, `stock` y
/// opcionalmente la referencia a categoria/proveedor por id.
struct ProductoRequest: Encodable {
    let nombre: String
    let precio: Double
    let stock: Int32
    let categoria: ReferenciaID?
    let proveedor: ReferenciaID?

    /// El backend referencia recursos relacionados como `{"id": N}`.
    struct ReferenciaID: Encodable {
        let id: Int64
    }

    /// Arma el cuerpo desde la entidad local.
    ///
    /// Solo se referencian categoria/proveedor que ya tengan `apiId`: una
    /// categoria creada offline todavia no existe en el servidor y mandarla
    /// haria fallar la request.
    init(entidad: ProductoEntity) {
        nombre = entidad.nombre ?? ""
        precio = entidad.precio
        stock = entidad.stock
        categoria = entidad.categoria?.apiId.map { ReferenciaID(id: $0.int64Value) }
        proveedor = entidad.proveedor?.apiId.map { ReferenciaID(id: $0.int64Value) }
    }
}
