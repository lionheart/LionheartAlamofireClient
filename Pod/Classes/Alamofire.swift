import UIKit
import Alamofire

typealias JSONDictionary = [String: AnyObject]

protocol EndpointEnum: RawRepresentable {
    typealias RawValue = StringLiteralType
    static var BaseURL: String { get }
}

enum APIRouter<T: EndpointEnum where T.RawValue == StringLiteralType>: URLRequestConvertible, StringLiteralConvertible {
    typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    typealias UnicodeScalarLiteralType = StringLiteralType

    case POST(T, parameters: JSONDictionary?)
    case POSTJSON(T, JSONDictionary)
    case GET(T)
    case GETParameters(T, JSONDictionary)

    var endpoint: T {
        switch self {
        case .POST(let endpoint, _):
            return endpoint

        case .GET(let endpoint):
            return endpoint

        case .GETParameters(let endpoint, _):
            return endpoint

        case .POSTJSON(let endpoint, _):
            return endpoint
        }
    }

    var HTTPMethod: String {
        switch self {
        case .POST, .POSTJSON:
            return "POST"

        case .GET, .GETParameters:
            return "GET"
        }
    }

    var parameters: JSONDictionary? {
        switch self {
        case .POST(_, let parameters):
            return parameters

        case .GET(_):
            return nil

        case .GETParameters(_, let parameters):
            return parameters

        case .POSTJSON(_, let parameters):
            return parameters
        }
    }

    var encoding: ParameterEncoding {
        switch self {
        case .POST, .GET, .GETParameters:
            return ParameterEncoding.URL

        case .POSTJSON:
            return ParameterEncoding.JSON
        }
    }

    var URLRequest: NSMutableURLRequest {
        var URL = NSURL(string: T.self.BaseURL)!
        URL = URL.URLByAppendingPathComponent(endpoint.rawValue)
        let request = NSMutableURLRequest(URL: URL)

        request.HTTPMethod = HTTPMethod
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return encoding.encode(request, parameters: parameters).0
    }

    init(_ stringValue: String) {
        self = .GET(T(rawValue: stringValue)!)
    }

    init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.init(value)
    }

    init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.init(value)
    }
    
    init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
}
