import Foundation

final class UsuarioFormViewModel {

    var onGuardado: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoadingChanged: ((Bool) -> Void)?

    private(set) var usuario: UsuarioDTO?
    private let service = UsuarioService()

    var rolesSeleccionados: Set<RolDisponible> = []
    var habilitado: Bool = true

    var esEdicion: Bool { usuario != nil }
    var titulo: String { esEdicion ? "Editar usuario" : "Nuevo usuario" }

    /// Editarse a uno mismo es valido, pero hay dos cambios que dejarian la
    /// sesion sin poder volver a entrar: sacarse ADMIN o desactivarse. Se
    /// bloquean los dos.
    var esElUsuarioDeLaSesion: Bool {
        usuario?.username == SessionManager.shared.username
    }

    /// En el alta la contraseña es obligatoria; en la edicion, vacia significa
    /// "no la toques" (asi lo trata el backend).
    var ayudaDePassword: String {
        esEdicion
            ? "Dejala vacia para no cambiarla."
            : "La va a necesitar la persona para entrar por primera vez."
    }

    init(usuario: UsuarioDTO?) {
        self.usuario = usuario
        if let usuario {
            habilitado = usuario.enabled
            rolesSeleccionados = Set(usuario.roles.compactMap { RolDisponible.desde($0) })
        } else {
            // Un usuario nuevo arranca como LECTOR: es el rol que menos puede
            // hacer, y subir de permisos tiene que ser una decision explicita.
            rolesSeleccionados = [.lector]
        }
    }

    // MARK: - Guardado

    /// Devuelve el mensaje de error de validacion, o `nil` si la request salio.
    /// El resultado del servidor llega por `onGuardado` / `onError`.
    func guardar(username: String, password: String) -> String? {
        let usuarioLimpio = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !usuarioLimpio.isEmpty else {
            return "El nombre de usuario no puede estar vacio"
        }

        guard !rolesSeleccionados.isEmpty else {
            return "Elegí al menos un rol"
        }

        if esElUsuarioDeLaSesion {
            guard rolesSeleccionados.contains(.admin) else {
                return "No podés sacarte el rol de administrador a vos mismo: te quedarias sin acceso a esta pantalla"
            }
            guard habilitado else {
                return "No podés desactivar tu propio usuario"
            }
        }

        let passwordLimpia = password.trimmingCharacters(in: .whitespacesAndNewlines)
        if !esEdicion && passwordLimpia.isEmpty {
            return "Poné una contraseña para el usuario nuevo"
        }

        let cuerpo = UsuarioRequest(
            username: usuarioLimpio,
            password: passwordLimpia.isEmpty ? nil : passwordLimpia,
            enabled: habilitado,
            roles: rolesSeleccionados.map(\.rawValue).sorted()
        )

        onLoadingChanged?(true)
        let alTerminar: (Result<UsuarioDTO, APIError>) -> Void = { [weak self] resultado in
            guard let self else { return }
            self.onLoadingChanged?(false)
            switch resultado {
            case .success:
                self.onGuardado?()
            case .failure(let error):
                self.onError?(Self.mensaje(para: error))
            }
        }

        if let existente = usuario {
            service.actualizar(id: existente.id, cuerpo, completion: alTerminar)
        } else {
            service.crear(cuerpo, completion: alTerminar)
        }
        return nil
    }

    /// El backend tiene el `username` como UNIQUE, asi que un choque llega como
    /// error de servidor sin mensaje util. Se traduce a algo accionable.
    private static func mensaje(para error: APIError) -> String {
        if case .server(let status, let mensaje) = error, status == 500 || status == 409 {
            return "No se pudo guardar. Puede que ya exista un usuario con ese nombre.\n\n(\(mensaje))"
        }
        return error.errorDescription ?? "No se pudo guardar el usuario"
    }
}
