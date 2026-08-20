import FirebaseDatabase
import Foundation

/// Lee y escribe la bitacora de auditoria en Firebase Realtime Database, con el
/// SDK oficial (`FirebaseDatabase`).
///
/// **Es la unica parte de la app que no usa `APIClient`.** Todo el consumo del
/// backend de Spring sigue con `URLSession` + `dataTask`; aca el SDK maneja el
/// transporte. La referencia sale de `Database.database()`, que se configura
/// sola a partir del `GoogleService-Info.plist` en `FirebaseApp.configure()`.
///
/// **Es online y no pasa por el `SyncManager`.** Igual que usuarios e imagenes:
/// no hay `BitacoraEntity` en Core Data ni cola de pendientes. Para una
/// auditoria eso es lo correcto — un registro que se encola en el dispositivo y
/// se sube cuando quiere no sirve como rastro confiable.
///
/// **Ningun error de aca puede romper una operacion del usuario.** Registrar es
/// un efecto secundario: si Firebase no contesta, el producto ya se guardo
/// igual. Por eso `registrar` no devuelve error y no tiene completion.
final class BitacoraService {

    static let shared = BitacoraService()

    /// Rama del arbol donde vive la bitacora. En Realtime Database no hay
    /// tablas: el arbol entero es un JSON y cada rama se direcciona por su ruta.
    private var referencia: DatabaseReference {
        Database.database().reference(withPath: "bitacora")
    }

    private init() {}

    /// Deja constancia de una accion. Dispara y se olvida.
    ///
    /// El usuario sale de `SessionManager` y no se recibe por parametro, para
    /// que ninguna pantalla pueda registrar un evento a nombre de otro.
    func registrar(_ accion: AccionBitacora, sobre entidad: EntidadBitacora, nombre: String) {
        let evento = EventoBitacora(
            accion: accion,
            entidad: entidad,
            nombre: nombre,
            usuario: SessionManager.shared.username ?? "desconocido"
        )

        // `childByAutoId` genera la clave ordenada por tiempo que el SDK usa para
        // las listas. `setValue` sin completion es exactamente "dispara y
        // olvida": el SDK reintenta solo si el envio no llega.
        referencia.childByAutoId().setValue(evento.comoDiccionario)
    }

    /// Baja la bitacora completa, de lo mas reciente a lo mas viejo.
    ///
    /// Se pide ordenado por `timestamp` y se invierte en el telefono:
    /// `queryOrdered` devuelve de menor a mayor, y aca interesa lo ultimo
    /// primero. `observeSingleEvent` lee una vez y se desuscribe — no se usa
    /// `observe` porque la pantalla no necesita actualizarse en vivo, y una
    /// suscripcion viva habria que darla de baja al salir.
    func todos(completion: @escaping (Result<[EventoBitacora], APIError>) -> Void) {
        referencia.queryOrdered(byChild: "timestamp").observeSingleEvent(of: .value) { snapshot in
            var eventos: [EventoBitacora] = []

            for hijo in snapshot.children {
                guard let hijo = hijo as? DataSnapshot,
                      let diccionario = hijo.value as? [String: Any],
                      let evento = EventoBitacora(diccionario: diccionario) else { continue }
                eventos.append(evento)
            }

            // El SDK ya entrega en el hilo principal, pero el orden viene
            // ascendente.
            completion(.success(eventos.reversed()))
        } withCancel: { error in
            completion(.failure(.server(status: 0, message: error.localizedDescription)))
        }
    }
}
