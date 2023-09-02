
import Foundation
import Combine

enum JokeApiError: Error {
    case typeConvertError(object: Any)
    case networkError(statusCode: Int, description: String)
    case decodeError(_ error: Error)
    case unknown
    
    var description: String {
        switch self {
        case .typeConvertError(let object):
            "\(object)が型変換に失敗"
        case .networkError(let statusCode, let description):
            "通信エラー\nstatusCode: \(statusCode), description: \(description)"
        case .decodeError(let description):
            "decodeに失敗\ndescription: \(description)"
        case .unknown:
            "不明なエラー"
        }
    }
}

final class JokeApiViewModel: ObservableObject {
    // @Publishedを付与したプロパティが更新されると、それに関連するViewも再描画する
    @Published var joke: String = ""
        
    private var cancellable: AnyCancellable?
    
    deinit {
        cancellable?.cancel()
    }
    
    func fetchJoke() {
        guard let url = URL(string: "https://icanhazdadjoke.com/") else {
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        cancellable = URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap({ (data, responce) -> Data in // throwできるMap
                guard let _responce = responce as? HTTPURLResponse else {
                    throw JokeApiError.typeConvertError(object: responce)
                }
                guard _responce.statusCode == 200 else {
                    throw JokeApiError.networkError(statusCode: _responce.statusCode, description: _responce.description)
                }
                return data
            })
            .decode(type: Joke.self, decoder: JSONDecoder())
            .mapError({ error in // Errorから別のエラー型に変換(Error->JokeApiError)
                JokeApiError.decodeError(error)
            })
            .receive(on: DispatchQueue.main) // どのスレッドで値を受け取るかを指定する
            .sink { completion in
                switch completion {
                case .finished:
                    print("jokeApi finished.")
                    
                case .failure(let e):
                    print("jokeApi_Error:\n\(e.localizedDescription)")
                }
            } receiveValue: { [weak self] responce in
                self?.joke = responce.joke
            }
    }
}
