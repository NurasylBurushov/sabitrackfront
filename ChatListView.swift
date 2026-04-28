import SwiftUI

struct ChatListView: View {
    @State private var chats: [ChatRoom] = []
    @State private var searchText = ""
    
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
                                NavigationLink(destination: ChatDetailView(chatId: chat.id, chatName: chat.name)) {
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
        }
    }
    
    var filteredChats: [ChatRoom] {
        if searchText.isEmpty { return chats }
        return chats.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    func loadChats() {
        chats = [
            ChatRoom(id: "1", name: "Айгуль Нурланова", lastMessage: "Малыш покушал и уснул 😊", lastMessageTime: "14:32", unreadCount: 2),
            ChatRoom(id: "2", name: "Мария Иванова", lastMessage: "Приду к 9:00 утра", lastMessageTime: "Вчера", unreadCount: 0),
            ChatRoom(id: "3", name: "Светлана Ким", lastMessage: "Спасибо за доверие!", lastMessageTime: "Пн", unreadCount: 0),
            ChatRoom(id: "4", name: "Динара Омарова", lastMessage: "Можно перенести на среду?", lastMessageTime: "Пн", unreadCount: 1),
            ChatRoom(id: "5", name: "Поддержка Sabi Track", lastMessage: "Ваш вопрос решён", lastMessageTime: "25 апр", unreadCount: 0),
        ]
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
