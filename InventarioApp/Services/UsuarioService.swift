import Foundation

/// ABM de usuarios contra `/api/usuarios`. Todo el prefijo pide ADMIN en el
/// backend (ver `SecurityConfig` en `inventario-backend`).
///
/// **Esta es la unica parte de la app que NO es offline-first, junto con las
/// imagenes, y es deliberado:**
///
/// 1. Dar de alta un usuario sin conexion no significa nada: el backend hashea
///    el password con BCrypt y valida que el `username` sea unico. Encolarlo
///    solo serviria para descubrir el conflicto mucho despues.
/// 2. Guardar usuarios en Core Data implicaria tener contraseñas — aunque sea
///    de paso, aunque sea un rato — en el SQLite del dispositivo. No hay ningun
///    motivo para correr ese riesgo.
///
/// Por eso no hay `UsuarioEntity` ni nada de esto pasa por el `SyncManager`:
/// cada pantalla lee del servidor cuando aparece.
struct UsuarioService {

    func listar(completion: @escaping (Result<[UsuarioDTO], APIError>) -> Void) {
        APIClient.shared.get(.usuarios, completion: completion)
    }

    func crear(_ cuerpo: UsuarioRequest, completion: @escaping (Result<UsuarioDTO, APIError>) -> Void) {
        APIClient.shared.post(.usuarios, body: cuerpo, completion: completion)
    }

    func actualizar(
        id: Int64,
        _ cuerpo: UsuarioRequest,
        completion: @escaping (Result<UsuarioDTO, APIError>) -> Void
    ) {
        APIClient.shared.put(.usuario(id: id), body: cuerpo, completion: completion)
    }

    func eliminar(id: Int64, completion: @escaping (Result<Void, APIError>) -> Void) {
        APIClient.shared.delete(.usuario(id: id)) { (resultado: Result<RespuestaVacia, APIError>) in
            switch resultado {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
