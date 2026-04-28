import Foundation

class NetworkService {
    static let shared = NetworkService()
    private let baseURL = "https://web-production-a7db4.up.railway.app"
    
    private init() {}
    
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            if T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            return try JSONDecoder().decode(T.self, from: data)
        case 401:
            throw NetworkError.unauthorized
        default:
            let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw NetworkError.serverError(errorData?.message ?? "Ошибка сервера")
        }
    }
    
    func sendSMSCode(phone: String) async throws -> SMSResponse {
        try await request(endpoint: "/api/auth/sms", method: "POST", body: ["phone": phone])
    }
    
    func verifySMS(phone: String, code: String) async throws -> AuthResponse {
        try await request(endpoint: "/api/auth/verify-sms", method: "POST", body: ["phone": phone, "code": code])
    }
    
    func loginWithEmail(email: String, password: String) async throws -> AuthResponse {
        try await request(endpoint: "/api/auth/login", method: "POST", body: ["email": email, "password": password])
    }
    
    func registerWithEmail(name: String, email: String, password: String) async throws -> AuthResponse {
        try await request(endpoint: "/api/auth/register", method: "POST", body: ["name": name, "email": email, "password": password])
    }
    
    func loginWithGoogle(token: String) async throws -> AuthResponse {
        try await request(endpoint: "/api/auth/google", method: "POST", body: ["token": token])
    }
    
    func loginWithApple(identityToken: String) async throws -> AuthResponse {
        try await request(endpoint: "/api/auth/apple", method: "POST", body: ["identityToken": identityToken])
    }
    
    func fetchProfile() async throws -> UserProfile {
        try await request(endpoint: "/api/user/profile")
    }
    
    func fetchNannies(filter: String?, search: String?) async throws -> [Nanny] {
        var params = [String: String]()
        if let f = filter { params["filter"] = f }
        if let s = search { params["search"] = s }
        var endpoint = "/api/nannies?"
        params.forEach { endpoint += "\($0.key)=\($0.value)&" }
        endpoint.removeLast()
        return try await request(endpoint: endpoint)
    }
    
    func fetchMessages(chatId: String) async throws -> [Message] {
        try await request(endpoint: "/api/chats/\(chatId)/messages")
    }
    
    func sendMessage(chatId: String, text: String) async throws -> Message {
        try await request(endpoint: "/api/chats/\(chatId)/messages", method: "POST", body: ["text": text])
    }
    
    func fetchProducts(category: String?) async throws -> [Product] {
        var endpoint = "/api/market/products"
        if let cat = category { endpoint += "?category=\(cat)" }
        return try await request(endpoint: endpoint)
    }
    
    func fetchNannyLocation(nannyId: String) async throws -> NannyLocation {
        try await request(endpoint: "/api/tracking/\(nannyId)/location")
    }
    
    func fetchPaymentMethods() async throws -> [PaymentMethod] {
        try await request(endpoint: "/api/payments/methods")
    }
    
    func addPaymentMethod(type: String, details: [String: String]) async throws -> PaymentMethod {
        var body = details
        body["type"] = type
        return try await request(endpoint: "/api/payments/methods", method: "POST", body: body)
    }
}

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(String)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Некорректный URL"
        case .invalidResponse: return "Некорректный ответ сервера"
        case .unauthorized: return "Требуется авторизация"
        case .serverError(let msg): return msg
        case .decodingError: return "Ошибка обработки данных"
        }
    }
}

struct EmptyResponse: Decodable {}
struct ErrorResponse: Decodable { let message: String }
struct SMSResponse: Decodable { let success: Bool; let message: String }
struct AuthResponse: Decodable {
    let token: String
    let user: UserProfile
}

struct UserProfile: Decodable, Identifiable {
    let id: String
    var name: String
    var email: String?
    var phone: String?
    var avatar: String?
    var role: String?
    var createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id", name, email, phone, avatar, role, createdAt
    }
}

struct Nanny: Decodable, Identifiable {
    let id: String
    var name: String
    var avatar: String?
    var rating: Double
    var pricePerHour: Int
    var experience: Int
    var location: String?
    var about: String?
    var age: Int?
    var verified: Bool?
    var categories: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id", name, avatar, rating, pricePerHour
        case experience, location, about, age, verified, categories
    }
}

struct Message: Decodable, Identifiable {
    let id: String
    var text: String
    var senderId: String
    var chatId: String?
    var createdAt: String
    var read: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id", text, senderId, chatId, createdAt, read
    }
}

struct Product: Decodable, Identifiable {
    let id: String
    var title: String
    var description: String?
    var price: Double
    var image: String?
    var category: String
    var sellerId: String?
    var sellerName: String?
    var condition: String?
    var createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id", title, description, price, image
        case category, sellerId, sellerName, condition, createdAt
    }
}

// ✅ ИСПРАВЛЕНО: добавлен Identifiable для Map
struct NannyLocation: Decodable, Identifiable {
    var id: String { "\(latitude)_\(longitude)_\(Int(timestamp ?? "0") ?? 0)" }
    var latitude: Double
    var longitude: Double
    var timestamp: String?
    var address: String?
    var speed: Double?
    var battery: Int?
}

struct PaymentMethod: Decodable, Identifiable {
    let id: String
    var type: String
    var last4: String?
    var brand: String?
    var isDefault: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id", type, last4, brand, isDefault
    }
}

struct ChatRoom: Identifiable {
    let id: String
    var name: String
    var avatar: String?
    var lastMessage: String?
    var lastMessageTime: String?
    var unreadCount: Int
}
