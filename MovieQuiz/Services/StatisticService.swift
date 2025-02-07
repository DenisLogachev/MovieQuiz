import Foundation

final class StatisticService: StatisticServiceProtocol {
    private let storage: UserDefaults = .standard
    private enum Keys: String {
        case correctAnswers
        case bestGame
        case totalQuestions
        case gamesCount
    }
    
    var gamesCount: Int {
        get { storage.integer(forKey: Keys.gamesCount.rawValue) }
        set { storage.set(newValue, forKey: Keys.gamesCount.rawValue) }
    }
    
    var bestGame: GameResult {
        get {
            guard let data = storage.data(forKey: Keys.bestGame.rawValue),
                  let bestGame = try? JSONDecoder().decode(GameResult.self, from: data) else {
                return GameResult(correct: 0, total: 0, date: Date())
            }
            return bestGame
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                storage.set(data, forKey: Keys.bestGame.rawValue)
            }
        }
    }
    
    var totalAccuracy: Double {
        let totalQuestions = storage.integer(forKey: Keys.totalQuestions.rawValue)
        guard totalQuestions > 0 else { return 0.0 }
        let accuracy = (Double(correctAnswers) / Double(totalQuestions)) * 100
        return round(accuracy * 100) / 100
    }
    
    var correctAnswers: Int {
        storage.integer(forKey: Keys.correctAnswers.rawValue)
    }
    
    func store(correct count: Int, total amount: Int) {
        let currentGamesCount = gamesCount + 1
        let currentCorrectAnswers = correctAnswers + count
        let currentTotalQuestions = storage.integer(forKey: Keys.totalQuestions.rawValue) + amount
        
        storage.set(currentGamesCount, forKey: Keys.gamesCount.rawValue)
        storage.set(currentCorrectAnswers, forKey: Keys.correctAnswers.rawValue)
        storage.set(currentTotalQuestions, forKey: Keys.totalQuestions.rawValue)
        
        let newGame = GameResult(correct: count, total: amount, date: Date())
        if newGame.isBetterThan(bestGame), let data = try? JSONEncoder().encode(newGame) {
            storage.set(data, forKey: Keys.bestGame.rawValue)
        }
    }
}


