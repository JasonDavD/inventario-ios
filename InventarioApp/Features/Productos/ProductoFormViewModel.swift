import Foundation

final class ProductoFormViewModel {

    private let service = ProductoService()

    private(set) var producto: ProductoEntity?
    var categoriaSeleccionada: CategoriaEntity?
    var proveedorSeleccionado: ProveedorEntity?

    var esEdicion: Bool { producto != nil }
    var titulo: String { esEdicion ? "Editar producto" : "Nuevo producto" }

    /// Un producto sin `apiId` todavia no existe en el servidor. Se avisa en la
    /// pantalla porque explica por que Fase 5 no va a dejar subirle fotos.
    var estaPendienteDeSincronizar: Bool {
        guard let producto else { return false }
        return producto.estadoSync == 0 || producto.apiId == nil
    }

    init(producto: ProductoEntity?) {
        self.producto = producto
        categoriaSeleccionada = producto?.categoria
        proveedorSeleccionado = producto?.proveedor
    }

    // MARK: - Datos para los selectores

    func categorias() -> [CategoriaEntity] { CategoriaService().todas() }
    func proveedores() -> [ProveedorEntity] { ProveedorService().todos() }

    // MARK: - Guardado

    /// Devuelve el mensaje de error, o `nil` si guardo bien.
    func guardar(nombre: String, precioTexto: String, stockTexto: String) -> String? {
        let nombreLimpio = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nombreLimpio.isEmpty else {
            return "El nombre no puede estar vacio"
        }

        guard let precio = Self.parsearDecimal(precioTexto), precio >= 0 else {
            return "El precio tiene que ser un numero mayor o igual a cero"
        }

        guard let stock = Int32(stockTexto.trimmingCharacters(in: .whitespaces)), stock >= 0 else {
            return "El stock tiene que ser un numero entero mayor o igual a cero"
        }

        let esAlta = producto == nil

        if let producto {
            service.actualizar(
                producto,
                nombre: nombreLimpio,
                precio: precio,
                stock: stock,
                categoria: categoriaSeleccionada,
                proveedor: proveedorSeleccionado
            )
        } else {
            producto = service.crear(
                nombre: nombreLimpio,
                precio: precio,
                stock: stock,
                categoria: categoriaSeleccionada,
                proveedor: proveedorSeleccionado
            )
        }

        // Se registra despues de guardar y no antes: la bitacora deja constancia
        // de lo que efectivamente paso.
        BitacoraService.shared.registrar(esAlta ? .creo : .edito, sobre: .producto, nombre: nombreLimpio)
        return nil
    }

    /// El teclado decimal del telefono usa coma o punto segun la region, asi que
    /// se aceptan las dos: escribir "10,55" no puede fallar la validacion.
    private static func parsearDecimal(_ texto: String) -> Double? {
        let normalizado = texto
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        return Double(normalizado)
    }
}
