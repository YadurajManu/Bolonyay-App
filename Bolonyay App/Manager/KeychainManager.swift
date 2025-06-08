import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.bolonyay.app"
    private let emailKey = "user_email"
    private let passwordKey = "user_password"
    private let rememberMeKey = "remember_me_enabled"
    
    private init() {}
    
    // MARK: - Save Credentials
    
    func saveCredentials(email: String, password: String) -> Bool {
        let emailSaved = save(key: emailKey, data: email.data(using: .utf8) ?? Data())
        let passwordSaved = save(key: passwordKey, data: password.data(using: .utf8) ?? Data())
        
        if emailSaved && passwordSaved {
            UserDefaults.standard.set(true, forKey: rememberMeKey)
            print("✅ Credentials saved securely to Keychain")
            return true
        } else {
            print("❌ Failed to save credentials to Keychain")
            return false
        }
    }
    
    func saveRememberMePreference(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: rememberMeKey)
        
        if !enabled {
            // If user disabled remember me, clear saved credentials
            clearCredentials()
        }
    }
    
    // MARK: - Retrieve Credentials
    
    func getCredentials() -> (email: String?, password: String?)? {
        guard isRememberMeEnabled() else { return nil }
        
        guard let emailData = load(key: emailKey),
              let passwordData = load(key: passwordKey),
              let email = String(data: emailData, encoding: .utf8),
              let password = String(data: passwordData, encoding: .utf8) else {
            return nil
        }
        
        return (email: email, password: password)
    }
    
    func isRememberMeEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: rememberMeKey)
    }
    
    func getSavedEmail() -> String? {
        guard let emailData = load(key: emailKey),
              let email = String(data: emailData, encoding: .utf8) else {
            return nil
        }
        return email
    }
    
    // MARK: - Clear Credentials
    
    func clearCredentials() {
        delete(key: emailKey)
        delete(key: passwordKey)
        UserDefaults.standard.removeObject(forKey: rememberMeKey)
        print("🧹 Cleared saved credentials from Keychain")
    }
    
    // MARK: - Private Keychain Operations
    
    private func save(key: String, data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item if it exists
        delete(key: key)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        return status == errSecSuccess ? result as? Data : nil
    }
    
    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
} 