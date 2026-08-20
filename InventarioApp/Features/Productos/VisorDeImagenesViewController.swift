import UIKit

/// Visor de fotos a pantalla completa: se abre al tocar una foto de la galeria,
/// deja pasar de una a otra deslizando y hacerle zoom con doble tap o pellizco.
///
/// Se presenta modal y se arma por codigo, sin escena en el Storyboard: no tiene
/// relaciones de navegacion que expresar y sus celdas son del tamaño de la
/// pantalla, que solo se conoce en runtime.
///
/// **Es la unica pantalla que no sigue la paleta del DESIGN.md**, y es a
/// proposito: un visor de fotos necesita un fondo oscuro para que la vista no
/// compita con la imagen. Se usa `charcoal-deep`, que es el color mas oscuro del
/// sistema, en vez de un negro puro de fuera de la paleta.
final class VisorDeImagenesViewController: UIViewController {

    /// Le avisa al detalle que hay que borrar la foto de esa posicion. El visor
    /// no borra por su cuenta: la logica y el estado viven en el ViewModel del
    /// detalle, aca solo se pide.
    var alPedirBorrar: ((Int) -> Void)?

    private let urls: [String]
    private let puedeBorrar: Bool
    private var indiceActual: Int

    private var collectionView: UICollectionView!
    private let contadorLabel = UILabel()
    private let cerrarButton = UIButton(type: .system)
    private let eliminarButton = UIButton(type: .system)

    init(urls: [String], indiceInicial: Int, puedeBorrar: Bool) {
        self.urls = urls
        self.indiceActual = indiceInicial
        self.puedeBorrar = puedeBorrar
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) no se usa: este visor se crea por codigo")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Color.charcoalDeep
        armarColeccion()
        armarBarra()
        actualizarContador()
    }

    /// La celda ocupa toda la pantalla, asi que su tamaño depende del `bounds`
    /// final. Se recalcula aca y no en `viewDidLoad`, donde todavia no es el
    /// definitivo.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout,
              layout.itemSize != view.bounds.size else { return }

        layout.itemSize = view.bounds.size
        layout.invalidateLayout()
        collectionView.setContentOffset(
            CGPoint(x: CGFloat(indiceActual) * view.bounds.width, y: 0),
            animated: false
        )
    }

    // MARK: - Armado

    private func armarColeccion() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            VisorImagenCollectionViewCell.self,
            forCellWithReuseIdentifier: VisorImagenCollectionViewCell.reuseIdentifier
        )
        // El contenido va pegado a los bordes: el visor es la foto, no un
        // documento con margenes.
        collectionView.contentInsetAdjustmentBehavior = .never
        view.addSubview(collectionView)
    }

    private func armarBarra() {
        cerrarButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        cerrarButton.tintColor = Theme.Color.onPrimary
        cerrarButton.addTarget(self, action: #selector(cerrarTapped), for: .touchUpInside)

        eliminarButton.setImage(UIImage(systemName: "trash"), for: .normal)
        eliminarButton.tintColor = Theme.Color.onPrimary
        eliminarButton.addTarget(self, action: #selector(eliminarTapped), for: .touchUpInside)
        eliminarButton.isHidden = !puedeBorrar

        contadorLabel.textAlignment = .center

        let barra = UIStackView(arrangedSubviews: [cerrarButton, contadorLabel, eliminarButton])
        barra.axis = .horizontal
        barra.alignment = .center
        barra.distribution = .fill
        barra.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(barra)

        // Los botones a los costados con su tamaño natural, y el contador
        // ocupando el resto para quedar centrado de verdad.
        cerrarButton.setContentHuggingPriority(.required, for: .horizontal)
        eliminarButton.setContentHuggingPriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            barra.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: Theme.Spacing.marginMobile
            ),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(
                equalTo: barra.trailingAnchor,
                constant: Theme.Spacing.marginMobile
            ),
            barra.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Theme.Spacing.xs),
            cerrarButton.widthAnchor.constraint(equalToConstant: 44),
            cerrarButton.heightAnchor.constraint(equalToConstant: 44),
            eliminarButton.widthAnchor.constraint(equalToConstant: 44),
            eliminarButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func actualizarContador() {
        // Solo tiene sentido si hay mas de una: con una sola foto el "1 de 1"
        // es ruido.
        guard urls.count > 1 else {
            contadorLabel.attributedText = nil
            return
        }
        contadorLabel.aplicar(
            .labelLG,
            color: Theme.Color.onPrimary,
            texto: "\(indiceActual + 1) de \(urls.count)",
            alineacion: .center
        )
    }

    // MARK: - Acciones

    @objc private func cerrarTapped() {
        dismiss(animated: true)
    }

    @objc private func eliminarTapped() {
        let alert = UIAlertController(
            title: "Eliminar foto",
            message: "Se borra del servidor ahora mismo. Esta accion no se puede deshacer.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { [weak self] _ in
            guard let self else { return }
            let indice = self.indiceActual
            // Se cierra primero y despues se avisa: el borrado y su spinner
            // viven en el detalle, y dejar el visor abierto mostrando una foto
            // que se esta borrando confunde.
            self.dismiss(animated: true) {
                self.alPedirBorrar?(indice)
            }
        })
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension VisorDeImagenesViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        urls.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let celda = collectionView.dequeueReusableCell(
            withReuseIdentifier: VisorImagenCollectionViewCell.reuseIdentifier,
            for: indexPath
        )
        guard let celdaVisor = celda as? VisorImagenCollectionViewCell else { return celda }
        celdaVisor.configurar(urlTexto: urls[indexPath.item])
        return celdaVisor
    }
}

// MARK: - UIScrollViewDelegate

extension VisorDeImagenesViewController: UICollectionViewDelegate {

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard view.bounds.width > 0 else { return }
        indiceActual = Int(round(scrollView.contentOffset.x / view.bounds.width))
        actualizarContador()
    }
}
