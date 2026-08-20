import Foundation

final class BitacoraListViewModel {

    var onCambio: (() -> Void)?
    var onError: ((String) -> Void)?
    var onLoadingChanged: ((Bool) -> Void)?

    private(set) var eventos: [EventoBitacora] = []

    private let service = BitacoraService.shared

    var estaVacio: Bool { eventos.isEmpty }

    /// Igual que usuarios, esto lee de la red y no de Core Data — pero de
    /// Firebase, no del backend propio. No hay copia local de la bitacora.
    func cargar() {
        onLoadingChanged?(true)
        service.todos { [weak self] resultado in
            guard let self else { return }
            self.onLoadingChanged?(false)
            switch resultado {
            case .success(let eventos):
                self.eventos = eventos
                self.onCambio?()
            case .failure(let error):
                self.onError?(error.errorDescription ?? "No se pudo cargar la bitacora")
            }
        }
    }

    func evento(en indice: Int) -> EventoBitacora? {
        eventos.indices.contains(indice) ? eventos[indice] : nil
    }
}
