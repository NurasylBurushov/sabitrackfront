import SwiftUI
import AuthenticationServices

struct AuthFlowView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showPhoneAuth = false
    @State private var showSignUp = false
    
    var body: some View {
        ZStack {
            if let uiImage = UIImage(named: "bg_login") {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                Color.peachBg.ignoresSafeArea()
            }
            
            VStack {
                LinearGradient(colors: [.black.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 200)
                    .ignoresSafeArea()
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 250)
                    .ignoresSafeArea()
            }
            .allowsHitTesting(false)
            
            if authVM.currentFlow == .signIn && !showPhoneAuth && !showSignUp {
                SignInView(showPhoneAuth: $showPhoneAuth, showSignUp: $showSignUp)
            } else if showPhoneAuth {
                PhoneAuthView()
            } else if showSignUp {
                SignUpView()
            }
        }
        .alert("Ошибка", isPresented: $authVM.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(authVM.error ?? "Произошла ошибка")
        }
    }
}

struct SignInView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Binding var showPhoneAuth: Bool
    @Binding var showSignUp: Bool
    @State private var showPassword = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 90, height: 90)
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 38, weight: .medium))
                            .foregroundColor(.white)
                    }
                    Text("Sabi Track")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("Безопасное отслеживание няни")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.top, 80)
                .padding(.bottom, 40)
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Логин или Email")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 4)
                        GlassTextField(placeholder: "Введите логин", text: $authVM.loginEmail)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Пароль")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 4)
                        ZStack(alignment: .trailing) {
                            if showPassword {
                                GlassTextField(placeholder: "Введите пароль", text: $authVM.loginPassword, isSecure: false)
                            } else {
                                GlassSecureField(placeholder: "Введите пароль", text: $authVM.loginPassword)
                            }
                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.trailing, 16)
                            }
                        }
                    }
                    
                    HStack {
                        Spacer()
                        Button {} label: {
                            Text("Забыли пароль?")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Button {
                        Task { await authVM.loginWithEmail() }
                    } label: {
                        Text("Войти")
                    }
                    .peachButton(authVM.isLoading)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 28)
                
                HStack(spacing: 16) {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.white.opacity(0.4))
                    Text("или")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 28)
                .padding(.top, 28)
                
                VStack(spacing: 12) {
                    Button {
                        authVM.loginWithGoogle()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            Text("Продолжить с Google")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 54)
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                    }
                    
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        authVM.handleAppleSignIn(result: result)
                    }
                    .frame(height: 54)
                    .cornerRadius(14)
                    
                    Button {
                        withAnimation { showPhoneAuth = true }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            Text("Войти по номеру телефона")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 54)
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 4)
                
                HStack(spacing: 4) {
                    Text("Нет аккаунта?")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                    Button {
                        withAnimation { showSignUp = true }
                    } label: {
                        Text("Создайте свой аккаунт")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 32)
                .padding(.bottom, 40)
            }
        }
        .scrollIndicators(.hidden)
    }
}

struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Button {
                        withAnimation { authVM.currentFlow = .signIn }
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)
                    
                    Text("Создайте свой аккаунт")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 28)
                    
                    Text("Заполните данные для регистрации")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 28)
                }
                .padding(.top, 20)
                .padding(.bottom, 32)
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ваше имя")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        GlassTextField(placeholder: "Введите имя", text: $authVM.signUpName)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Электронная почта")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        GlassTextField(placeholder: "example@email.com", text: $authVM.signUpEmail)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Пароль")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        ZStack(alignment: .trailing) {
                            if showPassword {
                                GlassTextField(placeholder: "Минимум 6 символов", text: $authVM.signUpPassword, isSecure: false)
                            } else {
                                GlassSecureField(placeholder: "Минимум 6 символов", text: $authVM.signUpPassword)
                            }
                            Button { showPassword.toggle() } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.trailing, 16)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Подтвердите пароль")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        ZStack(alignment: .trailing) {
                            if showConfirmPassword {
                                GlassTextField(placeholder: "Повторите пароль", text: $authVM.signUpConfirmPassword, isSecure: false)
                            } else {
                                GlassSecureField(placeholder: "Повторите пароль", text: $authVM.signUpConfirmPassword)
                            }
                            Button { showConfirmPassword.toggle() } label: {
                                Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.trailing, 16)
                            }
                        }
                    }
                    
                    Button {
                        Task { await authVM.registerWithEmail() }
                    } label: {
                        Text("Продолжить")
                    }
                    .peachButton(authVM.isLoading)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 28)
                
                HStack(spacing: 16) {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.white.opacity(0.4))
                    Text("или")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 28)
                .padding(.top, 28)
                
                VStack(spacing: 12) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        authVM.handleAppleSignIn(result: result)
                    }
                    .frame(height: 54)
                    .cornerRadius(14)
                    
                    Button {
                        authVM.loginWithGoogle()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            Text("Продолжить с Google")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 54)
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 28)
                
                HStack(spacing: 4) {
                    Text("Уже есть аккаунт?")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                    Button {
                        withAnimation { authVM.currentFlow = .signIn }
                    } label: {
                        Text("Войти")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 32)
                .padding(.bottom, 40)
            }
        }
        .scrollIndicators(.hidden)
    }
}

