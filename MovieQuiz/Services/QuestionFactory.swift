import Foundation

final class QuestionFactory: QuestionFactoryProtocol {
    private var usedQuestions: Set<String> = []
    private var movies: [MostPopularMovie] = []
    private weak var delegate: QuestionFactoryDelegate?
    private let moviesLoader: MoviesLoading
    
    init(moviesLoader: MoviesLoading, delegate: QuestionFactoryDelegate?) {
        self.moviesLoader = moviesLoader
        self.delegate = delegate
    }
    
    func requestNextQuestion() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self, !self.movies.isEmpty else { return }
            
            var index: Int
            var movie: MostPopularMovie
            
            repeat {
                index = (0..<self.movies.count).randomElement() ?? 0
                movie = self.movies[index]
            } while self.usedQuestions.contains(movie.id) && self.usedQuestions.count < self.movies.count
            
            self.usedQuestions.insert(movie.id)
            
            guard let _ = try? Data(contentsOf: movie.resizedImageURL) else {
                DispatchQueue.main.async {
                    self.delegate?.didFailToLoadData(with: MovieLoadingError.apiError("No image available"))
                    self.delegate?.didReceiveNextQuestion(question: nil)
                }
                return
            }
            
            URLSession.shared.dataTask(with:movie.resizedImageURL) {data, response, error in
                guard let imageData = data, error == nil else {
                    print("Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let rating = Float(movie.rating) ?? 0
                let possibleRatings: [Float] = [7.0, 7.5, 8.0, 8.5, 9.0, 9.5]
                let randomRating = possibleRatings.randomElement() ?? 7.0
                let isGreaterQuestion = Bool.random()
                let text: String
                let correctAnswer: Bool
                if isGreaterQuestion {
                    text = "Рейтинг этого фильма больше чем \(randomRating)?"
                    correctAnswer = rating > randomRating
                } else {
                    text = "Рейтинг этого фильма меньше чем \(randomRating)?"
                    correctAnswer = rating < randomRating
                }
                
                let question = QuizQuestion(imageData: imageData,
                                            text: text,
                                            correctAnswer: correctAnswer)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.didReceiveNextQuestion(question: question)
                }
            } .resume()
        }
    }
    
    func setup (delegate: QuestionFactoryDelegate) {
        guard self.delegate == nil else {return}
        self.delegate = delegate
    }
    
    func loadData() {
        moviesLoader.loadMovies { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let mostPopularMovies):
                    self.movies = mostPopularMovies.items
                    self.delegate?.didLoadDataFromServer()
                case .failure(let error):
                    self.delegate?.didFailToLoadData(with: error)
                }
            }
        }
    }
}
