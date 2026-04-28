import SwiftUI

struct RoleSelectionView: View {
    @AppStorage("userRole") private var userRole: String = ""
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color.peachBg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Логотип
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.peachPrimary, .peachDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 100, height: 100)
                            .shadow(color: .peachPrimary.opacity(0.3), radius: 20, y: 8)
                        Image(systemName: "figure.and.child")
                            .font(.system(size: 42, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Text("Добро пожаловать!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.textPrimary)
                    
                    Text("Выберите, с какой стороны вы\nбудете использовать приложение")
                        .font(.system(size: 15))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding(.bottom, 50)
                
                // Кнопки выбора роли
                VStack(spacing: 20) {
                    // РОДИТЕЛЬ
                    Button {
                        userRole = "parent"
                        onComplete()
                    } label: {
                        HStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.peachLight)
                                    .frame(width: 70, height: 70)
                                Image(systemName: "figure.and.child")
                                    .font(.system(size: 30))
                                    .foregroundColor(.peachDark)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Я родитель")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.textPrimary)
                                Text("Ищу няню, домработницу\nили сиделку для ребенка")
                                    .font(.system(size: 13))
                                    .foregroundColor(.textSecondary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.peachPrimary)
                        }
                        .padding(20)
                        .background(Color.peachSurface)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.peachLight, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // НЯНЯ
                    Button {
                        userRole = "nanny"
                        onComplete()
                    } label: {
                        HStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.peachLight)
                                    .frame(width: 70, height: 70)
                                Image(systemName: "figure.dress.line.vertical.figure")
                                    .font(.system(size: 30))
                                    .foregroundColor(.peachDark)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Я няня / Специалист")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.textPrimary)
                                Text("Ищу работу, предлагаю\nуслуги по уходу за детьми")
                                    .font(.system(size: 13))
                                    .foregroundColor(.textSecondary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.peachPrimary)
                        }
                        .padding(20)
                        .background(Color.peachSurface)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.peachLight, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 24)
                
                Spacer()
                Spacer()
            }
        }
    }
}
