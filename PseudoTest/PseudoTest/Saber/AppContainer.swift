import Foundation

internal class AppContainer: AppContaining {

    internal init() {
    }

    internal var userManager: UserManager {
        let userManager = self.makeUserManager()
        return userManager
    }

    private func makeUserManager() -> UserManager {
        return UserManager()
    }

}