import Foundation

protocol StatisticServiceProtocol {
    var gamesCount: Int { get }
    var totalAccuracy: Double { get }
    var bestGame: GameResult { get }
    
    func store(correct count: Int, total amount: Int)
}

