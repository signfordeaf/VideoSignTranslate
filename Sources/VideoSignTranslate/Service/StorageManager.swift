import Foundation
import Combine

@available(iOS 13.0, *)
public class StorageManager: ObservableObject {
    @Published public var models: [SignCacheModel] = []

    private let storageKey = "WeSignCacheStorage"

    public init() {
        load()
       // print("models:: \(models)")
    }

    @MainActor public func save(model: SignCacheModel) {
       // print("Gelen model: \(String(describing: model.videoBundleId))")

        // Aynı `videoBundleId`'ye sahip bir model varsa işlem yapma
        if models.contains(where: { $0.videoBundleId == model.videoBundleId }) {
            print(
                "Kayıt zaten mevcut: \(String(describing: model.videoBundleId))"
            )
            return
        }

        // Yeni modeli ekle ve UserDefaults'a kaydet
        models.append(model)
        persist()
        ApiService.shared
            .wesignCreate(
                videoBundleId: model.videoBundleId ?? "",
                videoPath: model.videoPath ?? "") { _ in }
    }

    public func load() {
        if let savedData = UserDefaults.standard.data(forKey: storageKey),
           let savedModels = try? JSONDecoder().decode([SignCacheModel].self, from: savedData) {
            models = savedModels
        //    print("Yüklendi: \(models.count) model")
        } else {
            models = []
        }
    }

    public func find(by videoBundleId: String) -> SignCacheModel? {
        return models.first { $0.videoBundleId == videoBundleId }
    }

    public func delete(model: SignCacheModel) {
        models.removeAll { $0.videoBundleId == model.videoBundleId }
        persist()
    }

    public func deleteAll() {
        models.removeAll()
        persist()
    }

    private func persist() {
        if let encoded = try? JSONEncoder().encode(models) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
}
