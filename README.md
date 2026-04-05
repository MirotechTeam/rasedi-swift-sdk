# Rasedi Swift SDK

Universal Rasedi Payment Gateway SDK for iOS, macOS, and Swift server-side applications. Fully powered by Apple's native `CryptoKit` and `Security` frameworks to ensure zero external dependencies and maximum security for cryptographic signatures.

## Github Repository

Check the [Github Repository](https://github.com/MirotechTeam/rasedi-swift-sdk) for full implementations.

## Installation

### Swift Package Manager (SPM)

The preferred way to install the Rasedi SDK is through the Swift Package Manager.

**In Xcode:**
1. Go to `File` > `Add Packages...`
2. Enter the repository URL: `https://github.com/MirotechTeam/rasedi-swift-sdk.git`
3. Click "Add Package" and select the `Rasedi` library for your target.

**In `Package.swift`:**
Add the dependency to your project's `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/MirotechTeam/rasedi-swift-sdk.git", from: "1.0.0")
]
```

## Usage

### Initialization

Initialize the `RasediClient` with your cryptographic credentials. Obtain your raw PEM format keys from the Rasedi Dashboard.

```swift
import Rasedi

let privateKey = """
-----BEGIN PRIVATE KEY-----
MC4CAQAwBQYDK2VwBCIEICJ+........................................
-----END PRIVATE KEY-----
"""

let secretKey = "test_your_secret_key_here"

let client = RasediClient(privateKey: privateKey, secretKey: secretKey)
```

> **Note**: Test vs. Live environment URL routing is automatically deduced based on whether your `secretKey` string contains `"test"`.

### 1. Create a Payment

Initiate a new payment request. Specify the supported `Gateway` endpoints and callback destinations.

```swift
let payload = CreatePaymentPayload(
    amount: "1050", // Amount in smallest currency unit 
    title: "Order #12345",
    description: "Premium Subscription Plan",
    gateways: [.creditCard, .zain], // Specify allowed payment methods
    redirectUrl: "https://your-domain.com/payment/success",
    callbackUrl: "https://your-domain.com/api/webhooks/payment", // For server-to-server notifications
    collectFeeFromCustomer: false,
    collectCustomerEmail: true,
    collectCustomerPhoneNumber: true
)

Task {
    do {
        let paymentResponse = try await client.createPayment(payload: payload)
        
        print("Payment Initiated: \(paymentResponse.body.referenceCode)")
        print("Redirect URL: \(paymentResponse.body.redirectUrl)")
    } catch {
        print("Payment error: \(error.localizedDescription)")
    }
}
```

### 2. Check Payment Status (`getStatus`)

Retrieve the current deterministic status of a payment using its unique `referenceCode`. Useful for polling verification without waiting for standard webhook callbacks.

```swift
Task {
    do {
        let statusResponse = try await client.getPaymentByReference(referenceCode: "YOUR_REFERENCE_CODE")
        
        if statusResponse.body.status == .paid {
            print("Payment successful!")
        } else {
            print("Current Status: \(statusResponse.body.status.rawValue)")
        }
    } catch {
        print("Status check failed: \(error)")
    }
}
```

### 3. Cancel a Payment (`cancelPayment`)

Cancel a pending payment session programmatically. This operation is strictly only permissible when the payment is currently listed in a `.pending` state prior to execution.

```swift
Task {
    do {
        let cancelResponse = try await client.cancelPayment(referenceCode: "YOUR_REFERENCE_CODE")
        
        if cancelResponse.body.status == .canceled {
            print("Payment successfully canceled.")
        }
    } catch {
        print("Cancellation error: \(error)")
    }
}
```

## Enums & Constants

### `Gateway`

Supported payment gateways:

| Enum Value | String Raw | Description |
| :--- | :--- | :--- |
| `.fib` | `FIB` | First Iraqi Bank |
| `.zain` | `ZAIN` | ZainCash |
| `.asiaPay` | `ASIA_PAY` | AsiaPay |
| `.fastPay` | `FAST_PAY` | FastPay |
| `.nassWallet` | `NASS_WALLET` | NassWallet |
| `.creditCard` | `CREDIT_CARD` | Credit Card (Visa/Mastercard) |

### `PaymentStatus`

Possible determinative states surrounding a specific payment context:

| Enum Value | String Raw | Description |
| :--- | :--- | :--- |
| `.pending` | `PENDING` | Payment created and awaiting user action |
| `.paid` | `PAID` | Payment successfully completed |
| `.failed` | `FAILED` | Payment failed or was declined |
| `.canceled` | `CANCELED` | Payment was manually canceled |
| `.timedOut` | `TIMED_OUT` | Payment session expired over inactivity |

## Platform Support

- `iOS 13.0+`
- `macOS 10.15+`
- `tvOS 13.0+`
- `watchOS 6.0+`

(Requires Apple's natively included `CryptoKit` implementations to drive fast, isolated, standard cryptographic integrations independent of bloated C libraries).

## License

MIT
