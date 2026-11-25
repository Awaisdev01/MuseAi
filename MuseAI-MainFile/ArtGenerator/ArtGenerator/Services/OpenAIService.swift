import UIKit
import Foundation

enum OpenAIModel: String, CaseIterable, Identifiable {
    case gptImage1 = "gpt-image-1"
    case dallE3 = "dall-e-3"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gptImage1: return "GPT Image"
        case .dallE3: return "DALL·E 3"
        }
    }

    var supportedSizes: [ImageSize] {
        switch self {
        case .gptImage1: return [.square1024, .landscape, .portrait]
        case .dallE3: return [.square1024, .landscape, .portrait]
        }
    }
}

enum ImageSize: String, CaseIterable, Identifiable {
    case square1024 = "1024x1024"
    case landscape = "1536x1024"
    case portrait = "1024x1536"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .square1024: return "1:1"
        case .landscape: return "3:2"
        case .portrait: return "2:3"
        }
    }

    var icon: String {
        switch self {
        case .square1024: return "square"
        case .landscape: return "rectangle"
        case .portrait: return "rectangle.portrait"
        }
    }
}

enum ImageQuality: String, CaseIterable, Identifiable {
    case low, medium, high

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }
}

struct GenerationSettings {
    var model: OpenAIModel = .gptImage1
    var size: ImageSize = .square1024
    var quality: ImageQuality = .medium
}

enum OpenAIError: LocalizedError {
    case emptyPrompt
    case invalidAPIKey
    case networkError(Error)
    case rateLimited
    case contentPolicyViolation
    case invalidResponse
    case serverError(String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .emptyPrompt: return "Please enter a description for your image."
        case .invalidAPIKey: return "Invalid API key. Please check your configuration."
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .rateLimited: return "Too many requests. Please wait a moment and try again."
        case .contentPolicyViolation: return "Your prompt was flagged by our safety system. Please try a different description."
        case .invalidResponse: return "Received an invalid response. Please try again."
        case .serverError(let m): return m
        case .decodingError: return "Failed to process the generated image. Please try again."
        }
    }
}

