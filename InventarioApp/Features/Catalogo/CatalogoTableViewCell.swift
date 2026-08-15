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

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = Theme.Color.surfaceContainerLowest

        pendienteChipView.layer.cornerRadius = Theme.Radius.base
        pendienteChipView.layer.cornerCurve = .continuous
        pendienteChipView.backgroundColor = Theme.Color.industrialOrange.withAlphaComponent(0.12)

        let fondoSeleccion = UIView()
        fondoSeleccion.backgroundColor = Theme.Color.surfaceTonal
        selectedBackgroundView = fondoSeleccion
    }

    func configurar(nombre: String?, detalle: String?, pendiente: Bool) {
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

        // Cambio local que todavia no llego al servidor.
        pendienteChipView.isHidden = !pendiente
        pendienteLabel.aplicar(
            .labelMD,
            color: Theme.Color.industrialOrange,
            texto: "PENDIENTE",
            alineacion: .center
        )
    }
}
