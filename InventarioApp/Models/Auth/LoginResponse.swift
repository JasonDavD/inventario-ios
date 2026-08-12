import Foundation

struct LoginResponse: Decodable {
    let token: String
    let tokenType: String
    let username: String
    let roles: [String]
}
