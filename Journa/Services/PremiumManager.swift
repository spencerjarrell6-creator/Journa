import Foundation
import StoreKit
import Combine

class PremiumManager: ObservableObject {
    static let shared = PremiumManager()
    
    @Published var isPremium: Bool = false
    @Published var product: Product? = nil
    @Published var isLoading: Bool = false
    
    private let productID = "com.journa.premium.monthly"
    
    init() {
        isPremium = true
        Task { @MainActor in
            await loadProduct()
            //await checkPremiumStatus()
        }
    }
    
    @MainActor
    func loadProduct() async {
        do {
            let products = try await Product.products(for: [productID])
            self.product = products.first
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    @MainActor
    func purchase() async {
        guard let product else { return }
        isLoading = true
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified:
                    isPremium = true
                case .unverified:
                    isPremium = false
                }
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("Purchase failed: \(error)")
        }
        isLoading = false
    }
    
    @MainActor
    func restore() async {
        isLoading = true
        do {
            try await AppStore.sync()
            await checkPremiumStatus()
        } catch {
            print("Restore failed: \(error)")
        }
        isLoading = false
    }
    
    @MainActor
    func checkPremiumStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == productID {
                    isPremium = true
                    return
                }
            }
        }
        isPremium = false
    }
}
