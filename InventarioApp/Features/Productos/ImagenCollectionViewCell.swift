import UIKit

final class ImagenCollectionViewCell: UICollectionViewCell {

    /// Tiene que coincidir con el `Identifier` de la celda prototipo en
    /// Main.storyboard.
    static let reuseIdentifier = "ImagenCell"

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    /// URL que esta celda esta mostrando. Se guarda para descartar descargas que
    /// llegan tarde: si la celda se reuso para otra foto mientras bajaba la
    /// anterior, pegar esa imagen mostraria la foto equivocada.
    private var urlActual: String?

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = Theme.Color.surfaceTonal
        layer.cornerRadius = Theme.Radius.base
        layer.cornerCurve = .continuous
        clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        activityIndicator.hidesWhenStopped = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        urlActual = nil
        imageView.image = nil
    }

    func configurar(urlTexto: String) {
        urlActual = urlTexto

        if let cacheada = DescargadorDeImagenes.shared.imagenCacheada(urlTexto) {
            imageView.image = cacheada
            activityIndicator.stopAnimating()
            return
        }

        imageView.image = nil
        activityIndicator.startAnimating()

        DescargadorDeImagenes.shared.descargar(urlTexto) { [weak self] imagen in
            guard let self, self.urlActual == urlTexto else { return }
            self.activityIndicator.stopAnimating()
            self.imageView.image = imagen
        }
    }
}
