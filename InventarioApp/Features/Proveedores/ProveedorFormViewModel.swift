import UIKit

final class ProveedorFormViewModel {

    var onLogoCambio: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoadingChanged: ((Bool) -> Void)?

    private let service = ProveedorService()
    private let imagenService = ImagenService()

    private(set) var proveedor: ProveedorEntity?

    var esEdicion: Bool { proveedor != nil }
    var titulo: String { esEdicion ? "Editar proveedor" : "Nuevo proveedor" }

    var estaPendienteDeSincronizar: Bool {
        guard let proveedor else { return false }
        return proveedor.estadoSync == 0 || proveedor.apiId == nil
    }

    /// El backend asocia el logo por `POST /api/proveedores/{id}/logo`, que
    /// necesita el id del proveedor ya creado. Es la misma limitacion que tienen
    /// las imagenes de producto: no hay forma de hacerlo offline.
    var puedeSubirLogo: Bool { proveedor?.apiId != nil }

    var logoUrl: String? { proveedor?.logoUrl }

    /// Por que no se puede subir el logo, o `nil` si si se puede.
    var motivoParaNoSubirLogo: String? {
        guard proveedor != nil else {
            return "Guardá el proveedor y sincronizalo; recien despues vas a poder subirle el logo."
        }
        guard puedeSubirLogo else {
            return "Este proveedor todavia no se sincronizo. Tocá Sincronizar en el listado y despues vas a poder subirle el logo."
        }
        return nil
    }

    init(proveedor: ProveedorEntity?) {
        self.proveedor = proveedor
    }

    // MARK: - Logo

    func subirLogo(_ imagen: UIImage) {
        guard let apiId = proveedor?.apiId else { return }

        onLoadingChanged?(true)
        imagenService.subirLogo(imagen, aProveedorConApiId: apiId.int64Value) { [weak self] resultado in
            guard let self else { return }
            self.onLoadingChanged?(false)
            switch resultado {
            case .success:
                // `subirLogo` vuelve a bajar del servidor, asi que `logoUrl` ya
                // es la de Cloudinary y no hay que armarla a mano.
                self.onLogoCambio?()
            case .failure(let error):
                self.onError?(error.errorDescription ?? "No se pudo subir el logo")
            }
        }
    }

    /// Devuelve el mensaje de error, o `nil` si guardo bien.
    func guardar(nombre: String, telefono: String, direccion: String) -> String? {
        let nombreLimpio = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nombreLimpio.isEmpty else {
            return "El nombre no puede estar vacio"
        }

        let telefonoFinal = Self.opcional(telefono)
        let direccionFinal = Self.opcional(direccion)

        let esAlta = proveedor == nil

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

        BitacoraService.shared.registrar(esAlta ? .creo : .edito, sobre: .proveedor, nombre: nombreLimpio)
        return nil
    }

    /// Vacio y "sin dato" son lo mismo para el backend, que acepta null en los
    /// dos campos. Mandar "" dejaria filas con strings vacios sin motivo.
    private static func opcional(_ texto: String) -> String? {
        let limpio = texto.trimmingCharacters(in: .whitespacesAndNewlines)
        return limpio.isEmpty ? nil : limpio
    }
}
