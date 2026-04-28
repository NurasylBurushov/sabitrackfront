import SwiftUI
import GoogleSignIn
@main
struct SabiTrackApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var authVM = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authVM.isAuthenticated {
                    MainTabView()
                } else {
                    AuthFlowView()
                }
            }
            .environmentObject(authVM)
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
