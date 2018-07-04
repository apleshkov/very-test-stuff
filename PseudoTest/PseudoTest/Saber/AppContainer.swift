import Foundation

internal class AppContainer: AppContaining {

    private var cached_userManager: UserManager?

    internal init() {
    }

    internal var userManager: UserManager {
        if let cached = self.cached_userManager { return cached }
        let userManager = self.makeUserManager()
        self.cached_userManager = userManager
        return userManager
    }

    private func makeUserManager() -> UserManager {
        return UserManager(appContainer: self)
    }

    internal func injectTo(viewController: ViewController) {
        viewController.userManager = self.userManager
    }

}