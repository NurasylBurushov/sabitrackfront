import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showNannySelection = false // Переменная для открытия выбора няни
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Шапка
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Здравствуйте,")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                        Text(authVM.user?.name ?? "Пользователь")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.textPrimary)
                    }
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(colors: [.peachLight, .peachPrimary.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                            )
                            .frame(width: 48, height: 48)
                        Text(String((authVM.user?.name ?? "U").prefix(1)))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.peachDark)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                // Быстрые действия
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    // ✅ ИЗМЕНЕНИЕ: Теперь эта кнопка открывает выбор няни
                    QuickActionCard(icon: "magnifyingglass", title: "Найти няню", color: .peachPrimary)
                        .onTapGesture {
                            showNannySelection = true
                        }
                    
                    QuickActionCard(icon: "map.fill", title: "Отслеживание", color: Color(red: 0.3, green: 0.7, blue: 0.5))
                    QuickActionCard(icon: "message.fill", title: "Чат", color: Color(red: 0.4, green: 0.5, blue: 0.9))
                    QuickActionCard(icon: "bag.fill", title: "Маркет", color: Color(red: 0.9, green: 0.6, blue: 0.2))
                }
                .padding(.horizontal, 20)
                
                // Активная няня
                if authVM.isAuthenticated {
                    ActiveNannyCard()
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                }
                
                // Последние чаты
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Последние чаты")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Button("Все") {}
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.peachPrimary)
                    }
                    
                    RecentChatRow(name: "Айгуль Нурланова", message: "Малыш покушал и уснул 😊", time: "14:32", unread: 2)
                    RecentChatRow(name: "Мария Иванова", message: "Приду к 9:00 утра", time: "Вчера", unread: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                
                // Популярные товары
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Популярное в маркете")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Button("Все") {}
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.peachPrimary)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            MarketMiniCard(title: "Pampers Premium", price: 4500, category: "Подгузники")
                            MarketMiniCard(title: "Huggies Ultra", price: 3800, category: "Подгузники")
                            MarketMiniCard(title: "Детский крем", price: 1200, category: "Уход")
                            MarketMiniCard(title: "Соска Avent", price: 2800, category: "Аксессуары")
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 30)
            }
        }
        // ✅ ИЗМЕНЕНИЕ: Вызов экрана выбора няни поверх главного экрана
        .fullScreenCover(isPresented: $showNannySelection) {
            SideSelectionView(onComplete: {
                showNannySelection = false
            })
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(color)
            }
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.peachSurface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.peachLight, lineWidth: 1.5)
        )
    }
}

struct ActiveNannyCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: SFSymbol.available("shield.checkered", fallback: "shield.fill"))
                    .font(.system(size: 16))
                    .foregroundColor(.peachPrimary)
                Text("Активное отслеживание")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Spacer()
                
                Text("В сети")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(20)
            }
            
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.peachLight)
                        .frame(width: 44, height: 44)
                    Text("А")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.peachDark)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Айгуль Нурланова")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text("Алматы, Бостандыкский р-н • Обновлено 2 мин назад")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Button {
                    // Открыть карту
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 13))
                        Text("Карта")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(colors: [.peachPrimary, .peachDark], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(Color.peachSurface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.peachLight, lineWidth: 1.5)
        )
    }
}

struct RecentChatRow: View {
    let name: String
    let message: String
    let time: String
    let unread: Int
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.peachLight)
                    .frame(width: 48, height: 48)
                Text(String(name.prefix(1)))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.peachDark)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(time)
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
                
                if unread > 0 {
                    Text("\(unread)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Color.peachPrimary)
                        .clipShape(Circle())
                }
            }
        }
        .padding(12)
        .background(Color.peachSurface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.peachLight, lineWidth: 1)
        )
    }
}

struct MarketMiniCard: View {
    let title: String
    let price: Int
    let category: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.peachLight)
                    .frame(height: 100)
                Image(systemName: "bag.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.peachPrimary.opacity(0.5))
            }
            
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textPrimary)
                .lineLimit(1)
            
            HStack {
                Text("\(price) ₸")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.peachPrimary)
                Spacer()
                Text(category)
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.peachLight)
                    .cornerRadius(8)
            }
        }
        .frame(width: 150)
        .padding(10)
        .background(Color.peachSurface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.peachLight, lineWidth: 1)
        )
    }
}
