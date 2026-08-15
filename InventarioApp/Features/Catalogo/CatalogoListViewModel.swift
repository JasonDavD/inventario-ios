import Foundation
import CoreData

/// ViewModel de las listas de categorias y proveedores.
///
/// Las dos hacen lo mismo — leer de Core Data, marcar una baja, disparar el
/// sync — y solo cambian la entidad y el servicio. Se parametriza con closures
/// en vez de duplicar el archivo: `CatalogoListViewModel<CategoriaEntity>` y
/// `CatalogoListViewModel<ProveedorEntity>`.
///
/// Es generico y por eso no puede ser el `customClass` de una escena, pero eso
/// no importa: el `customClass` es el ViewController, que instancia el suyo.
final class CatalogoListViewModel<T: NSManagedObject> {

    var onCambio: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoadingChanged: ((Bool) -> Void)?

    private(set) var items: [T] = []

    private let cargar: () -> [T]
    private let borrar: (T) -> Void

    var estaVacio: Bool { items.isEmpty }

    init(cargar: @escaping () -> [T], borrar: @escaping (T) -> Void) {
        self.cargar = cargar
        self.borrar = borrar
    }

    /// Lee de Core Data. No toca la red: es lo que hace que la pantalla funcione
    /// sin conexion.
    func cargarLocales() {
        items = cargar()
        onCambio?()
    }

    /// Marca la fila para eliminar. Sigue local hasta que el DELETE se confirme
    /// contra el servidor, pero desaparece de la lista al instante.
    func eliminar(en indice: Int) {
        guard items.indices.contains(indice) else { return }
        borrar(items[indice])
        cargarLocales()
    }

    /// Sube pendientes, procesa bajas y baja del servidor, en ese orden. Es la
    /// misma sincronizacion global que dispara la lista de productos: el
    /// `SyncManager` recorre las tres entidades.
    func sincronizar() {
        onLoadingChanged?(true)
        SyncManager.shared.sincronizar { [weak self] resultado in
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
