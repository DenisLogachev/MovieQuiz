import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    // MARK: - Outlets
    @IBOutlet weak private var indexLabel: UILabel!
    @IBOutlet weak private var previewImage: UIImageView!
    @IBOutlet weak private var questionLabel: UILabel!
    @IBOutlet weak private var noButton: UIButton!
    @IBOutlet weak private var yesButton: UIButton!
    @IBOutlet weak private var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    private var currentQuestionIndex = 0
    private var correctAnswers = 0
    private let questionsAmount: Int = 10
    private let moviesLoader = MoviesLoader()
    private lazy var questionFactory: QuestionFactoryProtocol = {
        let factory = QuestionFactory(moviesLoader: moviesLoader, delegate: self)
        return factory}()
    private var currentQuestion: QuizQuestion?
    private let alertPresenter = AlertPresenter()
    private lazy var statisticService: StatisticServiceProtocol = StatisticService()
    private let borderWidth: CGFloat = 8.0
    private let answerDelay:TimeInterval = 1.0
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        showLoadingIndicator()
        questionFactory.loadData()
    }
    
    private func setupUI() {
        previewImage.layer.cornerRadius = 20
        previewImage.layer.masksToBounds = true
        yesButton.layer.cornerRadius = 15
        yesButton.layer.masksToBounds = true
        noButton.layer.cornerRadius = 15
        noButton.layer.masksToBounds = true
        activityIndicator.hidesWhenStopped = true
    }
    // MARK: - QuestionFactoryDelegate
    func didReceiveNextQuestion(question: QuizQuestion?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let question = question else {return}
            self.currentQuestion = question
            self.currentQuestionIndex += 1
            let viewModel = self.convert(model: question, index: self.currentQuestionIndex)
            self.show(quiz: viewModel)
            self.setAnswerButtonsState(isEnabled: true)
        }
    }
    
    // MARK: - Private functions
    private func setAnswerButtonsState(isEnabled: Bool) {
        yesButton.isEnabled = isEnabled
        noButton.isEnabled = isEnabled
    }
    private func convert(model: QuizQuestion, index: Int) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: model.image ?? UIImage(),
            question: model.text,
            questionNumber: "\(index)/\(questionsAmount)")
    }
    
    private func show(quiz step: QuizStepViewModel) {
        previewImage.layer.borderWidth = 0
        previewImage.layer.borderColor = UIColor.clear.cgColor
        previewImage.image = step.image
        questionLabel.text = step.question
        indexLabel.text = step.questionNumber
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        DispatchQueue.main.async {[weak self] in
            guard let self else {return}
            self.updateAnswerResult(isCorrect: isCorrect)
            self.previewImage.layer.borderWidth = self.borderWidth
            self.previewImage.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + answerDelay) {[weak self] in
            guard let self else {return}
            self.showNextQuestionOrResults()
        }
    }
    private func updateAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
    }
    
    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questionsAmount - 1 {
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
            
            show(quiz: result)
        } else {
            currentQuestionIndex += 1
            setAnswerButtonsState(isEnabled: true)
            questionFactory.requestNextQuestion()
        }
    }
    
    private func restartQuiz() {
        currentQuestionIndex = 0
        correctAnswers = 0
        previewImage.layer.borderWidth = 0
        questionFactory.requestNextQuestion()
        setAnswerButtonsState(isEnabled: true)
    }
    
    private func handleAnswer(givenAnswer: Bool) {
        guard let currentQuestion = currentQuestion else { return }
        setAnswerButtonsState(isEnabled: false)
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    private func show(quiz result: QuizResultsViewModel) {
        setAnswerButtonsState(isEnabled: false)
        let message = result.text
        let alertModel = AlertModel(
            title: "Этот раунд окончен!",
            message: message,
            buttonText: "Сыграть ещё раз",
            completion: { [weak self] in
                self?.restartQuiz()
            }
        )
        alertPresenter.showAlert(model: alertModel, in: self)
    }
    private func showLoadingIndicator() {
        DispatchQueue.main.async {[weak self] in
            self?.activityIndicator.startAnimating()
        }
    }
    private func showNetworkError(message: String)  {
        DispatchQueue.main.async { [weak self] in
            self?.activityIndicator.stopAnimating()
        }
        let model = AlertModel(title: "Ошибка",
                               message: message,
                               buttonText: "Попробовать еще раз") { [weak self] in
            guard let self = self else { return }
            self.showLoadingIndicator()
            self.questionFactory.loadData()
        }
        alertPresenter.showAlert(model: model, in: self)
    }
    
    func didLoadDataFromServer() {
        stopActivityIndicator()
        questionFactory.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            stopActivityIndicator()
            let message: String
            if let urlError = error as? URLError {
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
            self.showNetworkError(message:message)
        }
    }
    private func stopActivityIndicator() {
        DispatchQueue.main.async {[weak self] in
            self?.activityIndicator.stopAnimating()
            self?.activityIndicator.isHidden = true
        }
    }
    
    // MARK: - Actions
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        handleAnswer(givenAnswer: true)
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        handleAnswer(givenAnswer: false)
    }
}

