import Foundation

final class UsuarioListViewModel {

    var onCambio: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoadingChanged: ((Bool) -> Void)?

    private(set) var usuarios: [UsuarioDTO] = []

    private let service = UsuarioService()

    var estaVacio: Bool { usuarios.isEmpty }

    /// A diferencia del resto de la app, esto lee del servidor y no de Core
    /// Data: no hay copia local de usuarios (ver `UsuarioService`).
    func cargar() {
        onLoadingChanged?(true)
        service.listar { [weak self] resultado in
            guard let self else { return }
            self.onLoadingChanged?(false)
            switch resultado {
            case .success(let usuarios):
                // Orden estable por username: el backend devuelve el orden de la
                // tabla, que cambia al editar.
                self.usuarios = usuarios.sorted {
                    $0.username.localizedCaseInsensitiveCompare($1.username) == .orderedAscending
                }
                self.onCambio?()
            case .failure(let error):
                self.onError?(error.errorDescription ?? "No se pudo cargar la lista de usuarios")
            }
        }
    }

    /// Borrarse a uno mismo deja la sesion viva con un usuario que ya no existe:
    /// todo sigue andando hasta que el token vence y ahi no se puede volver a
    /// entrar. Se bloquea en la UI antes de que pase.
    func esElUsuarioDeLaSesion(_ usuario: UsuarioDTO) -> Bool {
        usuario.username == SessionManager.shared.username
    }

    func eliminar(en indice: Int) {
        guard usuarios.indices.contains(indice) else { return }
        let usuario = usuarios[indice]

        onLoadingChanged?(true)
        service.eliminar(id: usuario.id) { [weak self] resultado in
            guard let self else { return }
            self.onLoadingChanged?(false)
            switch resultado {
            case .success:
                self.cargar()
            case .failure(let error):
                self.onError?(error.errorDescription ?? "No se pudo eliminar el usuario")
            }
        }
    }
}
