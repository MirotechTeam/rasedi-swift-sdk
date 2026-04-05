import Foundation

public enum Gateway: String, Codable, CaseIterable {
    case fib = "FIB"
    case zain = "ZAIN"
    case asiaPay = "ASIA_PAY"
    case fastPay = "FAST_PAY"
    case nassWallet = "NASS_WALLET"
    case creditCard = "CREDIT_CARD"
}

public enum PaymentStatus: String, Codable, CaseIterable {
    case timedOut = "TIMED_OUT"
    case pending = "PENDING"
    case paid = "PAID"
    case canceled = "CANCELED"
    case failed = "FAILED"
}
