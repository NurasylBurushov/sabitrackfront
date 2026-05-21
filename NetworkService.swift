import Foundation

/// Базовый URL того же деплоя, что и babytrack13 (REST + WebSocket).
enum APIBase {
    static let url = "https://web-production-a7db4.up.railway.app"
}

class NetworkService {
    static let shared = NetworkService()
    private let baseURL = APIBase.url
    
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
            let decoder = JSONDecoder()
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                #if DEBUG
                if let preview = String(data: data, encoding: .utf8) {
                    print("JSON decode error: \(error)\nОтвет: \(preview.prefix(800))")
                }
                #endif
                throw NetworkError.decodingError
            }
        case 401:
            throw NetworkError.unauthorized
        default:
            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = obj["detail"] {
                let msg: String
                if let s = detail as? String { msg = s }
                else if let arr = detail as? [String] { msg = arr.joined(separator: ", ") }
                else { msg = "Ошибка сервера" }
                throw NetworkError.serverError(msg)
            }
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
        try await request(endpoint: "/api/users/me")
    }
    
    func updateProfile(name: String? = nil, avatar: String? = nil, role: String? = nil) async throws -> UserProfile {
        var body: [String: Any] = [:]
        if let name { body["name"] = name }
        if let avatar { body["avatar"] = avatar }
        if let role { body["role"] = role }
        return try await request(endpoint: "/api/users/me", method: "PATCH", body: body.isEmpty ? nil : body)
    }
    
    /// Presign → PUT в R2 → публичный URL (фото профиля, няни, маркет).
    func uploadImage(data: Data, purpose: String, contentType: String = "image/jpeg") async throws -> String {
        let presign: PresignUploadResponse = try await request(
            endpoint: "/api/uploads/presign",
            method: "POST",
            body: ["purpose": purpose, "content_type": contentType]
        )
        try await putPresignedUpload(data: data, presign: presign)
        return presign.publicUrl
    }
    
    private func putPresignedUpload(data: Data, presign: PresignUploadResponse) async throws {
        guard let url = URL(string: presign.uploadUrl) else { throw NetworkError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        let headers = presign.requiredHeaders ?? ["Content-Type": "image/jpeg"]
        for (k, v) in headers { req.setValue(v, forHTTPHeaderField: k) }
        req.httpBody = data
        let (_, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NetworkError.serverError("Не удалось загрузить файл в хранилище")
        }
    }
    
    func updateMyNannyAvatar(publicUrl: String) async throws -> Nanny {
        try await request(
            endpoint: "/api/nannies/me",
            method: "PATCH",
            body: ["avatar_url": publicUrl]
        )
    }
    
    func createMarketProduct(
        title: String,
        description: String?,
        price: Int,
        category: String,
        condition: String,
        imageUrl: String?
    ) async throws -> CreateProductResponse {
        var body: [String: Any] = [
            "title": title,
            "price": price,
            "category": category,
            "condition": condition,
        ]
        if let description { body["description"] = description }
        if let imageUrl { body["image_url"] = imageUrl }
        return try await request(endpoint: "/api/market/products", method: "POST", body: body)
    }
    
    func fetchNannies(filter: String?, search: String?) async throws -> [Nanny] {
        var params = [String: String]()
        if let f = filter { params["specialties"] = f }
        if let s = search, !s.isEmpty { params["city"] = s }
        var endpoint = "/api/nannies"
        if !params.isEmpty {
            endpoint += "?"
            params.forEach { endpoint += "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)&" }
            endpoint.removeLast()
        }
        let list: NannyListResponse = try await request(endpoint: endpoint)
        return list.nannies
    }
    
    func fetchChats() async throws -> [ChatListItem] {
        try await request(endpoint: "/api/chats")
    }
    
    func fetchMessages(chatId: String) async throws -> [Message] {
        try await request(endpoint: "/api/chats/\(chatId)/messages")
    }
    
    func sendMessage(chatId: String, text: String) async throws -> Message {
        try await request(endpoint: "/api/chats/\(chatId)/messages", method: "POST", body: ["text": text])
    }
    
    func fetchProducts(category: String?) async throws -> [Product] {
        var endpoint = "/api/market/products"
        if let cat = category, let enc = cat.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            endpoint += "?category=\(enc)"
        }
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

struct PresignUploadResponse: Decodable {
    let uploadUrl: String
    let publicUrl: String
    let key: String
    let requiredHeaders: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case uploadUrl = "upload_url"
        case publicUrl = "public_url"
        case key
        case requiredHeaders = "required_headers"
    }
}

struct CreateProductResponse: Decodable {
    let id: String
    let title: String
    let price: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title, price
    }
}
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
    var profileCompleted: Bool?
    var createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id", name, email, phone, avatar, role, profileCompleted, createdAt
    }
}

struct NannyListResponse: Decodable {
    let nannies: [Nanny]
    let total: Int
    let page: Int
    let perPage: Int
    
