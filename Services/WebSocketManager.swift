import Foundation
import Combine

class WebSocketManager: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    @Published var isConnected = false
    @Published var lastMessage: Message?
    @Published var messages: [Message] = []
    @Published var error: String?
    
    private var webSocket: URLSessionWebSocket?
    private var receiveTask: Task<Void, Never>?
    private var heartbeatTask: Task<Void, Never>?
    private var chatId: String?
    
    static let shared = WebSocketManager()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Connection Management
    func connect(chatId: String) {
        self.chatId = chatId
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            error = "Отсутствует токен авторизации"
            return
        }
        
        messages.removeAll()
        lastMessage = nil
        
        let wsSchemeHost = APIBase.url.replacingOccurrences(of: "https://", with: "wss://")
        var components = URLComponents(string: "\(wsSchemeHost)/api/chats/\(chatId)/ws")
        components?.queryItems = [URLQueryItem(name: "token", value: token)]
        
        guard let url = components?.url else {
            error = "Некорректный URL WebSocket"
            return
        }
        
        let urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        webSocket = urlSession.webSocketTask(with: url)
        webSocket?.resume()
        
        isConnected = true
        error = nil
        
        // Начинаем слушать сообщения
        receiveMessages()
        
        // Heartbeat для поддержания соединения
        startHeartbeat()
    }
    
    func disconnect() {
        receiveTask?.cancel()
        heartbeatTask?.cancel()
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        isConnected = false
    }
    
    // MARK: - Send Message
    func sendMessage(_ text: String) {
        guard isConnected else {
            error = "WebSocket не подключён"
            return
        }
        
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        let messageData: [String: Any] = [
            "text": text,
            "type": "text"
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: messageData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            error = "Ошибка кодирования сообщения"
            return
        }
        
        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocket?.send(message) { [weak self] err in
            if let err = err {
                self?.error = "Ошибка отправки: \(err.localizedDescription)"
                print("WebSocket send error: \(err)")
            }
        }
    }
    
    // MARK: - Receive Messages
    private func receiveMessages() {
        receiveTask = Task {
            while !Task.isCancelled {
                do {
                    let message = try await webSocket?.receive()
                    
                    switch message {
                    case .string(let json):
                        if let data = json.data(using: .utf8) {
                            if let msg = try? JSONDecoder().decode(Message.self, from: data) {
                                DispatchQueue.main.async {
                                    self.lastMessage = msg
                                    if !self.messages.contains(where: { $0.id == msg.id }) {
                                        self.messages.append(msg)
                                    }
                                }
                            }
                        }
                    case .data(let data):
                        print("Получены бинарные данные: \(data)")
                    case nil:
                        print("WebSocket соединение закрыто")
                        await MainActor.run {
                            self.isConnected = false
                        }
                    @unknown default:
                        break
                    }
                } catch {
                    if !Task.isCancelled {
                        DispatchQueue.main.async {
                            self.error = "Ошибка WebSocket: \(error.localizedDescription)"
                            self.isConnected = false
                        }
                    }
                    break
                }
            }
        }
    }
    
    // MARK: - Heartbeat
    private func startHeartbeat() {
        heartbeatTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30 * 1_000_000_000) // 30 секунд
                
                if isConnected {
                    let ping = URLSessionWebSocketTask.Message.string("{\"type\":\"ping\"}")
                    webSocket?.send(ping) { _ in }
                }
            }
        }
    }
    
    // MARK: - URLSessionWebSocketDelegate
    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        DispatchQueue.main.async {
            self.isConnected = true
            self.error = nil
            print("✅ WebSocket подключён")
        }
    }
    
    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        DispatchQueue.main.async {
            self.isConnected = false
            print("❌ WebSocket закрыт с кодом: \(closeCode.rawValue)")
        }
    }
}