struct PhoneAuthView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Button {
                    withAnimation {
                        authVM.smsSent = false
                        authVM.smsCode = ""
                        authVM.timer?.invalidate()
                    }
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 20)
                
                if !authVM.smsSent {
                    phoneInputSection
                } else {
                    smsVerificationSection
                }
                
                Spacer(minLength: 40)
            }
        }
        .scrollIndicators(.hidden)
    }
    
    var phoneInputSection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .padding(.top, 40)
                Text("Вход по номеру телефона")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text("Мы отправим SMS с кодом подтверждения на ваш номер")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Номер телефона")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                HStack {
                    Text("+7")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.leading, 16)
                    
                    TextField("(___) ___-__-__", text: $authVM.phoneNumber)
                        .font(.system(size: 15))
                        .keyboardType(.phonePad)
                        .foregroundColor(.white)
                        .padding(.trailing, 16)
                }
                .frame(height: 54)
                .background(.ultraThinMaterial)
                .cornerRadius(14)
            }
            .padding(.horizontal, 28)
            
            Button {
                Task { await authVM.sendSMS() }
            } label: {
                Text("Отправить код")
            }
            .peachButton(authVM.isLoading)
            .padding(.horizontal, 28)
        }
    }
    
    var smsVerificationSection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "message.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .padding(.top, 40)
                Text("Введите код из SMS")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text("Код отправлен на номер +7 \(authVM.phoneNumber)")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            
            SMSCodeInput(code: $authVM.smsCode)
                .padding(.horizontal, 28)
            
            Button {
                Task { await authVM.verifySMS() }
            } label: {
                Text("Подтвердить")
            }
            .peachButton(authVM.isLoading)
            .padding(.horizontal, 28)
            .disabled(authVM.smsCode.count < 4)
            .opacity(authVM.smsCode.count < 4 ? 0.5 : 1.0)
            
            if authVM.smsCountdown > 0 {
                Text("Повторная отправка через \(authVM.smsCountdown) сек")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            } else {
                Button {
                    Task { await authVM.sendSMS() }
                } label: {
                    Text("Отправить код повторно")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct SMSCodeInput: View {
    @Binding var code: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<4, id: \.self) { index in
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                        .frame(width: 64, height: 64)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    index < code.count ? Color.white : Color.white.opacity(0.3),
                                    lineWidth: index < code.count ? 2 : 1.5
                                )
                        )
                    
                    if index < code.count {
                        Text(String(code[code.index(code.startIndex, offsetBy: index)]))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    } else if index == code.count && isFocused {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2, height: 28)
                    }
                }
            }
        }
        .overlay {
            TextField("", text: $code)
                .textContentType(.oneTimeCode)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .opacity(0)
                .frame(width: 0, height: 0)
        }
        .onTapGesture {
            isFocused = true
        }
        .onChange(of: code) { newValue in
            if newValue.count > 4 {
                code = String(newValue.prefix(4))
            }
        }
    }
}

struct GlassTextField: View {
    let placeholder: String
    let text: Binding<String>
    var isSecure: Bool = true
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .font(.system(size: 15))
        .foregroundColor(.white)
    }
}

struct GlassSecureField: View {
    let placeholder: String
    let text: Binding<String>
    
    var body: some View {
        SecureField(placeholder, text: text)
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(.ultraThinMaterial)
            .cornerRadius(14)
            .font(.system(size: 15))
            .foregroundColor(.white)
    }
}
