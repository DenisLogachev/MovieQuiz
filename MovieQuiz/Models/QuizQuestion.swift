import Foundation
import UIKit

struct QuizQuestion {
    let imageData: Data
    let text: String
    let correctAnswer: Bool
    
    var image: UIImage? {
        return UIImage (data: imageData)
    }
}
