import XCTest
@testable import Placavision

final class MainServiceTests: XCTestCase {
    func testCheckInitialState_defaultsToLogin() {
        // Ensure no token and no current user
        let fh = FileHelper()
        fh.clearUsersFile()
        fh.clearCurrentUser()
        let svc = MainService()
        XCTAssertEqual(svc.checkInitialState(), MainService.MainTarget.login)
    }

    func testLogout_clearsCurrentUser() {
        let fh = FileHelper()
        fh.clearUsersFile()
        fh.saveUser(User(correo: "a@b.com", contrasena: "", nombre_usuario: nil, identificador_nacional: nil, telefono: nil, role: nil))
        fh.setCurrentUser("a@b.com")

        let svc = MainService()
        let exp = expectation(description: "logout")
        svc.logout { result in
            switch result {
            case .success(let msg):
                XCTAssertTrue(msg.contains("Sesión"))
            case .failure:
                XCTFail("Logout should succeed")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        XCTAssertNil(fh.getCurrentUser())
    }
}
