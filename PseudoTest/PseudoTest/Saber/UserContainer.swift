import Foundation

internal class UserContainer: UserContaining {

    internal unowned let appContainer: AppContainer

    internal let userData: UserData

    internal init(appContainer: AppContainer, userData: UserData) {
        self.appContainer = appContainer
        self.userData = userData
    }

    internal var userVC: UserVC {
        let userVC = self.makeUserVC()
        return userVC
    }

    private func makeUserVC() -> UserVC {
        return UserVC(user: self.userData.user)
    }

}