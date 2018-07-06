import Foundation

internal class UserContainer: UserContaining {

    internal unowned let pseudoTestAppContainer: PseudoTest.AppContainer

    internal let pseudoTestUserData: PseudoTest.UserData

    internal init(pseudoTestAppContainer: PseudoTest.AppContainer, pseudoTestUserData: PseudoTest.UserData) {
        self.pseudoTestAppContainer = pseudoTestAppContainer
        self.pseudoTestUserData = pseudoTestUserData
    }

    internal var pseudoTestUserVC: PseudoTest.UserVC {
        let pseudoTestUserVC = self.makePseudoTestUserVC()
        return pseudoTestUserVC
    }

    private func makePseudoTestUserVC() -> PseudoTest.UserVC {
        return PseudoTest.UserVC(user: self.pseudoTestUserData.user)
    }

}