import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    // ✅ Принимаем управление вкладками от MainTabView
    @Binding var selectedTab: MainTabView.Tab
    
    @State private var showEditProfile = false
    @State private var showPaymentMethods = false
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            Color.peachBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle().fill(LinearGradient(colors: [.peachPrimary, .peachDark], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 90, height: 90).shadow(color: .peachPrimary.opacity(0.3), radius: 16, y: 6)
                            Text(String((authVM.user?.name ?? "U").prefix(1))).font(.system(size: 34, weight: .bold)).foregroundColor(.white)
                        }
                        Text(authVM.user?.name ?? "Пользователь").font(.system(size: 22, weight: .bold)).foregroundColor(.textPrimary)
                        HStack(spacing: 16) {
                            Label(authVM.user?.email ?? "—", systemImage: "envelope.fill").font(.system(size: 13)).foregroundColor(.textSecondary)
                            if let phone = authVM.user?.phone { Label(phone, systemImage: "phone.fill").font(.system(size: 13)).foregroundColor(.textSecondary) }
                        }
                        Button { showEditProfile = true } label: {
                            HStack(spacing: 6) { Image(systemName: "pencil").font(.system(size: 13)); Text("Редактировать").font(.system(size: 14, weight: .semibold)) }
                                .foregroundColor(.peachPrimary).padding(.horizontal, 20).padding(.vertical, 10).background(Color.peachLight.opacity(0.5)).cornerRadius(12)
                        }
                    }
                    .padding(.top, 24).padding(.bottom, 24)
                    
                    HStack(spacing: 0) { StatItem(value: "3", label: "Няни"); StatItem(value: "12", label: "Заказов"); StatItem(value: "4.8", label: "Рейтинг") }
                        .padding(.vertical, 20).background(Color.peachSurface).cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.peachLight, lineWidth: 1.5)).padding(.horizontal, 20)
                    
                    VStack(spacing: 8) {
                        ProfileMenuRow(icon: "creditcard.fill", title: "Способы оплаты", subtitle: "2 карты привязано", color: .peachPrimary) { showPaymentMethods = true }
                        ProfileMenuRow(icon: "gearshape.fill", title: "Настройки", subtitle: "Язык, тема, безопасная карта", color: .textSecondary) { showSettings = true }
                        ProfileMenuRow(icon: "bell.fill", title: "Уведомления", subtitle: "Push, SMS, Email", color: Color(red: 0.4, green: 0.5, blue: 0.9)) {}
                        ProfileMenuRow(icon: "shield.fill", title: "Безопасность", subtitle: "Пароль, 2FA, данные", color: Color(red: 0.6, green: 0.4, blue: 0.8)) {}
                        ProfileMenuRow(icon: "questionmark.circle.fill", title: "Помощь и поддержка", subtitle: "FAQ, обратная связь", color: .textMuted) {}
                    }
                    .padding(.horizontal, 20).padding(.top, 20)
                    
                    Button { authVM.logout() } label: {
                        HStack(spacing: 8) { Image(systemName: "arrow.right.square.fill").font(.system(size: 18)); Text("Выйти из аккаунта").font(.system(size: 16, weight: .semibold)) }
                            .foregroundColor(.red).frame(maxWidth: .infinity).frame(height: 54).background(Color.red.opacity(0.08)).cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.15), lineWidth: 1.5))
                    }
                    .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showPaymentMethods) { PaymentMethodsView() }
        .sheet(isPresented: $showEditProfile) { EditProfileView() }
        // ✅ Вызов экрана настроек
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(selectedTab: $selectedTab)
        }
    }
}

struct StatItem: View {
    let value: String; let label: String
    var body: some View {
        VStack(spacing: 4) { Text(value).font(.system(size: 22, weight: .bold)).foregroundColor(.peachPrimary); Text(label).font(.system(size: 13)).foregroundColor(.textSecondary) }
            .frame(maxWidth: .infinity)
    }
}

struct ProfileMenuRow: View {
    let icon: String; let title: String; let subtitle: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack { color.opacity(0.12).frame(width: 44, height: 44).cornerRadius(12); Image(systemName: icon).font(.system(size: 18, weight: .medium)).foregroundColor(color) }
                VStack(alignment: .leading, spacing: 2) { Text(title).font(.system(size: 15, weight: .medium)).foregroundColor(.textPrimary); Text(subtitle).font(.system(size: 12)).foregroundColor(.textMuted) }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 14, weight: .medium)).foregroundColor(.textMuted)
            }
            .padding(14).background(Color.peachSurface).cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.peachLight, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthViewModel
    @State private var name = ""; @State private var email = ""; @State private var phone = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.peachBg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle().fill(LinearGradient(colors: [.peachPrimary, .peachDark], startPoint: .top, endPoint: .bottom)).frame(width: 100, height: 100)
                            Text(String(name.isEmpty ? "U" : name.prefix(1))).font(.system(size: 38, weight: .bold)).foregroundColor(.white)
                            Circle().fill(Color.white).frame(width: 32, height: 32).overlay(Image(systemName: "camera.fill").font(.system(size: 14)).foregroundColor(.peachPrimary)).offset(x: 35, y: 30)
                        }
                        .padding(.top, 20)
                        VStack(alignment: .leading, spacing: 6) { Text("Имя").font(.system(size: 13, weight: .medium)).foregroundColor(.textSecondary); peachTextField("Ваше имя", text: $name) }
                        VStack(alignment: .leading, spacing: 6) { Text("Email").font(.system(size: 13, weight: .medium)).foregroundColor(.textSecondary); peachTextField("Email", text: $email).textInputAutocapitalization(.never).keyboardType(.emailAddress) }
                        VStack(alignment: .leading, spacing: 6) { Text("Телефон").font(.system(size: 13, weight: .medium)).foregroundColor(.textSecondary); peachTextField("Телефон", text: $phone).keyboardType(.phonePad) }
                        Button { authVM.user?.name = name; dismiss() } label: { Text("Сохранить") }.peachButton().padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Редактировать").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() }.foregroundColor(.peachPrimary) } }
            .onAppear { name = authVM.user?.name ?? ""; email = authVM.user?.email ?? ""; phone = authVM.user?.phone ?? "" }
        }
    }
}
