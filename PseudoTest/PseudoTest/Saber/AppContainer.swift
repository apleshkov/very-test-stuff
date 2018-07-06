import Foundation

internal class AppContainer: AppContaining {

    private var cached_userManager: PseudoTest.UserManager?

    internal init() {
    }

    internal var userManager: PseudoTest.UserManager {
        if let cached = self.cached_userManager { return cached }
        let userManager = self.makeUserManager()
        self.cached_userManager = userManager
        return userManager
    }

    private func makeUserManager() -> PseudoTest.UserManager {
        return PseudoTest.UserManager(appContainer: self)
    }

    internal func injectTo(viewController: PseudoTest.ViewController) {
        viewController.userManager = self.userManager
    }

}