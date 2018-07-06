import Foundation

internal class AppContainer: AppContaining {

    private var cached_pseudoTestUserManager: PseudoTest.UserManager?

    internal init() {
    }

    internal var pseudoTestUserManager: PseudoTest.UserManager {
        if let cached = self.cached_pseudoTestUserManager { return cached }
        let pseudoTestUserManager = self.makePseudoTestUserManager()
        self.cached_pseudoTestUserManager = pseudoTestUserManager
        return pseudoTestUserManager
    }

    private func makePseudoTestUserManager() -> PseudoTest.UserManager {
        return PseudoTest.UserManager(appContainer: self)
    }

    internal func injectTo(pseudoTestViewController: PseudoTest.ViewController) {
        pseudoTestViewController.userManager = self.pseudoTestUserManager
    }

}