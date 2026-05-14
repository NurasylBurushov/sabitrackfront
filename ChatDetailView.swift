import SwiftUI
import Combine

struct ChatDetailView: View {
    let chatId: String
    let chatName: String
    @EnvironmentObject var authVM: AuthViewModel
    @ObservedObject private var ws = WebSocketManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var messages: [Message] = []
    @State private var newMessage = ""
    @State private var loadFailed = false
    
    private var myUserId: String { authVM.user?.id ?? "" }
    
    var body: some View {
        ZStack {
            Color.peachBg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Button { dismiss() } label: {
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
                                .fill(ws.isConnected ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)
                            Text(ws.isConnected ? "В сети" : "Подключение…")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 10)
                .background(Color.peachSurface)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 8) {
                            ForEach(messages) { msg in
                                MessageBubble(message: msg, isMe: msg.senderId == myUserId)
                                    .id(msg.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                HStack(spacing: 10) {
                    HStack {
                        TextField("Сообщение...", text: $newMessage)
                            .font(.system(size: 15))
                            .onSubmit { sendMessageTapped() }
                        
                        if !newMessage.isEmpty {
                            Button { sendMessageTapped() } label: {
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
        .onAppear {
            ws.connect(chatId: chatId)
            Task { await loadMessages() }
        }
        .onDisappear {
            ws.disconnect()
        }
        .onReceive(ws.$lastMessage) { msg in
            guard let msg else { return }
            if !messages.contains(where: { $0.id == msg.id }) {
                messages.append(msg)
            }
        }
        .alert("Не удалось загрузить сообщения", isPresented: $loadFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Проверьте интернет и повторите попытку.")
        }
    }
    
    private func loadMessages() async {
        do {
            let loaded = try await NetworkService.shared.fetchMessages(chatId: chatId)
            await MainActor.run { messages = loaded }
        } catch {
            await MainActor.run { loadFailed = true }
        }
    }
    
    private func sendMessageTapped() {
        let trimmed = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        newMessage = ""
        Task {
            do {
                let sent = try await NetworkService.shared.sendMessage(chatId: chatId, text: trimmed)
                await MainActor.run {
                    if !messages.contains(where: { $0.id == sent.id }) {
                        messages.append(sent)
                    }
                }
            } catch {
                await MainActor.run { newMessage = trimmed }
            }
        }
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
    
    private func formatTime(_ dateStr: String) -> String {
        let options: [ISO8601DateFormatter.Options] = [
            [.withInternetDateTime, .withFractionalSeconds],
            [.withInternetDateTime],
            [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime],
        ]
        for opts in options {
            let f = ISO8601DateFormatter()
            f.formatOptions = opts
            if let date = f.date(from: dateStr) {
                let display = DateFormatter()
                display.dateFormat = "HH:mm"
                return display.string(from: date)
            }
        }
        return ""
    }
}
