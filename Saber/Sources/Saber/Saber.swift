enum Saber {}

public struct SaberConfiguration {

    public var accessLevel = "internal"
    
    public var indent = "    "

    public var header: String? = nil
    
    public init() {}
}

extension SaberConfiguration {

    public static let `default` = SaberConfiguration()
}
