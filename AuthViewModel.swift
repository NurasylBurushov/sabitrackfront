import Foundation
import SwiftUI
import AuthenticationServices
import CryptoKit
import GoogleSignIn

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: UserProfile?
    @Published var isLoading = false
    @Published var error: String?
    @Published var showError = false
    
    @Published var loginEmail = ""
    @Published var loginPassword = ""
    
    @Published var signUpName = ""
    @Published var signUpEmail = ""
    @Published var signUpPassword = ""
    @Published var signUpConfirmPassword = ""
    
    @Published var phoneNumber = ""
    @Published var smsCode = ""
    @Published var smsSent = false
    @Published var smsCountdown: Int = 60
    @Published var timer: Timer?
    
    @Published var currentFlow: AuthFlow = .signIn
    @Published var authMethod: AuthMethod = .email
    
    enum AuthFlow { case signIn, signUp }
    enum AuthMethod { case email, phone, google, apple }
    
    init() {
        let token = UserDefaults.standard.string(forKey: "auth_token")
        if token != nil {
            isAuthenticated = true
            Task { await loadProfile() }
        }
    }
    
    // MARK: - Email
    func loginWithEmail() async {
        await MainActor.run { isLoading = true; error = nil }
        do {
            let response = try await NetworkService.shared.loginWithEmail(
                email: loginEmail, password: loginPassword)
            await saveAuth(response)
        } catch {
            await handleNetworkError(error, prefix: "Ошибка входа")
        }
        await MainActor.run { isLoading = false }
    }
    
    // MARK: - Регистрация
    func registerWithEmail() async {
        guard signUpPassword == signUpConfirmPassword else {
            await MainActor.run { error = "Пароли не совпадают"; showError = true }
            return
        }
        guard signUpPassword.count >= 6 else {
            await MainActor.run { error = "Пароль минимум 6 символов"; showError = true }
            return
        }
        await MainActor.run { isLoading = true; error = nil }
        do {
            let response = try await NetworkService.shared.registerWithEmail(
                name: signUpName, email: signUpEmail, password: signUpPassword)
            await saveAuth(response)
        } catch {
            await handleNetworkError(error, prefix: "Ошибка регистрации")
        }
        await MainActor.run { isLoading = false }
    }
    
    // MARK: - SMS
    func sendSMS() async {
        guard phoneNumber.count >= 10 else {
            await MainActor.run { error = "Введите корректный номер"; showError = true }
            return
        }
        await MainActor.run { isLoading = true; error = nil }
        let cleanPhone = phoneNumber.filter { $0.isNumber }
        let finalPhone = cleanPhone.hasPrefix("7") ? "+\(cleanPhone)" : "+7\(cleanPhone)"
        do {
            _ = try await NetworkService.shared.sendSMSCode(phone: finalPhone)
            await MainActor.run {
                self.smsSent = true
                self.smsCountdown = 60
                self.startCountdown()
            }
        } catch {
            await handleNetworkError(error, prefix: "Ошибка отправки SMS")
        }
        await MainActor.run { isLoading = false }
    }
    
    func verifySMS() async {
        guard smsCode.count >= 4 else {
            await MainActor.run { error = "Введите код"; showError = true }
            return
        }
        await MainActor.run { isLoading = true; error = nil }
        let cleanPhone = phoneNumber.filter { $0.isNumber }
        let finalPhone = cleanPhone.hasPrefix("7") ? "+\(cleanPhone)" : "+7\(cleanPhone)"
        do {
            let response = try await NetworkService.shared.verifySMS(
                phone: finalPhone, code: smsCode)
            await saveAuth(response)
        } catch {
            await handleNetworkError(error, prefix: "Неверный код")
        }
        await MainActor.run { isLoading = false }
    }
    
    // MARK: - Google
    func loginWithGoogle() {
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
            .first else { return }
        
        GIDSignIn.sharedInstance.signIn(
            with: GIDConfiguration(clientID: "981994412149-u6lbkibn07736l7g5etretlkhb23sgfj.apps.googleusercontent.com"),
            presenting: rootVC
        ) { [weak self] user, error in
            guard let self = self else { return }
            
            if let error = error {
                Task { @MainActor in
                    self.error = "Ошибка Google: \(error.localizedDescription)"
                    self.showError = true
                }
                return
            }
            
            guard let idToken = user?.authentication.idToken else {
                Task { @MainActor in
                    self.error = "Не удалось получить токен"
                    self.showError = true
                }
                return
            }
            
            Task {
                await MainActor.run { self.isLoading = true }
                do {
                    let response = try await NetworkService.shared.loginWithGoogle(token: idToken)
                    await self.saveAuth(response)
                } catch {
                    await self.handleNetworkError(error, prefix: "Ошибка Google")
                }
                await MainActor.run { self.isLoading = false }
            }
        }
    }    // MARK: - Apple
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = credential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8) else {
                Task { @MainActor in
                    self.error = "Не удалось получить токен Apple"
                    self.showError = true
                }
                return
            }
            Task {
                await MainActor.run { isLoading = true; error = nil }
                do {
                    let response = try await NetworkService.shared.loginWithApple(
                        identityToken: tokenString)
                    await saveAuth(response)
                } catch {
                    await handleNetworkError(error, prefix: "Ошибка входа через Apple")
                }
                await MainActor.run { isLoading = false }
            }
        case .failure(let error):
            Task { @MainActor in
                self.error = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    // MARK: - Профиль
    func loadProfile() async {
        do {
            let profile = try await NetworkService.shared.fetchProfile()
            await MainActor.run { self.user = profile }
        } catch {
            await MainActor.run {
                self.isAuthenticated = false
                UserDefaults.standard.removeObject(forKey: "auth_token")
            }
        }
    }
    
    // MARK: - Выход
    func logout() {
        Task { @MainActor in
            UserDefaults.standard.removeObject(forKey: "auth_token")
            self.user = nil
            self.isAuthenticated = false
            self.currentFlow = .signIn
            self.smsSent = false
            self.smsCode = ""
            self.timer?.invalidate()
        }
    }
    
    // MARK: - Helpers
    @MainActor
    private func saveAuth(_ response: AuthResponse) {
        UserDefaults.standard.set(response.token, forKey: "auth_token")
        self.user = response.user
        self.isAuthenticated = true
    }
    
    @MainActor
    private func handleNetworkError(_ error: Error, prefix: String) {
        let message = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
        self.error = "\(prefix): \(message)"
        self.showError = true
    }
    
    private func startCountdown() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            if self.smsCountdown > 0 {
                self.smsCountdown -= 1
            } else {
                t.invalidate()
            }
        }
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.map { byte in
            let hex = String(Int(byte), radix: 16)
            return hex.count == 1 ? "0" + hex : hex
        }.joined()
    }
}
