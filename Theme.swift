import SwiftUI
import UIKit

extension Color {
    static let peachPrimary = Color(red: 1.0, green: 0.55, blue: 0.40)
    static let peachLight = Color(red: 1.0, green: 0.78, blue: 0.69)
    static let peachDark = Color(red: 0.93, green: 0.38, blue: 0.25)
    static let peachBg = Color(red: 1.0, green: 0.96, blue: 0.94)
    static let peachSurface = Color(red: 1.0, green: 0.98, blue: 0.96)
    static let textPrimary = Color(red: 0.13, green: 0.13, blue: 0.13)
    static let textSecondary = Color(red: 0.45, green: 0.45, blue: 0.45)
    static let textMuted = Color(red: 0.70, green: 0.70, blue: 0.70)
}

/// SF Symbol может отсутствовать на старых версиях iOS — подставляем запасной.
enum SFSymbol {
    static func available(_ primary: String, fallback: String) -> String {
        UIImage(systemName: primary) != nil ? primary : fallback
    }
}

extension View {
    func peachButton(_ isLoading: Bool = false) -> some View {
        self
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [.peachPrimary, .peachDark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold))
            .cornerRadius(16)
            .shadow(color: .peachPrimary.opacity(0.35), radius: 12, y: 6)
            .overlay {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .disabled(isLoading)
    }
    
    func peachTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Color.peachSurface)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.peachLight, lineWidth: 1.5)
            )
            .font(.system(size: 15))
            .foregroundColor(.textPrimary)
    }
    
    func peachSecureField(_ placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Color.peachSurface)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.peachLight, lineWidth: 1.5)
            )
            .font(.system(size: 15))
            .foregroundColor(.textPrimary)
    }
}
