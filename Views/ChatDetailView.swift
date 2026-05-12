import SwiftUI

struct ChatDetailView: View {
    let chatId: String
    let chatName: String
    @EnvironmentObject var authVM: AuthViewModel
    @State private var messages: [Message] = []
    @State private var newMessage = ""
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var isSending = false
    @Environment(\.dismiss) var dismiss
    
    // WebSocket
    @StateObject private var wsManager = WebSocketManager.shared
    
    var body: some View {
        ZStack {
            Color.peachBg.ignoresSafeArea()
            VStack(spacing: 0) {
                // Навбар с индикатором подключения
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.textPrimary)
                    }
                    
                    ZStack {
                        Circle()
                            .fill(Color.peachLight)
                            .frame(width: 38, height: 38)
                        Text(String(chatName.prefix(1)))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.peachDark)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(chatName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        HStack(spacing: 6) {
                            Circle()
                                .fill(wsManager.isConnected ? Color.green : Color.yellow)
                                .frame(width: 8, height: 8)
                            Text(wsManager.isConnected ? "В сети" : "Подключение...")
                                .font(.system(size: 12))
                                .foregroundColor(wsManager.isConnected ? .green : .yellow)
                        }
                    }
                    
                    Spacer()
                    
                    Button {} label: {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.peachPrimary)
                            .frame(width: 38, height: 38)
                            .background(Color.peachSurface)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 10)
                .background(Color.peachSurface)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                
                // Сообщения
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        if isLoading {
                            ProgressView()
                                .tint(.peachPrimary)
                                .padding(.top, 24)
                        } else if let loadError {
                            VStack(spacing: 12) {
                                Text(loadError)
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                                    .multilineTextAlignment(.center)
                                Button("Повторить") {
                                    Task { await loadMessages() }
                                }
                                .peachButton(false)
                                .frame(maxWidth: 200)
                            }
                            .padding(.top, 24)
                        } else if messages.isEmpty {
                            VStack {
                                Spacer()
                                Text("Нет сообщений")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                                Spacer()
                            }
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(messages) { msg in
                                    MessageBubble(
                                        message: msg,
                                        isMe: msg.senderId == (authVM.user?.id ?? "")
                                    )
                                    .id(msg.id)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Инпут
                HStack(spacing: 10) {
                    Button {} label: {
                        Image(systemName: "paperclip")
                            .font(.system(size: 20))
                            .foregroundColor(.textMuted)
                            .frame(width: 40, height: 40)
                    }
                    
                    HStack {
                        TextField("Сообщение...", text: $newMessage)
                            .font(.system(size: 15))
                            .disabled(isSending)
                            .onSubmit { Task { await sendMessage() } }
                        
                        if !newMessage.isEmpty {
                            if isSending {
                                ProgressView()
                                    .tint(.peachPrimary)
                                    .scaleEffect(0.8)
                            } else {
                                Button {
                                    Task { await sendMessage() }
                                } label: {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 34, height: 34)
                                        .background(
                                            LinearGradient(colors: [.peachPrimary, .peachDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        )
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .background(Color.peachSurface)
                    .cornerRadius(23)
                    .overlay(
                        RoundedRectangle(cornerRadius: 23)
                            .stroke(Color.peachLight, lineWidth: 1.5)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .background(Color.peachSurface)
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadMessages()
            wsManager.connect(chatId: chatId)
        }
        .onDisappear {
            wsManager.disconnect()
        }
        // Слушаем новые сообщения из WebSocket
        .onReceive(wsManager.$lastMessage) { newMsg in
            if let newMsg = newMsg, newMsg.chatId == chatId {
                if !messages.contains(where: { $0.id == newMsg.id }) {
                    messages.append(newMsg)
                }
            }
        }
        .onReceive(wsManager.$error) { errorMsg in
            if let errorMsg = errorMsg {
                loadError = errorMsg
            }
        }
    }
    
    @MainActor
    func loadMessages() async {
        guard authVM.isAuthenticated else {
            messages = []
            return
        }
        isLoading = true
        loadError = nil
        do {
            messages = try await NetworkService.shared.fetchMessages(chatId: chatId)
        } catch {
            loadError = "Не удалось загрузить сообщения.\n\(error.localizedDescription)"
        }
        isLoading = false
    }
    
    @MainActor
    func sendMessage() async {
        let text = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        newMessage = ""
        isSending = true
        
        do {
            // Отправляем через REST API
            let sent = try await NetworkService.shared.sendMessage(chatId: chatId, text: text)
            messages.append(sent)
            
            // Отправляем через WebSocket для других клиентов
            wsManager.sendMessage(text)
        } catch {
            loadError = "Не удалось отп��авить сообщение.\n\(error.localizedDescription)"
            newMessage = text // Возвращаем текст если ошибка
        }
        isSending = false
    }
}

struct MessageBubble: View {
    let message: Message
    let isMe: Bool
    
    var body: some View {
        HStack {
            if isMe { Spacer(minLength: 60) }
            
            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 15))
                    .foregroundColor(isMe ? .white : .textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if isMe {
                                LinearGradient(colors: [.peachPrimary, .peachDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                            } else {
                                Color.peachSurface
                            }
                        }
                    )
                    .cornerRadius(18)
                    .overlay(
                        Group {
                            if !isMe {
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.peachLight, lineWidth: 1)
                            }
                        }
                    )
                
                Text(formatTime(message.createdAt))
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
            }
            
            if !isMe { Spacer(minLength: 60) }
        }
    }
    
    func formatTime(_ dateStr: String) -> String {
        let display = DateFormatter()
        display.dateFormat = "HH:mm"
        
        if let date = parseISO(dateStr) {
            return display.string(from: date)
        }
        return dateStr
    }
    
    private func parseISO(_ str: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: str) { return d }
        
        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]
        return f2.date(from: str)
    }
}
