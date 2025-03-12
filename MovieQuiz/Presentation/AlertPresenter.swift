import Foundation
import UIKit

final class AlertPresenter {
    func showAlert (model: AlertModel, in viewController: UIViewController) {
        let alert = UIAlertController(
            title: model.title,
            message: model.message,
            preferredStyle: .alert)
        let action = UIAlertAction(title: model.buttonText, style: .default) { _ in
            model.completion?()
        }
        alert.addAction(action)
        alert.view.accessibilityIdentifier = "Game results"
        viewController.present(alert, animated: true, completion: nil)
    }
}
