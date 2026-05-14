import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var chats: [ChatRoom] = []
    @State private var searchText = ""
    @State private var loadError: String?
    @State private var showLoadError = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.peachBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Заголовок
                    HStack {
                        Text("Чаты")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.textPrimary)
                        Spacer()
                        
                        Button {
                            // Новый чат
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.peachPrimary)
                                .frame(width: 42, height: 42)
                                .background(Color.peachSurface)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    // Поиск
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.textMuted)
                        TextField("Поиск чатов...", text: $searchText)
                            .font(.system(size: 15))
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .background(Color.peachSurface)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.peachLight, lineWidth: 1.5)
                    )
                    .padding(.horizontal, 20)
                    
                    // Список чатов
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredChats) { chat in
                                NavigationLink(
                                    destination: ChatDetailView(chatId: chat.id, chatName: chat.name)
                                        .environmentObject(authVM)
                                ) {
                                    ChatRow(chat: chat)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear { loadChats() }
            .alert("Не удалось загрузить чаты", isPresented: $showLoadError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(loadError ?? "")
            }
        }
    }
    
    var filteredChats: [ChatRoom] {
        if searchText.isEmpty { return chats }
        return chats.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    func loadChats() {
        Task {
            do {
                let items = try await NetworkService.shared.fetchChats()
                let rooms = items.map { item in
                    ChatRoom(
                        id: item.id,
                        name: item.nanny.name,
                        avatar: item.nanny.avatarUrl,
                        lastMessage: item.lastMessage,
                        lastMessageTime: Self.shortDate(from: item.createdAt),
                        unreadCount: item.unreadCount
                    )
                }
                await MainActor.run {
                    chats = rooms
                    loadError = nil
                    showLoadError = false
                }
            } catch {
                await MainActor.run {
                    chats = []
                    loadError = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
                    showLoadError = true
                }
            }
        }
    }
    
    private static func shortDate(from iso: String) -> String {
        let parsers: [ISO8601DateFormatter.Options] = [
            [.withInternetDateTime, .withFractionalSeconds],
            [.withInternetDateTime],
            [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime],
        ]
        for opts in parsers {
            let f = ISO8601DateFormatter()
            f.formatOptions = opts
            if let d = f.date(from: iso) {
                let out = DateFormatter()
                out.locale = Locale(identifier: "ru_RU")
                if Calendar.current.isDateInToday(d) {
                    out.dateFormat = "HH:mm"
                } else if Calendar.current.isDateInYesterday(d) {
                    return "Вчера"
                } else {
                    out.dateFormat = "d MMM"
                }
                return out.string(from: d)
            }
        }
        return ""
    }
}

struct ChatRow: View {
    let chat: ChatRoom
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.peachLight, .peachPrimary.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 54, height: 54)
                Text(String(chat.name.prefix(1)))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.peachDark)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text(chat.lastMessageTime ?? "")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                }
                
                HStack {
                    Text(chat.lastMessage ?? "")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                    Spacer()
                    if chat.unreadCount > 0 {
                        Text("\(chat.unreadCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(Color.peachPrimary)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(14)
        .background(Color.peachSurface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.peachLight, lineWidth: 1)
        )
    }
}
