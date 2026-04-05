import Foundation

public enum RasediError: Error, LocalizedError {
    case invalidURL
    case serializationError
    case requestFailed(statusCode: Int, data: String)
    case verificationNotImplemented
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .serializationError: return "Failed to serialize request body"
        case .requestFailed(let statusCode, let data): return "Request failed with status \(statusCode): \(data)"
        case .verificationNotImplemented: return "Verification not implemented for client-side SDK due to security risks. Use status checking or webhooks instead."
        }
    }
}

public class RasediClient {
    private static let apiBaseURL = "https://api.rasedi.com"
    private static let upstreamVersion = 1
    
    private let auth: Auth
    private let isTest: Bool
    private let session: URLSession
    
    public init(privateKey: String, secretKey: String) {
        self.auth = Auth(privateKeyPem: privateKey, keyId: secretKey)
        self.isTest = secretKey.contains("test")
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        self.session = URLSession(configuration: config)
    }
    
    private func call<T: Codable, U: Codable>(path: String, method: String, body: U?) async throws -> ApiResponse<T> {
        let env = isTest ? "test" : "live"
        let relativeUrl = "/v\(RasediClient.upstreamVersion)/payment/rest/\(env)\(path)"
        guard let url = URL(string: RasediClient.apiBaseURL + relativeUrl) else {
            throw RasediError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(body)
                request.httpBody = data
            } catch {
                throw RasediError.serializationError
            }
        }
        
        let signature = try auth.makeSignature(method: method, relativeUrl: relativeUrl)
        request.setValue(signature, forHTTPHeaderField: "x-signature")
        request.setValue(auth.getKeyId(), forHTTPHeaderField: "x-id")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RasediError.requestFailed(statusCode: 0, data: String(data: data, encoding: .utf8) ?? "")
        }
        
        let statusCode = httpResponse.statusCode
        if statusCode < 200 || statusCode > 209 {
            throw RasediError.requestFailed(statusCode: statusCode, data: String(data: data, encoding: .utf8) ?? "")
        }
        
        let decoder = JSONDecoder()
        let decodedBody = try decoder.decode(T.self, from: data)
        let headers = httpResponse.allHeaderFields
        
        return ApiResponse(body: decodedBody, headers: headers, statusCode: statusCode)
    }
    
    public func createPayment(payload: CreatePaymentPayload) async throws -> ApiResponse<PaymentResponseBody> {
        return try await call(path: "/create", method: "POST", body: payload)
    }
    
    public func getPaymentByReference(referenceCode: String) async throws -> ApiResponse<PaymentResponseBody> {
        // Use String as dummy codable type for nil body
        let noBody: String? = nil
        return try await call(path: "/status/\(referenceCode)", method: "GET", body: noBody)
    }
    
    public func cancelPayment(referenceCode: String) async throws -> ApiResponse<PaymentResponseBody> {
        let noBody: String? = nil
        return try await call(path: "/cancel/\(referenceCode)", method: "PATCH", body: noBody)
    }
    
    @available(*, deprecated, message: "Use status checking or webhooks instead.")
    public func verify(payload: Any) async throws -> Any {
        throw RasediError.verificationNotImplemented
    }
}
