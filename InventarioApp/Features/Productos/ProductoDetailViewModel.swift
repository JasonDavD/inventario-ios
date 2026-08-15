import UIKit

final class ProductoDetailViewModel {

    var onCambio: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoadingChanged: ((Bool) -> Void)?

    let producto: ProductoEntity
    private(set) var imagenes: [ProductoImagenEntity] = []

    private let service = ImagenService()

    init(producto: ProductoEntity) {
        self.producto = producto
        recargarImagenes()
    }

    // MARK: - Estado

    /// `apiId` nil significa que el producto todavia no existe en el servidor, y
    /// el backend necesita ese id para asociarle una imagen. Es la limitacion de
    /// diseño de PLAN.md: no hay forma de subir fotos offline.
    var estaSincronizado: Bool { producto.apiId != nil }

    var puedeGestionarImagenes: Bool {
        estaSincronizado && SessionManager.shared.puedeEditarProductos
    }

    /// El backend no acepta mas de 5 por producto.
    var alcanzoElMaximo: Bool { imagenes.count >= ImagenService.maximoPorProducto }

    var textoContadorDeFotos: String {
        "\(imagenes.count) de \(ImagenService.maximoPorProducto)"
    }

    /// Por que no se pueden agregar fotos, o `nil` si si se puede.
    var motivoParaNoAgregar: String? {
        if !estaSincronizado {
            return "Este producto todavia no se sincronizo. Tocá Sincronizar en el listado y despues vas a poder agregarle fotos."
        }
        if !SessionManager.shared.puedeEditarProductos {
            return "Tu usuario no tiene permiso para modificar productos."
        }
        if alcanzoElMaximo {
            return "Llegaste al maximo de \(ImagenService.maximoPorProducto) fotos. Borrá una para poder agregar otra."
        }
        return nil
    }

    // MARK: - Datos

    /// Ordena por `orden` y no por el orden del set: las relaciones to-many de
    /// Core Data no tienen orden garantizado, asi que sin esto las fotos se
    /// reacomodan solas entre recargas.
    func recargarImagenes() {
        let set = producto.imagenes as? Set<ProductoImagenEntity> ?? []
        imagenes = set.sorted { $0.orden < $1.orden }
        onCambio?()
    }

    // MARK: - Acciones

    func subir(_ imagen: UIImage) {
        guard let apiId = producto.apiId else { return }

        onLoadingChanged?(true)
        service.subirImagen(imagen, aProductoConApiId: apiId.int64Value) { [weak self] resultado in
            guard let self else { return }
            self.onLoadingChanged?(false)
            switch resultado {
            case .success:
                self.recargarImagenes()
            case .failure(let error):
                self.onError?(error.errorDescription ?? "No se pudo subir la foto")
            }
        }
    }

    func borrar(en indice: Int) {
        guard imagenes.indices.contains(indice),
              let apiId = producto.apiId,
              let imagenId = imagenes[indice].apiId else { return }

        onLoadingChanged?(true)
        service.borrarImagen(
            imagenId: imagenId.int64Value,
            deProductoConApiId: apiId.int64Value
        ) { [weak self] resultado in
            guard let self else { return }
            self.onLoadingChanged?(false)
            switch resultado {
            case .success:
                self.recargarImagenes()
            case .failure(let error):
                self.onError?(error.errorDescription ?? "No se pudo borrar la foto")
            }
        }
    }
}
