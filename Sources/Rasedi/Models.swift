import Foundation

public struct CreatePaymentPayload: Codable {
    public var amount: String
    public var title: String
    public var description: String
    public var gateways: [Gateway]
    public var redirectUrl: String
    public var callbackUrl: String
    public var collectFeeFromCustomer: Bool
    public var collectCustomerEmail: Bool
    public var collectCustomerPhoneNumber: Bool
    
    public init(
        amount: String,
        title: String,
        description: String,
        gateways: [Gateway],
        redirectUrl: String,
        callbackUrl: String,
        collectFeeFromCustomer: Bool,
        collectCustomerEmail: Bool,
        collectCustomerPhoneNumber: Bool
    ) {
        self.amount = amount
        self.title = title
        self.description = description
        self.gateways = gateways
        self.redirectUrl = redirectUrl
        self.callbackUrl = callbackUrl
        self.collectFeeFromCustomer = collectFeeFromCustomer
        self.collectCustomerEmail = collectCustomerEmail
        self.collectCustomerPhoneNumber = collectCustomerPhoneNumber
    }
}

public struct PaymentResponseBody: Codable {
    public var referenceCode: String
    public var amount: String
    public var paidVia: String?
    public var paidAt: String?
    public var redirectUrl: String
    public var status: PaymentStatus
    public var payoutAmount: String?
    
    public init(
        referenceCode: String,
        amount: String,
        paidVia: String? = nil,
        paidAt: String? = nil,
        redirectUrl: String,
        status: PaymentStatus,
        payoutAmount: String? = nil
    ) {
        self.referenceCode = referenceCode
        self.amount = amount
        self.paidVia = paidVia
        self.paidAt = paidAt
        self.redirectUrl = redirectUrl
        self.status = status
        self.payoutAmount = payoutAmount
    }
}

public struct ApiResponse<T: Codable> {
    public var body: T
    public var headers: [AnyHashable: Any]
    public var statusCode: Int
    
    public init(body: T, headers: [AnyHashable : Any], statusCode: Int) {
        self.body = body
        self.headers = headers
        self.statusCode = statusCode
    }
}
