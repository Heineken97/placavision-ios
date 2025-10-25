import Foundation

public final class MainService {
    private let repository = Repository()
    private let fileHelper = FileHelper()

    public init() {}

    /// Cierra sesión y limpia el usuario actual.
    public func logout() {
        fileHelper.clearCurrentUser()
        print("🔒 Sesión cerrada")
    }

    /// Navega a una sección específica de la app.
    public func navigate(to target: MainTarget) {
        switch target {
        case .login:
            print("➡️ Navegar a Login")
        case .reportPlate:
            print("➡️ Navegar a ReporteDePlaca")
        case .gps:
            print("➡️ Navegar a GpsSuccess")
        case .viewReports:
            print("➡️ Navegar a CasosReportados")
        case .editProfile:
            print("➡️ Navegar a EditProfile")
        case .videoFeed:
            print("➡️ Navegar a VideoFeed")
        }
    }

    public enum MainTarget {
        case login
        case reportPlate
        case gps
        case viewReports
        case editProfile
        case videoFeed
    }
}
