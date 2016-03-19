import UIKit
import Alamofire

public typealias JSONDictionary = [String: AnyObject]

public protocol AlamofireEndpoint: RawRepresentable {
    typealias RawValue = StringLiteralType
    static var BaseURL: String { get }
}

public enum AlamofireRouter<T: AlamofireEndpoint where T.RawValue == StringLiteralType>: URLRequestConvertible, StringLiteralConvertible {
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public typealias UnicodeScalarLiteralType = StringLiteralType

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

    public var URLRequest: NSMutableURLRequest {
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

    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.init(value)
    }

    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.init(value)
    }
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }

    /**

     ```
     Router<Endpoint>.GET(.Users).responseJSON { (response: [JSONDictionary]?) in

     }
     ```

     */
    public func responseJSON<T>(completion: T -> Void) throws {
        Manager.sharedInstance.request(self).responseJSON { response in
            switch response.result {
            case .Success(let value):
                if let value = value as? T {
                    completion(value)
                }

            case .Failure:
                break
            }
        }
    }
}

public class AlamofireClient<T: AlamofireEndpoint where T.RawValue == StringLiteralType> {
    public typealias Router = AlamofireRouter<T>

    static func request(URLRequest: Router) -> Request {
        return Manager.sharedInstance.request(URLRequest)
    }
}