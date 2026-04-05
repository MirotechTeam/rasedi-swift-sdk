import XCTest
@testable import Rasedi

final class RasediTests: XCTestCase {
    
    func testTestEnvironmentDetection() {
        let clientTest = RasediClient(privateKey: "pk", secretKey: "test_secret_key")
        let clientLive = RasediClient(privateKey: "pk", secretKey: "live_secret_key")
        
        let urlTest = getEnvironmentUrl(client: clientTest)
        XCTAssertTrue(urlTest.contains("/test/"), "URL should contain /test/ if secretKey includes 'test'")
        
        let urlLive = getEnvironmentUrl(client: clientLive)
        XCTAssertTrue(urlLive.contains("/live/"), "URL should contain /live/ if secretKey doesn't include 'test'")
    }
    
    // Use reflection to access private url format logic just for basic logic verification
    private func getEnvironmentUrl(client: RasediClient) -> String {
        let mirror = Mirror(reflecting: client)
        let isTest = mirror.descendant("isTest") as? Bool ?? false
        return isTest ? "/test/" : "/live/"
    }
    
    func testEd25519Signature() throws {
        // Quick verification the Auth class parses Ed25519 OID format PKCS8 without throwing unsupported format
        let dummyEd25519 = """
        -----BEGIN PRIVATE KEY-----
        MC4CAQAwBQYDK2VwBCIEIIHHOyI452c1TGEbZZd/YmP6Qk1B9g+A2w58N7L0r8qE
        -----END PRIVATE KEY-----
        """
        
        let auth = Auth(privateKeyPem: dummyEd25519, keyId: "test_key")
        let signature = try auth.makeSignature(method: "POST", relativeUrl: "/v1/payment/rest/test/create")
        XCTAssertFalse(signature.isEmpty)
    }
}
