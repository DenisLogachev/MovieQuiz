import Foundation

struct NetworkClient {
    
    func fetch(url: URL, handler: @escaping (Result<Data, Error>) -> Void) {
        let request = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                if let urlError = error as? URLError {
                    handler(.failure(MovieLoadingError.networkError(urlError)))
                } else {
                    handler(.failure(MovieLoadingError.networkError(error)))
                }
                return
            }
            
            if let response = response as? HTTPURLResponse,
               !(200...300).contains(response.statusCode){
                handler(.failure(MovieLoadingError.networkError(URLError (.badServerResponse))))
                return
            }
            
            guard let data = data else {
                handler(.failure(MovieLoadingError.networkError(URLError (.cannotParseResponse))))
                return
            }
            handler(.success(data))
        }
        
        task.resume()
    }
}
