//
//  ApiService.swift
//  VideoSignTranslate
//
//  Created by Selim Yavaşoğlu on 4.12.2024.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case requestFailed
    case invalidResponse
    case noData
    case decodingError
    case cancelled
}

@available(iOS 13.0, *)
class ApiService: @unchecked Sendable {
    @MainActor static let shared = ApiService()

    @MainActor var storage = StorageManager()

    private init() {}

    func wesignUploadFile(
        videoBundleURL: URL?,
        completion: @escaping @Sendable (Result<Bool, Error>) -> Void
    ) {
        let parameters =
            [
                ["key": "file", "type": "file"]
            ] as [[String: Any]]

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        for param in parameters {
            guard let paramName = param["key"] as? String else { continue }

            body += Data("--\(boundary)\r\n".utf8)
            body += Data(
                "Content-Disposition: form-data; name=\"\(paramName)\"".utf8)

            if let paramType = param["type"] as? String, paramType == "file" {
                // Bundle.main ile video dosyasını alma
                if let fileURL = videoBundleURL {
                    let filename = fileURL.lastPathComponent
                    if let fileContent = try? Data(contentsOf: fileURL) {
                        body += Data("; filename=\"\(filename)\"\r\n".utf8)
                        body += Data("Content-Type: video/mp4\r\n\r\n".utf8)  // Doğru MIME türü
                        body += fileContent
                        body += Data("\r\n".utf8)
                    } else {
                        print("Error: Could not read file content.")
                        completion(
                            .failure(
                                NSError(
                                    domain: "FileError", code: -1,
                                    userInfo: [
                                        NSLocalizedDescriptionKey:
                                            "Could not read file content."
                                    ])))
                        return
                    }
                } else {
                    print("Error: File not found in Bundle.")
                    completion(
                        .failure(
                            NSError(
                                domain: "FileError", code: -2,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        "File not found in Bundle."
                                ])))
                    return
                }
            }
        }

        body += Data("--\(boundary)--\r\n".utf8)

