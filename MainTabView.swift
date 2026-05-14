import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @AppStorage("userRole") private var userRole: String = ""
    @State private var selectedTab: Tab = .home
    
    enum Tab: Int, CaseIterable {
        case home, chat, market, map, profile
    }
    
    var body: some View {
        ZStack {
            Color.peachBg.ignoresSafeArea()
            
            if authVM.needsProfileCompletion {
                CompleteProfileView()
            } else if userRole.isEmpty {
                // Если роль не выбрана (после регистрации) — показываем выбор
                RoleSelectionView {
                    // При выборе роли @AppStorage сам обновит UI и покажет вкладки
                }
            } else {
                // Роль выбрана — показываем главный экран
                VStack(spacing: 0) {
                    Group {
                        switch selectedTab {
                        case .home:
                            HomeView()
                        case .chat:
                            ChatListView()
                        case .market:
                            MarketView()
                        case .map:
                            SafeMapView()
                        case .profile:
                            // ✅ Передаем управление вкладками в профиль
                            ProfileView(selectedTab: $selectedTab)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    CustomTabBar(selected: $selectedTab)
                }
            }
        }
    }
}

struct CustomTabBar: View {
    @Binding var selected: MainTabView.Tab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTabView.Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selected = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selected == tab {
                                Circle()
                                    .fill(Color.peachPrimary)
                                    .frame(width: 44, height: 44)
                                    .shadow(color: .peachPrimary.opacity(0.3), radius: 8, y: 4)
                            }
                            
                            Image(systemName: tabIcon(tab))
                                .font(.system(size: 20, weight: selected == tab ? .semibold : .regular))
                                .foregroundColor(selected == tab ? .white : .textMuted)
                                .frame(width: 44, height: 44)
                        }
                        
                        Text(tabLabel(tab))
                            .font(.system(size: 10, weight: selected == tab ? .semibold : .regular))
                            .foregroundColor(selected == tab ? .peachPrimary : .textMuted)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            Color.peachSurface
                .shadow(color: .black.opacity(0.05), radius: 10, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    func tabIcon(_ tab: MainTabView.Tab) -> String {
        switch tab {
        case .home: return "house.fill"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .market: return SFSymbol.available("bag.fill", fallback: "cart.fill")
        case .map: return "map.fill"
        case .profile: return "person.fill"
        }
    }
    
    func tabLabel(_ tab: MainTabView.Tab) -> String {
        switch tab {
        case .home: return "Главная"
        case .chat: return "Чат"
        case .market: return "Маркет"
        case .map: return "Карта"
        case .profile: return "Профиль"
        }
    }
}
