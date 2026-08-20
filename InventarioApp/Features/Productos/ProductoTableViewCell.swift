import UIKit

final class ProductoTableViewCell: UITableViewCell {

    /// Tiene que coincidir con el `Identifier` de la celda prototipo en
    /// Main.storyboard. Si no coinciden, `dequeueReusableCell` crashea.
    static let reuseIdentifier = "ProductoCell"

    @IBOutlet weak var imagenView: UIImageView!
    @IBOutlet weak var nombreLabel: UILabel!
    @IBOutlet weak var categoriaChipView: UIView!
    @IBOutlet weak var categoriaLabel: UILabel!
    @IBOutlet weak var pendienteChipView: UIView!
    @IBOutlet weak var pendienteLabel: UILabel!
    @IBOutlet weak var precioLabel: UILabel!
    @IBOutlet weak var stockLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = Theme.Color.surfaceContainerLowest

        [categoriaChipView, pendienteChipView].forEach { chip in
            chip?.layer.cornerRadius = Theme.Radius.base
            chip?.layer.cornerCurve = .continuous
        }
        categoriaChipView.backgroundColor = Theme.Color.surfaceTonal
        pendienteChipView.backgroundColor = Theme.Color.industrialOrange.withAlphaComponent(0.12)

        imagenView.layer.cornerRadius = Theme.Radius.base
        imagenView.layer.cornerCurve = .continuous
        imagenView.backgroundColor = Theme.Color.surfaceTonal
        imagenView.tintColor = Theme.Color.outline

        let fondoSeleccion = UIView()
        fondoSeleccion.backgroundColor = Theme.Color.surfaceTonal
        selectedBackgroundView = fondoSeleccion
    }

    /// Si la celda se reuso mientras la descarga estaba en vuelo, esa imagen ya
    /// no corresponde a este producto. Mismo criterio que la galeria del detalle.
    private var urlActual: String?

    override func prepareForReuse() {
        super.prepareForReuse()
        urlActual = nil
        mostrarPlaceholder()
    }

    func configurar(con producto: ProductoEntity) {
        configurarImagen(de: producto)

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

        // Cambio local que todavia no llego al servidor.
        pendienteChipView.isHidden = (producto.estadoSync == 1)
        pendienteLabel.aplicar(
            .labelMD,
            color: Theme.Color.industrialOrange,
            texto: "PENDIENTE",
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

    /// La foto principal es la de menor `orden`, el mismo criterio con el que la
    /// galeria del detalle las ordena. Un producto sin fotos muestra el
    /// placeholder, no un hueco: la fila tiene que medir lo mismo en los dos casos.
    private func configurarImagen(de producto: ProductoEntity) {
        let imagenes = (producto.imagenes as? Set<ProductoImagenEntity>) ?? []
        let principal = imagenes.sorted { $0.orden < $1.orden }.first

        guard let urlTexto = principal?.url, !urlTexto.isEmpty else {
            urlActual = nil
            mostrarPlaceholder()
            return
        }

        urlActual = urlTexto

        if let cacheada = DescargadorDeImagenes.shared.imagenCacheada(urlTexto) {
            mostrarFoto(cacheada)
            return
        }

        mostrarPlaceholder()
        DescargadorDeImagenes.shared.descargar(urlTexto) { [weak self] imagen in
            guard let self, self.urlActual == urlTexto, let imagen else { return }
            self.mostrarFoto(imagen)
        }
    }

    private func mostrarFoto(_ imagen: UIImage) {
        imagenView.contentMode = .scaleAspectFill
        imagenView.image = imagen
    }

    private func mostrarPlaceholder() {
        // `scaleAspectFit` y no `scaleAspectFill`: el simbolo tiene que verse
        // entero y centrado, no recortado como si fuera una foto.
        imagenView.contentMode = .scaleAspectFit
        imagenView.image = UIImage(systemName: "shippingbox")
    }
}