actor OpenAIService {
    static let shared = OpenAIService()

    private let session: URLSession
    private var baseURL: String { AppConfig.apiBaseURL }
    private let maxRetries = 2

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 180
        session = URLSession(configuration: config)
    }

    // MARK: - Image Generation
    func generateImage(prompt: String, negativePrompt: String? = nil, settings: GenerationSettings, apiKey: String) async throws -> UIImage {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OpenAIError.emptyPrompt
        }
        guard !apiKey.isEmpty, !apiKey.contains("xxxx"), !apiKey.contains("YOUR_") else {
            throw OpenAIError.invalidAPIKey
        }

        var finalPrompt = prompt
        if let neg = negativePrompt, !neg.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            finalPrompt += ". Avoid: \(neg)"
        }

        let url = URL(string: "\(baseURL)/images/generations")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": settings.model.rawValue,
            "prompt": finalPrompt,
            "n": 1,
            "size": settings.size.rawValue,
            "quality": settings.quality.rawValue
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        return try await performImageRequestWithRetry(request: request)
    }

    // MARK: - Batch
    func generateBatch(prompt: String, negativePrompt: String? = nil, settings: GenerationSettings, count: Int, apiKey: String) async throws -> [UIImage] {
        try await withThrowingTaskGroup(of: UIImage.self) { group in
            for _ in 0..<count {
                group.addTask {
                    try await self.generateImage(prompt: prompt, negativePrompt: negativePrompt, settings: settings, apiKey: apiKey)
                }
            }
            var images: [UIImage] = []
            for try await image in group { images.append(image) }
            return images
        }
    }

    // MARK: - Image Analysis
    func analyzeImage(_ image: UIImage, userPrompt: String, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty, !apiKey.contains("xxxx"), !apiKey.contains("YOUR_") else { throw OpenAIError.invalidAPIKey }
        guard let imageData = image.jpegData(compressionQuality: 0.6) else { throw OpenAIError.decodingError }

        let base64Image = imageData.base64EncodedString()
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let sys = userPrompt.isEmpty
            ? "Create a detailed DALL-E prompt to recreate this image. Include composition, colors, lighting, style. Under 150 words. Return ONLY the prompt."
            : "Combine this image with the user's request into a DALL-E prompt. Under 150 words. Return ONLY the prompt."

        let messages: [[String: Any]] = [
            ["role": "system", "content": sys],
            ["role": "user", "content": [
                ["type": "text", "text": userPrompt.isEmpty ? "Describe this image" : userPrompt],
                ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)", "detail": "low"]]
            ] as [Any]]
        ]

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "max_tokens": 250,
            "temperature": 0.7
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw OpenAIError.invalidResponse }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let msg = choices.first?["message"] as? [String: Any],
              let content = msg["content"] as? String else { throw OpenAIError.decodingError }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Prompt Enhancement
    func enhancePrompt(prompt: String, style: ArtStylePreset, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty, !apiKey.contains("xxxx"), !apiKey.contains("YOUR_") else { throw OpenAIError.invalidAPIKey }

        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "Enhance this image prompt with artistic details for \"\(style.name)\" style (\(style.promptSuffix)). Under 150 words. Return ONLY the enhanced prompt."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 200,
            "temperature": 0.7
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let msg = choices.first?["message"] as? [String: Any],
              let content = msg["content"] as? String else { return prompt }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Request with Retry
    private func performImageRequestWithRetry(request: URLRequest, attempt: Int = 0) async throws -> UIImage {
        do {
            return try await performImageRequest(request: request)
        } catch OpenAIError.networkError(_) where attempt < maxRetries {
            let delay = UInt64(pow(2.0, Double(attempt))) * 1_000_000_000
            try await Task.sleep(nanoseconds: delay)
            print("🔄 Retry attempt \(attempt + 1)...")
            return try await performImageRequestWithRetry(request: request, attempt: attempt + 1)
        } catch OpenAIError.rateLimited where attempt < maxRetries {
            try await Task.sleep(nanoseconds: 3_000_000_000)
            print("🔄 Rate limited, retrying...")
            return try await performImageRequestWithRetry(request: request, attempt: attempt + 1)
        }
    }

    private func performImageRequest(request: URLRequest) async throws -> UIImage {
        print("🎨 Sending generation request...")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            print("❌ Network: \(error.localizedDescription)")
            throw OpenAIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else { throw OpenAIError.invalidResponse }
        print("📡 Status: \(http.statusCode)")

        if http.statusCode == 401 {
            throw OpenAIError.invalidAPIKey
        }
        if http.statusCode == 429 {
            throw OpenAIError.rateLimited
        }

        if http.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("❌ API error: \(body)")
            if let info = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let err = info["error"] as? [String: Any] {
                if (err["code"] as? String) == "content_policy_violation" { throw OpenAIError.contentPolicyViolation }
                if let msg = err["message"] as? String { throw OpenAIError.serverError(msg) }
            }
            throw OpenAIError.serverError("Server returned \(http.statusCode)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArr = json["data"] as? [[String: Any]],
              let first = dataArr.first else {
            throw OpenAIError.decodingError
        }

        if let b64 = first["b64_json"] as? String,
           let imgData = Data(base64Encoded: b64),
           let img = UIImage(data: imgData) {
            print("✅ Generated (base64)")
            return img
        }

        if let urlStr = first["url"] as? String, let url = URL(string: urlStr) {
            print("📥 Downloading from URL...")
            let (imgData, _) = try await session.data(from: url)
            if let img = UIImage(data: imgData) {
                print("✅ Generated (URL)")
                return img
            }
        }

        throw OpenAIError.decodingError
    }
}