        var request = URLRequest(
            url: URL(string: "https://pl.weaccess.ai/api/upload-file/")!,
            timeoutInterval: Double.infinity
        )
        //        request.addValue(
        //            "sessionid=np0mqeie6s3785y0d9bma378t0jbyxty",
        //            forHTTPHeaderField: "Cookie")
        request.addValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            Task {
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                if let response = response as? HTTPURLResponse {
                    print("Response status code: \(response.statusCode)")

                    if response.statusCode == 200, let data = data {
                        do {
                            // JSON verisini parse et
                            if let json = try JSONSerialization.jsonObject(
                                with: data, options: []) as? [String: Any],
                                let videoPath = json["file_path"] as? String
                            {
                                

                                // Ana iş parçacığında cache işlemini kaydet
                                await MainActor.run {
                                    self.saveCacheFile(
                                        videoBundleURL: videoBundleURL,
                                        videoPath: videoPath
                                    )
                                }
                                self.wesignCreate(
                                    videoBundleId: VideoSignController.shared
                                        .initVideoBundleURL(videoBundleURL!),
                                    videoPath: videoPath) { _ in }
                                completion(.success(true))
                            } else {
                                print(
                                    "Error: 'video_path' bulunamadı veya JSON formatı hatalı."
                                )
                                completion(
                                    .failure(
                                        NSError(
                                            domain: "Invalid JSON", code: 0,
                                            userInfo: nil)))
                            }
                        } catch {
                            print("JSON dönüşüm hatası: \(error)")
                            completion(.failure(error))
                        }
                    } else {
                        print(
                            "Error: Unexpected status code \(response.statusCode)"
                        )
                        completion(
                            .failure(
                                NSError(
                                    domain: "HTTP Error",
                                    code: response.statusCode, userInfo: nil)))
                    }
                } else {
                    print("Error: Invalid response.")
                    completion(
                        .failure(
                            NSError(
                                domain: "Invalid Response", code: 0,
                                userInfo: nil)))
                }
            }
        }

        task.resume()
    }
    @MainActor func saveCacheFile(videoBundleURL: URL?, videoPath: String) {
        storage
            .save(
                model: SignCacheModel(
                    videoType: "file",
                    videoPath: videoPath,
                    videoURL: videoBundleURL?.relativePath,
                    videoBundleId:
                        VideoSignController.shared.initVideoBundleURL(videoBundleURL!),
                    signModel: nil
                )
            )
    }

    func wesignCreate(
        videoBundleId: String,
        videoPath: String,
        completion: @escaping @Sendable (Result<String, Error>) -> Void
    ) {
        let parameters =
            [
                [
                    "key": "api_key",
                    "value": VideoSignController.shared.apiKey,
                    "type": "text",
                ],
                [
                    "key": "video_bundle_id",
                    "value": videoBundleId,
                    "type": "text",
                ],
                [
                    "key": "video_path",
                    "value": videoPath,
                    "type": "text",
                ],
            ] as [[String: Any]]

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        var _: Error? = nil
        for param in parameters {
            if param["disabled"] != nil { continue }
            let paramName = param["key"]!
            body += Data("--\(boundary)\r\n".utf8)
            body += Data(
                "Content-Disposition:form-data; name=\"\(paramName)\"".utf8)
            if param["contentType"] != nil {
                body += Data(
                    "\r\nContent-Type: \(param["contentType"] as! String)".utf8)
            }
            let paramType = param["type"] as! String
            if paramType == "text" {
                let paramValue = param["value"] as! String
                body += Data("\r\n\r\n\(paramValue)\r\n".utf8)
            } else {
                let paramSrc = param["src"] as! String
                let fileURL = URL(fileURLWithPath: paramSrc)
                if let fileContent = try? Data(contentsOf: fileURL) {
                    body += Data("; filename=\"\(paramSrc)\"\r\n".utf8)
                    body += Data(
                        "Content-Type: \"content-type header\"\r\n".utf8)
                    body += Data("\r\n".utf8)
                    body += fileContent
                    body += Data("\r\n".utf8)
                }
            }
        }
        body += Data("--\(boundary)--\r\n".utf8)
        let postData = body

        var request = URLRequest(
            url: URL(
                string: "https://pl.weaccess.ai/mobile/api/wesign-create/")!,
            timeoutInterval: Double.infinity)
        //        request.addValue(
        //            "sessionid=np0mqeie6s3785y0d9bma378t0jbyxty",
        //            forHTTPHeaderField: "Cookie")
        request.addValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type")

        request.httpMethod = "POST"
        request.httpBody = postData

        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            guard let data = data else {
                print(String(describing: error))
                return
            }
            print(String(data: data, encoding: .utf8)!)
        }

        task.resume()

    }

    func wesignGet(
        videoBundleId: String,
        videoPath: String,
        completion: @escaping @Sendable (Result<SignModel, APIError>) -> Void
    ) {
        let parameters = [
            "video_bundle_id": videoBundleId,
            "video_path": videoPath,
            "api_key": VideoSignController.shared.apiKey,

        ]

        guard
            var urlComponents = URLComponents(
                string: "https://pl.weaccess.ai/mobile/api/wesign-get")
        else {
            completion(.failure(.invalidURL))
            return
        }

        urlComponents.queryItems =
            parameters
            .map { URLQueryItem(name: $0.key, value: $0.value) }

        guard let url = urlComponents.url else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(
            url: url, timeoutInterval: Double.infinity)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(
                    with: data, options: [])
                if let jsonDict = json as? [String: Any] {
                    let jsonData = try JSONSerialization.data(
                        withJSONObject: jsonDict, options: [])
                    let decoder = JSONDecoder()
                    let signModel = try decoder.decode(
                        SignModel.self, from: jsonData)
                    completion(.success(signModel))
                } else {
                    completion(
                        .failure(.decodingError)
                    )
                }
            } catch {
                completion(
                    .failure(.invalidResponse)
                )
            }
        }
        task.resume()

    }

}
