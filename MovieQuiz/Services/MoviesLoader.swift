import Foundation

protocol MoviesLoading {
    func loadMovies(handler: @escaping (Result<MostPopularMovies, Error>) -> Void)
}

struct MoviesLoader: MoviesLoading {
    // MARK: - NetworkClient
    private let networkClient = NetworkClient()
    
    // MARK: - URL
    private var mostPopularMoviesUrl: URL {
        guard let url = URL(string:Constants.apiTopMoviesURL) else {
            preconditionFailure("Unable to construct mostPopularMoviesUrl")
        }
        return url
    }
    
    func loadMovies(handler: @escaping (Result<MostPopularMovies, Error>) -> Void) {
        networkClient.fetch(url: mostPopularMoviesUrl) { result in
            switch result {
            case .success(let data):
                do {
                    let mostPopularMovies = try JSONDecoder().decode(MostPopularMovies.self, from: data)
                    
                    if let errorMessage = mostPopularMovies.errorMessage, !errorMessage.isEmpty {
                        handler(.failure(MovieLoadingError.apiError(errorMessage)))
                        return
                    } else if mostPopularMovies.items.isEmpty {
                        handler(.failure(MovieLoadingError.emptyMoviesList))
                        return
                    }
                    handler(.success(mostPopularMovies))
                    
                } catch {
                    handler(.failure(MovieLoadingError.networkError(error)))
                }
                
            case .failure(let error):
                if let urlError = error as? URLError, urlError.code == .notConnectedToInternet { print("Нет интернета")
                }
                handler(.failure(error))
            }
        }
    }
}

