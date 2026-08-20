import UIKit

/// Celda de las listas de categorias y proveedores: nombre, un detalle
/// secundario y el chip PENDIENTE.
///
/// Las dos listas muestran exactamente la misma estructura, asi que comparten
/// clase. Cada escena tiene su propia celda prototipo en el Storyboard, las dos
/// con este `Identifier` — estan en escenas distintas, no chocan.
final class CatalogoTableViewCell: UITableViewCell {

    /// Tiene que coincidir con el `Identifier` de las celdas prototipo en
    /// Main.storyboard. Si no coinciden, `dequeueReusableCell` crashea.
    static let reuseIdentifier = "CatalogoCell"

    @IBOutlet weak var nombreLabel: UILabel!
    @IBOutlet weak var detalleLabel: UILabel!
    @IBOutlet weak var pendienteChipView: UIView!
    @IBOutlet weak var pendienteLabel: UILabel!

    /// **Opcional a proposito.** Esta clase la usan cuatro celdas prototipo
    /// (categorias, proveedores, usuarios y bitacora) y solo la de proveedores
    /// tiene logo. Si el outlet fuera `!`, las otras tres crashearian al
    /// tocarlo. Siendo `?`, cada escena conecta lo que tiene.
    @IBOutlet weak var logoImageView: UIImageView?

    /// Si la celda se reuso mientras la descarga estaba en vuelo, ese logo ya no
    /// corresponde a esta fila.
    private var urlActual: String?

    /// Estados que la celda sabe marcar. Es un enum cerrado y no un texto libre
    /// para que los chips no se multipliquen en colores y mayusculas distintas
    /// segun la pantalla.
    enum Chip {
        /// Cambio local que todavia no llego al servidor.
        case pendiente
        /// Usuario con `enabled = false`: existe pero no puede entrar.
        case inactivo

        var texto: String {
            switch self {
            case .pendiente: return "PENDIENTE"
            case .inactivo: return "INACTIVO"
            }
        }

        /// El DESIGN.md reserva el naranja para indicadores de estado; el gris
        /// de `outline` alcanza para algo que no reclama accion.
        var color: UIColor {
            switch self {
            case .pendiente: return Theme.Color.industrialOrange
            case .inactivo: return Theme.Color.outline
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = Theme.Color.surfaceContainerLowest

        pendienteChipView.layer.cornerRadius = Theme.Radius.base
        pendienteChipView.layer.cornerCurve = .continuous

        logoImageView?.layer.cornerRadius = Theme.Radius.base
        logoImageView?.layer.cornerCurve = .continuous
        logoImageView?.backgroundColor = Theme.Color.surfaceTonal
        logoImageView?.tintColor = Theme.Color.outline

        let fondoSeleccion = UIView()
        fondoSeleccion.backgroundColor = Theme.Color.surfaceTonal
        selectedBackgroundView = fondoSeleccion
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        urlActual = nil
        mostrarPlaceholderDeLogo()
    }

    /// `imagenURL` solo lo manda proveedores; el resto de las pantallas usa el
    /// valor por defecto y ni se entera de que existe.
    func configurar(nombre: String?, detalle: String?, chip: Chip?, imagenURL: String? = nil) {
        configurarLogo(imagenURL)

        nombreLabel.aplicar(
            .bodyLG,
            color: Theme.Color.charcoalDeep,
            texto: nombre ?? "(sin nombre)"
        )

        // El detalle es opcional en las dos entidades (una categoria puede no
        // tener descripcion, un proveedor puede no tener telefono).
        let detalleLimpio = detalle?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hayDetalle = !(detalleLimpio?.isEmpty ?? true)
        detalleLabel.isHidden = !hayDetalle
        detalleLabel.aplicar(.bodyMD, color: Theme.Color.charcoalMuted, texto: detalleLimpio)

        pendienteChipView.isHidden = (chip == nil)
        guard let chip else { return }

        pendienteChipView.backgroundColor = chip.color.withAlphaComponent(0.12)
        pendienteLabel.aplicar(
            .labelMD,
            color: chip.color,
            texto: chip.texto,
            alineacion: .center
        )
    }

    private func configurarLogo(_ urlTexto: String?) {
        // En las escenas sin logo no hay nada que hacer, ni siquiera placeholder.
        guard logoImageView != nil else { return }

        guard let urlTexto, !urlTexto.isEmpty else {
            urlActual = nil
            mostrarPlaceholderDeLogo()
            return
        }

        urlActual = urlTexto

        if let cacheada = DescargadorDeImagenes.shared.imagenCacheada(urlTexto) {
            mostrarLogo(cacheada)
            return
        }

        mostrarPlaceholderDeLogo()
        DescargadorDeImagenes.shared.descargar(urlTexto) { [weak self] imagen in
            guard let self, self.urlActual == urlTexto, let imagen else { return }
            self.mostrarLogo(imagen)
        }
    }

    private func mostrarLogo(_ imagen: UIImage) {
        logoImageView?.image = imagen
    }

    private func mostrarPlaceholderDeLogo() {
        logoImageView?.image = UIImage(systemName: "building.2")
    }
}
