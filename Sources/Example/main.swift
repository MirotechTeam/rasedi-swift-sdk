import Foundation
import Rasedi

@main
struct ExampleApp {
    static func main() async throws {
        let privateKey = """
        -----BEGIN PRIVATE KEY-----
        <HERE>
        -----END PRIVATE KEY-----
        """

        let secretKey = "<HERE>"

        let client = RasediClient(privateKey: privateKey, secretKey: secretKey)

        let payload = CreatePaymentPayload(
            amount: "1000",
            title: "Test Payment from Swift SDK",
            description: "This is a test payment to verify the SDK functionality.",
            gateways: [.fib, .zain, .fastPay],
            redirectUrl: "https://example.com/redirect",
            callbackUrl: "https://example.com/callback",
            collectFeeFromCustomer: false,
            collectCustomerEmail: false,
            collectCustomerPhoneNumber: false
        )

        do {
            print("Creating payment...")
            let response = try await client.createPayment(payload: payload)
            print("Payment Created Successfully!")
            print("Reference Code: \(response.body.referenceCode)")
            print("Redirect URL: \(response.body.redirectUrl)")
        } catch {
            print("Error creating payment: \(error.localizedDescription)")
            exit(1)
        }
    }
}
