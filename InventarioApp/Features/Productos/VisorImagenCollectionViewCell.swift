import UIKit

/// Una foto del visor, dentro de un `UIScrollView` para poder hacerle zoom.
///
/// Se arma por codigo y no con un prototipo en el Storyboard: la celda es de
/// pantalla completa y su tamaño depende del `bounds` del visor, que se calcula
/// en runtime. Escribirla en XML significaria constraints que igual habria que
/// recalcular a mano.
final class VisorImagenCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifier = "VisorImagenCell"

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    /// Igual que en la celda de la galeria: si la celda se reuso mientras la
    /// descarga estaba en vuelo, esa imagen ya no corresponde.
    private var urlActual: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        armar()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        armar()
    }

    private func armar() {
        backgroundColor = .clear

        scrollView.frame = contentView.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 4
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        // Sin esto, el zoom de una foto compite con el paginado del visor y
        // arrastrar dentro de la foto cambia de pagina.
        scrollView.bouncesZoom = true
        contentView.addSubview(scrollView)

        imageView.frame = scrollView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)

        activityIndicator.color = Theme.Color.onPrimary
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = CGPoint(x: contentView.bounds.midX, y: contentView.bounds.midY)
        activityIndicator.autoresizingMask = [
            .flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin
        ]
        contentView.addSubview(activityIndicator)

        let dobleTap = UITapGestureRecognizer(target: self, action: #selector(dobleTapEnLaFoto(_:)))
        dobleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(dobleTap)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        scrollView.zoomScale = 1
        imageView.image = nil
        urlActual = nil
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

    /// Doble tap alterna entre ver la foto entera y acercarla. Es el gesto que
    /// la gente espera en un visor, y evita tener que pellizcar para algo tan
    /// comun.
    @objc private func dobleTapEnLaFoto(_ gesto: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            return
        }

        let punto = gesto.location(in: imageView)
        let lado = scrollView.bounds.size.width / 2
        let alto = scrollView.bounds.size.height / 2
        scrollView.zoom(
            to: CGRect(x: punto.x - lado / 2, y: punto.y - alto / 2, width: lado, height: alto),
            animated: true
        )
    }
}

// MARK: - UIScrollViewDelegate

extension VisorImagenCollectionViewCell: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
}
