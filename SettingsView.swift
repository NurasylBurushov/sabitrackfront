import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    // Управление вкладками для кнопки "Безопасная карта"
    @Binding var selectedTab: MainTabView.Tab
    
    // Настройки темы и языка
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("appLanguage") private var appLanguage = "Русский"
    
    let languages = ["Русский", "Қазақша", "English"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.peachBg.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        
                        // MARK: - Безопасная карта (Переносит на карту)
                        Button {
                            // 1. Переключаем нижнюю вкладку на Карту
                            selectedTab = .map
                            // 2. Закрываем настройки
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Color(red: 0.3, green: 0.7, blue: 0.5).opacity(0.12)
                                        .frame(width: 44, height: 44).cornerRadius(12)
                                    Image(systemName: "map.fill").font(.system(size: 18, weight: .medium)).foregroundColor(Color(red: 0.3, green: 0.7, blue: 0.5))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Безопасная карта").font(.system(size: 15, weight: .medium)).foregroundColor(.textPrimary)
                                    Text("Отслеживание няни в реальном времени").font(.system(size: 12)).foregroundColor(.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.left.square").font(.system(size: 20)).foregroundColor(.peachPrimary)
                            }
                            .padding(16).background(Color.peachSurface).cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.peachLight, lineWidth: 1))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // MARK: - Язык
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Язык приложения").font(.system(size: 14, weight: .semibold)).foregroundColor(.textPrimary)
                            Picker("", selection: $appLanguage) {
                                ForEach(languages, id: \.self) { lang in
                                    Text(lang).tag(lang)
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 54)
                            .background(Color.peachSurface)
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.peachLight, lineWidth: 1.5))
                        }
                        .padding(.top, 8)
                        
                        // MARK: - Тема (Светлая/Тёмная)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Оформление").font(.system(size: 14, weight: .semibold)).foregroundColor(.textPrimary)
                            
                            HStack(spacing: 0) {
                                // Светлая
                                Button {
                                    isDarkMode = false
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: "sun.max.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(!isDarkMode ? .peachPrimary : .textMuted)
                                        Text("Светлая")
                                            .font(.system(size: 13, weight: !isDarkMode ? .semibold : .regular))
                                            .foregroundColor(!isDarkMode ? .peachPrimary : .textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(!isDarkMode ? Color.peachLight.opacity(0.5) : Color.peachSurface)
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(!isDarkMode ? Color.peachPrimary : Color.peachLight, lineWidth: !isDarkMode ? 2 : 1.5)
                                    )
                                }
                                
                                // Тёмная
                                Button {
                                    isDarkMode = true
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: "moon.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(isDarkMode ? .peachPrimary : .textMuted)
                                        Text("Тёмная")
                                            .font(.system(size: 13, weight: isDarkMode ? .semibold : .regular))
                                            .foregroundColor(isDarkMode ? .peachPrimary : .textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(isDarkMode ? Color.peachLight.opacity(0.5) : Color.peachSurface)
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(isDarkMode ? Color.peachPrimary : Color.peachLight, lineWidth: isDarkMode ? 2 : 1.5)
                                    )
                                }
                            }
                        }
                        .padding(.top, 8)
                        
                        // MARK: - Уведомления
                        SettingsToggleRow(icon: "bell.fill", title: "Push-уведомления", subtitle: "Получать уведомления о чатах", isOn: .constant(true))
                        SettingsToggleRow(icon: "message.fill", title: "SMS-уведомления", subtitle: "Уведомления о статусе заказа", isOn: .constant(false))
                        
                        // MARK: - Другое
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Другое").font(.system(size: 14, weight: .semibold)).foregroundColor(.textPrimary)
                            
                            HStack {
                                Text("Версия приложения").font(.system(size: 15)).foregroundColor(.textPrimary)
                                Spacer()
                                Text("1.0.0").font(.system(size: 14)).foregroundColor(.textMuted)
                            }
                            .padding(16).background(Color.peachSurface).cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.peachLight, lineWidth: 1))
                            
                            Button {} label: {
                                HStack {
                                    Text("Очистить кэш").font(.system(size: 15)).foregroundColor(.textPrimary)
                                    Spacer()
                                    Image(systemName: "trash").font(.system(size: 16)).foregroundColor(.red)
                                }
                                .padding(16).background(Color.peachSurface).cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.peachLight, lineWidth: 1))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.top, 8)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            // ✅ КНОПКА ЗАКРЫТИЯ НАСТРОЕК
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                        .foregroundColor(.peachPrimary)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}

// Компонент переключателя для настроек
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Color.peachPrimary.opacity(0.12).frame(width: 44, height: 44).cornerRadius(12)
                Image(systemName: icon).font(.system(size: 18, weight: .medium)).foregroundColor(.peachPrimary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .medium)).foregroundColor(.textPrimary)
                Text(subtitle).font(.system(size: 12)).foregroundColor(.textMuted)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(Color.peachPrimary)
        }
        .padding(14).background(Color.peachSurface).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.peachLight, lineWidth: 1))
    }
}
