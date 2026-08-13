import Foundation

final class ProductoListViewModel {

    var onCambio: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoadingChanged: ((Bool) -> Void)?

    private(set) var productos: [ProductoEntity] = []

    private let service = ProductoService()

    var estaVacio: Bool { productos.isEmpty }

    /// Lee de Core Data. No toca la red: es lo que hace que la pantalla funcione
    /// sin conexion.
    func cargarLocales() {
        productos = service.productosLocales()
        onCambio?()
    }

    func sincronizar() {
        onLoadingChanged?(true)
        SyncManager.shared.descargarDelServidor { [weak self] resultado in
            guard let self else { return }
            self.onLoadingChanged?(false)
            switch resultado {
            case .success:
                self.cargarLocales()
            case .failure(let error):
                // Los datos locales siguen en pantalla: que falle el sync no
                // vacia la lista.
                self.onError?(error.errorDescription ?? "No se pudo sincronizar")
            }
        }
    }
}
