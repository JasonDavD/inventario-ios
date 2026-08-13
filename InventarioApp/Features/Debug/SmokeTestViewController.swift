import UIKit
import CoreData

// TEMPORAL — Fase 1. Verifica en pantalla que el stack de Core Data levanta:
// inserta una CategoriaEntity, la lee con NSFetchRequest y la borra.
// Fase 2 reemplaza esta escena por la de Login y este archivo se elimina.
final class SmokeTestViewController: UIViewController {

    @IBOutlet weak var resultLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        resultLabel.text = correrPrueba()
    }

    private func correrPrueba() -> String {
        let context = PersistenceController.shared.viewContext
        let marca = UUID().uuidString

        let categoria = CategoriaEntity(context: context)
        categoria.localId = marca
        categoria.nombre = "Categoria de prueba"
        categoria.estadoSync = 0
        categoria.pendienteEliminar = false

        do {
            try context.save()
        } catch {
            return "FALLO al guardar\n\(error.localizedDescription)"
        }

        let request = NSFetchRequest<CategoriaEntity>(entityName: "CategoriaEntity")
        request.predicate = NSPredicate(format: "localId == %@", marca)

        let encontradas: [CategoriaEntity]
        do {
            encontradas = try context.fetch(request)
        } catch {
            return "FALLO al leer\n\(error.localizedDescription)"
        }

        guard let recuperada = encontradas.first else {
            return "FALLO: guardo pero el fetch no la encontro"
        }
        let nombre = recuperada.nombre ?? "(sin nombre)"

        // Se limpia para que cada corrida arranque de cero.
        context.delete(recuperada)
        PersistenceController.shared.saveContext()

        return """
        OK — el stack de Core Data levanta

        Insertada y leida: \(nombre)

        Entidades en el modelo:
        \(entidadesDelModelo())
        """
    }

    private func entidadesDelModelo() -> String {
        PersistenceController.shared.container.managedObjectModel.entities
            .compactMap { $0.name }
            .sorted()
            .joined(separator: "\n")
    }
}
