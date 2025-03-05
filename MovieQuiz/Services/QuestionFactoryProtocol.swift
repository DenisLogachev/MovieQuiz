import Foundation

protocol QuestionFactoryProtocol {
    func setup(delegate: QuestionFactoryDelegate)
    func requestNextQuestion()
    //func resetQuestions()
    func loadData() 
}
