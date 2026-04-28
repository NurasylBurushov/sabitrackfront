import SwiftUI

struct ChatDetailView: View {
    let chatId: String
    let chatName: String
    @State private var messages: [Message] = []
    @State private var newMessage = ""
    // ✅ Правильный способ закрытия экрана
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.peachBg.ignoresSafeArea()
            VStack(spacing: 0) {
                // Навбар
                HStack(spacing: 12) {
                    // ✅ РАБОЧАЯ КНОПКА НАЗАД
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
                        Text("В сети")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
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
                        LazyVStack(spacing: 8) {
                            ForEach(messages) { msg in
                                MessageBubble(message: msg, isMe: msg.senderId == "demo_001")
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
                            .onSubmit { sendMessage() }
                        
                        if !newMessage.isEmpty {
                            Button {
                                sendMessage()
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
        .onAppear { loadMessages() }
    }
    
    func loadMessages() {
        messages = [
            Message(id: "m1", text: "Здравствуйте! Я пришла на работу.", senderId: "nanny_1", createdAt: "2026-04-23T09:00:00", read: true),
            Message(id: "m2", text: "Доброе утро, Айгуль! Дверь открыта.", senderId: "demo_001", createdAt: "2026-04-23T09:01:00", read: true),
            Message(id: "m3", text: "Малыш проснулся в хорошем настроении 😊", senderId: "nanny_1", createdAt: "2026-04-23T09:30:00", read: true),
            Message(id: "m4", text: "Замечательно! Покормите его кашей, пожалуйста", senderId: "demo_001", createdAt: "2026-04-23T09:31:00", read: true),
            Message(id: "m5", text: "Малыш покушал и уснул 😊", senderId: "nanny_1", createdAt: "2026-04-23T14:32:00", read: false),
        ]
    }
    
    func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let msg = Message(
            id: "m_\(UUID().uuidString.prefix(8))",
            text: newMessage,
            senderId: "demo_001",
            createdAt: ISO8601DateFormatter().string(from: Date()),
            read: false
        )
        messages.append(msg)
        newMessage = ""
        
        // Эхо-ответ (демо)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let reply = Message(
                id: "r_\(UUID().uuidString.prefix(8))",
                text: "Хорошо, поняла! 👍",
                senderId: "nanny_1",
                createdAt: ISO8601DateFormatter().string(from: Date()),
                read: false
            )
            messages.append(reply)
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
    
    func formatTime(_ dateStr: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        if let date = formatter.date(from: dateStr) {
            let display = DateFormatter()
            display.dateFormat = "HH:mm"
            return display.string(from: date)
        }
        return ""
    }
}
