import Foundation

enum MovieLoadingError: Error {
    case networkError(Error)
    case apiError(String)
    case emptyMoviesList
}