    enum CodingKeys: String, CodingKey {
        case nannies, total, page
        case perPage = "per_page"
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        nannies = (try? c.decode([Nanny].self, forKey: .nannies)) ?? []
        page = (try? c.decode(Int.self, forKey: .page)) ?? 1
        if let pp = try? c.decode(Int.self, forKey: .perPage) {
            perPage = pp
        } else if let ppd = try? c.decode(Double.self, forKey: .perPage) {
            perPage = Int(ppd)
        } else {
            perPage = 20
        }
        if let t = try? c.decode(Int.self, forKey: .total) {
            total = t
        } else if let td = try? c.decode(Double.self, forKey: .total) {
            total = Int(td)
        } else {
            total = nannies.count
        }
    }
}

struct ChatListItem: Decodable {
    let id: String
    let nanny: ChatListNanny
    let lastMessage: String?
    let unreadCount: Int
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, nanny
        case lastMessage = "last_message"
        case unreadCount = "unread_count"
        case createdAt = "created_at"
    }
}

struct ChatListNanny: Decodable {
    let id: String?
    let name: String
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case avatarUrl = "avatar_url"
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
    
    init(
        id: String,
        name: String,
        avatar: String? = nil,
        rating: Double,
        pricePerHour: Int,
        experience: Int,
        location: String? = nil,
        about: String? = nil,
        age: Int? = nil,
        verified: Bool? = nil,
        categories: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.rating = rating
        self.pricePerHour = pricePerHour
        self.experience = experience
        self.location = location
        self.about = about
        self.age = age
        self.verified = verified
        self.categories = categories
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let s = try c.decodeIfPresent(String.self, forKey: .id) {
            id = s
        } else {
            id = try c.decode(String.self, forKey: .legacyId)
        }
        let rawName = try c.decodeIfPresent(String.self, forKey: .name)
        let trimmed = rawName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        name = trimmed.isEmpty ? "Няня" : trimmed
        avatar = try c.decodeIfPresent(String.self, forKey: .avatar_url)
            ?? c.decodeIfPresent(String.self, forKey: .avatar)
        rating = Self.decodeDoubleFlexible(c, key: .rating) ?? 0
        pricePerHour = Self.decodeIntFlexible(c, keys: [.hourly_rate, .pricePerHour]) ?? 0
        experience = Self.decodeIntFlexible(c, keys: [.experience_years, .experience]) ?? 0
        let city = try c.decodeIfPresent(String.self, forKey: .city)
        let district = try c.decodeIfPresent(String.self, forKey: .district)
        if let city = city, let district = district, !district.isEmpty {
            location = "\(city), \(district)"
        } else {
            location = city
        }
        about = try c.decodeIfPresent(String.self, forKey: .bio)
            ?? c.decodeIfPresent(String.self, forKey: .about)
        age = try c.decodeIfPresent(Int.self, forKey: .age)
        verified = try c.decodeIfPresent(Bool.self, forKey: .is_verified)
            ?? c.decodeIfPresent(Bool.self, forKey: .verified)
        if let arr = try? c.decode([String].self, forKey: .specialties) {
            categories = arr
        } else if let alt = try? c.decode([String].self, forKey: .categories) {
            categories = alt
        } else {
            categories = []
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case legacyId = "_id"
        case name, avatar, avatar_url, rating
        case hourly_rate, pricePerHour
        case experience_years, experience
        case city, district, bio, about, age
        case is_verified, verified
        case specialties, categories
    }
    
    private static func decodeIntFlexible(_ c: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) -> Int? {
        for key in keys {
            if let i = try? c.decodeIfPresent(Int.self, forKey: key) { return i }
            if let d = try? c.decodeIfPresent(Double.self, forKey: key) { return Int(d.rounded()) }
        }
        return nil
    }
    
    private static func decodeDoubleFlexible(_ c: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Double? {
        if let d = try? c.decodeIfPresent(Double.self, forKey: key) { return d }
        if let i = try? c.decodeIfPresent(Int.self, forKey: key) { return Double(i) }
        return nil
    }
}

struct Message: Decodable, Identifiable, Equatable {
    let id: String
    var text: String
    var senderId: String
    var chatId: String?
    var createdAt: String
    var read: Bool?
    
    init(id: String, text: String, senderId: String, chatId: String? = nil, createdAt: String, read: Bool? = nil) {
        self.id = id
        self.text = text
        self.senderId = senderId
        self.chatId = chatId
        self.createdAt = createdAt
        self.read = read
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let oid = try c.decodeIfPresent(String.self, forKey: .legacyId) {
            id = oid
        } else {
            id = try c.decode(String.self, forKey: .id)
        }
        text = try c.decodeIfPresent(String.self, forKey: .text) ?? ""
        if let sid = try c.decodeIfPresent(String.self, forKey: .sender_id) {
            senderId = sid
        } else {
            senderId = try c.decodeIfPresent(String.self, forKey: .senderId) ?? ""
        }
        if let cid = try c.decodeIfPresent(String.self, forKey: .chat_id) {
            chatId = cid
        } else {
            chatId = try c.decodeIfPresent(String.self, forKey: .chatId)
        }
        if let ca = try c.decodeIfPresent(String.self, forKey: .created_at) {
            createdAt = ca
        } else if let ca = try c.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = ca
        } else {
            createdAt = ""
        }
        read = try c.decodeIfPresent(Bool.self, forKey: .is_read)
            ?? c.decodeIfPresent(Bool.self, forKey: .read)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case legacyId = "_id"
        case text
        case sender_id, senderId
        case chat_id, chatId
        case created_at, createdAt
        case is_read, read
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
