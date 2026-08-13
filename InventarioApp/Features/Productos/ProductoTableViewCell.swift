import UIKit

final class ProductoTableViewCell: UITableViewCell {

    /// Tiene que coincidir con el `Identifier` de la celda prototipo en
    /// Main.storyboard. Si no coinciden, `dequeueReusableCell` crashea.
    static let reuseIdentifier = "ProductoCell"

    @IBOutlet weak var nombreLabel: UILabel!
    @IBOutlet weak var categoriaChipView: UIView!
    @IBOutlet weak var categoriaLabel: UILabel!
    @IBOutlet weak var precioLabel: UILabel!
    @IBOutlet weak var stockLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = Theme.Color.surfaceContainerLowest

        categoriaChipView.backgroundColor = Theme.Color.surfaceTonal
        categoriaChipView.layer.cornerRadius = Theme.Radius.base
        categoriaChipView.layer.cornerCurve = .continuous

        let fondoSeleccion = UIView()
        fondoSeleccion.backgroundColor = Theme.Color.surfaceTonal
        selectedBackgroundView = fondoSeleccion
    }

    func configurar(con producto: ProductoEntity) {
        nombreLabel.aplicar(
            .bodyLG,
            color: Theme.Color.charcoalDeep,
            texto: producto.nombre ?? "(sin nombre)"
        )

        // La categoria puede venir null desde la API; sin ella el chip no se muestra.
        let categoria = producto.categoria?.nombre
        categoriaChipView.isHidden = (categoria == nil)
        categoriaLabel.aplicar(
            .labelMD,
            color: Theme.Color.charcoalMuted,
            texto: categoria?.uppercased(),
            alineacion: .center
        )

        precioLabel.aplicar(
            .bodyLG,
            color: Theme.Color.charcoalDeep,
            texto: Formato.precio(producto.precio),
            alineacion: .right
        )

        // El DESIGN.md reserva el naranja para indicadores de estado. Quedarse sin
        // stock es el unico estado de esta pantalla que lo amerita.
        let sinStock = producto.stock <= 0
        stockLabel.aplicar(
            .bodyMD,
            color: sinStock ? Theme.Color.industrialOrange : Theme.Color.charcoalMuted,
            texto: sinStock ? "Sin stock" : "\(producto.stock) u.",
            alineacion: .right
        )
    }
}
