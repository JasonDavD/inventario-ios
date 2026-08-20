import Foundation

final class CategoriaFormViewModel {

    private let service = CategoriaService()

    private(set) var categoria: CategoriaEntity?

    var esEdicion: Bool { categoria != nil }
    var titulo: String { esEdicion ? "Editar categoria" : "Nueva categoria" }

    /// Una categoria sin `apiId` todavia no existe en el servidor, asi que
    /// ningun producto puede referenciarla al sincronizar. Se avisa en pantalla
    /// porque explica por que el producto puede subir sin categoria.
    var estaPendienteDeSincronizar: Bool {
        guard let categoria else { return false }
        return categoria.estadoSync == 0 || categoria.apiId == nil
    }

    init(categoria: CategoriaEntity?) {
        self.categoria = categoria
    }

    /// Devuelve el mensaje de error, o `nil` si guardo bien.
    func guardar(nombre: String, descripcion: String) -> String? {
        let nombreLimpio = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nombreLimpio.isEmpty else {
            return "El nombre no puede estar vacio"
        }

        // Vacio y "sin descripcion" son lo mismo para el backend, que la acepta
        // null. Mandar "" dejaria filas con un string vacio sin motivo.
        let descripcionLimpia = descripcion.trimmingCharacters(in: .whitespacesAndNewlines)
        let descripcionFinal = descripcionLimpia.isEmpty ? nil : descripcionLimpia

        let esAlta = categoria == nil

        if let categoria {
            service.actualizar(categoria, nombre: nombreLimpio, descripcion: descripcionFinal)
        } else {
            categoria = service.crear(nombre: nombreLimpio, descripcion: descripcionFinal)
        }

        BitacoraService.shared.registrar(esAlta ? .creo : .edito, sobre: .categoria, nombre: nombreLimpio)
        return nil
    }
}
