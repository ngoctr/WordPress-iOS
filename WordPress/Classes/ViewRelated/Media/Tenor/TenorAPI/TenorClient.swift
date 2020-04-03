// Encapsulates Tenor API Client to interact with Tenor

import Alamofire
import Foundation

// MARK: Search endpoint & params

private enum EndPoints: String {
    case search = "https://api.tenor.com/v1/search"
}

private enum SearchParams: String {
    case key
    case searchString = "q"
    case mediaFilter = "media_filter"
    case limit
    case position = "pos"
}

// MARK: - TenorClient

private struct ClientConfig {
    var apiKey: String?
}

struct TenorClient {
    typealias TenorSearchResult = ((_ data: [TenorGIF]?, _ position: String?, _ error: Error?) -> Void)

    private var config: ClientConfig
    static var shared = TenorClient()

    private init() {
        config = ClientConfig()
    }

    static func configure(apiKey: String) {
        shared.config.apiKey = apiKey
    }

    // MARK: - Public Methods

    public func search(for query: String, limit: Int = 20, from position: String?, completion: @escaping TenorSearchResult) {
        assert(limit <= 50, "Tenor allows a maximum 50 images per search")

        guard let url = URL(string: EndPoints.search.rawValue) else {
            return
        }

        let params: [String: Any] = [
            SearchParams.key.rawValue: config.apiKey!,
            SearchParams.searchString.rawValue: query,
            SearchParams.limit.rawValue: limit,
            SearchParams.position.rawValue: position ?? "",
        ]

        Alamofire.request(url, method: .get, parameters: params).responseData { response in

            switch response.result {
            case .success:
                guard let data = response.data else {
                    let error = NSError(domain: "TenorClient", code: -1, userInfo: nil)
                    completion(nil, nil, error)
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .millisecondsSince1970

                    let response = try decoder.decode(TenorResponse<[TenorGIF]>.self, from: data)
                    completion(response.results ?? [], response.next, nil)
                } catch {
                    assertionFailure("Couldn't decode API response from Tenor. Required to check https://tenor.com/gifapi/documentation for breaking changes if needed")
                    completion(nil, nil, error)
                }

            case .failure(let error):
                completion(nil, nil, error)
            }
        }
    }
}
