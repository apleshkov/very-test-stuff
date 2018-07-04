import Foundation

internal class UserContainer: UserContaining {

    internal unowned let appContainer: AppContainer

    internal init(appContainer: AppContainer) {
        self.appContainer = appContainer
    }

}