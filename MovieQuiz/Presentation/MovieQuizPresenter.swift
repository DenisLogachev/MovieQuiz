import UIKit

final class MovieQuizPresenter: QuestionFactoryDelegate {
    // MARK: - Business Logic Properties
    private let questionsAmount: Int = 10
    private var currentQuestionIndex: Int = 0
    private var correctAnswers: Int = 0
    private let answerDelay: TimeInterval = 1.0
    private var currentQuestion: QuizQuestion?
    
    weak var viewController: MovieQuizViewControllerProtocol?
    
    private lazy var statisticService: StatisticServiceProtocol = StatisticService()
    private lazy var questionFactory: QuestionFactoryProtocol = {
        let factory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        return factory}()
    
    // MARK: - Initialization
    init(viewController: MovieQuizViewControllerProtocol) {
        self.viewController = viewController
    }
    
    // MARK: - Data Loading
    func loadData() {
        viewController?.showLoadingIndicator()
        questionFactory.loadData()
    }
    
    // MARK: - User Actions
    func yesButtonClicked() {
        processAnswer(isYes: true)
    }
    
    func noButtonClicked() {
        processAnswer(isYes: false)
    }
    
    private func processAnswer(isYes: Bool) {
        guard let currentQuestion = currentQuestion else {return}
        let isCorrect = (isYes == currentQuestion.correctAnswer)
        if isCorrect {
            correctAnswers += 1
        }
        viewController?.showAnswerResult(isCorrect: isCorrect)
        DispatchQueue.main.asyncAfter(deadline: .now() + answerDelay) { [weak self] in
            guard let self else {return}
            self.proceedNextQuestionOrResults()
        }
    }
    
    // MARK: - Quiz Flow
    private func isLastQuestion() -> Bool {
        return currentQuestionIndex == questionsAmount - 1
    }
    private func proceedNextQuestionOrResults() {
        if isLastQuestion() {
            statisticService.store(correct: correctAnswers, total: questionsAmount)
            let bestGame = statisticService.bestGame
            let totalAccuracy = String(format: "%.2f", statisticService.totalAccuracy)
            let resultMessage = """
                         Ваш результат: \(correctAnswers)/\(questionsAmount)
                         Количество сыгранных квизов: \(statisticService.gamesCount)
                         Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGame.date.dateTimeString))
                         Средняя точность: \(totalAccuracy)%
                         """
            let result = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: resultMessage,
                buttonText: "Сыграть ещё раз"
            )
            viewController?.hideLoadingIndicator()
            viewController?.show(quiz: result)
        } else {
            currentQuestionIndex += 1
            questionFactory.requestNextQuestion()
        }
    }
    func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        questionFactory.requestNextQuestion()
    }
    
    // MARK: - QuestionFactoryDelegate Methods
    func didLoadDataFromServer() {
        viewController?.hideLoadingIndicator()
        questionFactory.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        let message: String
        if error is URLError {
            message = "Проверьте подключение к интернету и попробуйте снова."
        } else if let movieError = error as? MovieLoadingError {
            switch movieError {
            case .networkError:
                message = "Ошибка сети. Пожалуйста, попробуйте позже."
            case .apiError(let errorMessage):
                message = "Ошибка сервера: \(errorMessage)"
            case .emptyMoviesList:
                message = "Не удалось загрузить фильмы. Попробуйте позже."
            }
        } else {
            message = "Неизвестная ошибка: \(error.localizedDescription)"
        }
        viewController?.hideLoadingIndicator()
        viewController?.showNetworkError(message: message)
    }
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {return}
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.show(quiz: viewModel)
        }
    }
    
    // MARK: - Helpers
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: model.image ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
}

