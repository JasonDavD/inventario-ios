import Foundation

final class ProveedorFormViewModel {

    private let service = ProveedorService()

    private(set) var proveedor: ProveedorEntity?

    var esEdicion: Bool { proveedor != nil }
    var titulo: String { esEdicion ? "Editar proveedor" : "Nuevo proveedor" }

    var estaPendienteDeSincronizar: Bool {
        guard let proveedor else { return false }
        return proveedor.estadoSync == 0 || proveedor.apiId == nil
    }

    /// El logo no se puede subir desde este formulario: el backend lo asocia por
    /// `POST /api/proveedores/{id}/logo`, que necesita el id del proveedor ya
    /// creado. Es la misma limitacion que tienen las imagenes de producto.
    var puedeSubirLogo: Bool { proveedor?.apiId != nil }

    init(proveedor: ProveedorEntity?) {
        self.proveedor = proveedor
    }

    /// Devuelve el mensaje de error, o `nil` si guardo bien.
    func guardar(nombre: String, telefono: String, direccion: String) -> String? {
        let nombreLimpio = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nombreLimpio.isEmpty else {
            return "El nombre no puede estar vacio"
        }

        let telefonoFinal = Self.opcional(telefono)
        let direccionFinal = Self.opcional(direccion)

        if let proveedor {
            service.actualizar(
                proveedor,
                nombre: nombreLimpio,
                telefono: telefonoFinal,
                direccion: direccionFinal
            )
        } else {
            proveedor = service.crear(
                nombre: nombreLimpio,
                telefono: telefonoFinal,
                direccion: direccionFinal
            )
        }
        return nil
    }

    /// Vacio y "sin dato" son lo mismo para el backend, que acepta null en los
    /// dos campos. Mandar "" dejaria filas con strings vacios sin motivo.
    private static func opcional(_ texto: String) -> String? {
        let limpio = texto.trimmingCharacters(in: .whitespacesAndNewlines)
        return limpio.isEmpty ? nil : limpio
    }
}
