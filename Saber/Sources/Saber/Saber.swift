enum Saber {}

public struct SaberConfiguration {

    public var indent: String = "    "

    public var header: String? = nil

    public init() {}
}

extension SaberConfiguration {

    public static let `default` = SaberConfiguration()
}
