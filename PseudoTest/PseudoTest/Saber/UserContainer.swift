import Foundation

internal class UserContainer: UserContaining {

    internal unowned let appContainer: PseudoTest.AppContainer

    internal let userData: PseudoTest.UserData

    internal init(appContainer: PseudoTest.AppContainer, userData: PseudoTest.UserData) {
        self.appContainer = appContainer
        self.userData = userData
    }

    internal var userVC: PseudoTest.UserVC {
        let userVC = self.makeUserVC()
        return userVC
    }

    private func makeUserVC() -> PseudoTest.UserVC {
        return PseudoTest.UserVC(user: self.userData.user)
    }

}