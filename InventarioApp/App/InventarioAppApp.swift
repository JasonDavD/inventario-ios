import SwiftUI

@main
struct InventarioAppApp: App {
    @StateObject private var session = SessionManager()

    var body: some Scene {
        WindowGroup {
            Group {
                if session.isAuthenticated {
                    // Placeholder temporal — Fase 2 lo reemplaza por ProductoListView.
                    Text("Sesion iniciada como \(session.username ?? "")")
                } else {
                    LoginView(session: session)
                }
            }
            .environmentObject(session)
        }
    }
}
