//
//  Copyright 2016 Lionheart Software LLC
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//

import UIKit
import Alamofire

public enum APIError: Error {
    case unspecified
}

public typealias JSONDictionary = [String: Any]

public enum AlamofireAuthentication {
    case basic(String, String)
    case bearer(String)
    case headers([(name: String, value: String)])
    case none
}

public protocol AlamofireManagerSingleton: class {
    static var sharedManager: SessionManager { get }
}

public protocol AlamofireEndpoint: RawRepresentable {
    associatedtype RawValue = StringLiteralType
    static var BaseURL: String { get }
    static var DefaultContentType: String { get }
    static var CustomManager: AlamofireManagerSingleton.Type? { get }
    var Authentication: AlamofireAuthentication { get }
}

public enum AlamofireRequestParameter: ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public typealias Value = AnyObject

    case json(JSONDictionary)
    case file(Data)
    case body(String)
    case urlParameters(JSONDictionary)
    case contentType(String)
    case header(name: String, value: String)
    case authentication(AlamofireAuthentication)

    public init(dictionaryLiteral elements: (Key, Value)...) {
        var parameters: JSONDictionary = [:]
        for (key, value) in elements {
            parameters[key] = value
        }
        self = .urlParameters(parameters)
    }
}

extension NSMutableURLRequest: URLRequestConvertible {
    public func asURLRequest() throws -> URLRequest {
        return self as URLRequest
    }
}

public enum AlamofireRouter<T: AlamofireEndpoint>: URLRequestConvertible, ExpressibleByStringLiteral where T.RawValue == StringLiteralType {
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public typealias UnicodeScalarLiteralType = StringLiteralType

    case POST(T)
    case GET(T)
    case PATCH(T)
    case HEAD(T)
    case PUT(T)
    case DELETE(T)

    indirect case pattern(AlamofireRouter, [String])
    indirect case methodWithRequestParameters(AlamofireRouter, [AlamofireRequestParameter])

    var endpoint: T {
        switch self {
        case .POST(let endpoint):
            return endpoint

        case .GET(let endpoint):
            return endpoint

        case .PATCH(let endpoint):
            return endpoint

        case .HEAD(let endpoint):
            return endpoint

        case .PUT(let endpoint):
            return endpoint

        case .DELETE(let endpoint):
            return endpoint

        case .methodWithRequestParameters(let method, _):
            return method.endpoint

        case .pattern(let router, _):
            return router.endpoint
        }
    }

    var path: String {
        switch self {
        case .pattern(_, var parameters):
            var path = ""
            for character in endpoint.rawValue {
                if character == Character("?") {
                    let value = parameters.removeFirst()
                    path += String(value)
                } else {
                    character.write(to: &path)
                }
            }
            return path

        case .methodWithRequestParameters(let router, _):
            return router.path

        default:
            return endpoint.rawValue
        }
    }

    var headers: [String: String] {
        var response: [String: String] = [:]
        switch self {
        case .methodWithRequestParameters(_, let requestParameters):
            for parameter in requestParameters {
                if case .header(let name, let value) = parameter {
                    response[name] = value
                }
            }

            return [:]

        case .pattern(let router, _):
            return router.headers

        default:
            return [:]
        }
    }

    var contentType: String {
        switch self {
        case .methodWithRequestParameters(let router, let requestParameters):
            for parameter in requestParameters {
                if case .contentType(let contentType) = parameter {
                    return contentType
                }
            }

            return router.contentType

        case .pattern(let router, _):
            return router.contentType

        default:
            return T.DefaultContentType
        }
    }

    var HTTPMethod: String {
        switch self {
        case .POST:
            return "POST"

        case .GET:
            return "GET"

        case .PATCH:
            return "PATCH"

        case .HEAD:
            return "HEAD"

        case .PUT:
            return "PUT"

        case .DELETE:
            return "DELETE"

        case .methodWithRequestParameters(let router, _):
            return router.HTTPMethod

        case .pattern(let router, _):
            return router.HTTPMethod
        }
    }

    var parameters: JSONDictionary? {
        switch self {
        case .pattern(let router, _):
            return router.parameters

        case .methodWithRequestParameters(_, let requestParameters):
            for parameter in requestParameters {
                switch parameter {
                case .json(let parameters):
                    return parameters

                case .urlParameters(let parameters):
                    return parameters

                default:
                    break
                }
            }
            return nil

        default:
            return nil
        }
    }

    var authentication: AlamofireAuthentication {
        switch self {
        case .methodWithRequestParameters(_, let requestParameters):
            for parameter in requestParameters {
                switch parameter {
                case .authentication(let authentication):
                    return authentication

                default:
                    break
                }
            }

        case .pattern(let router, _):
            return router.authentication

        default:
            break
        }

        return endpoint.Authentication
    }

    @available(*, deprecated: 1.0, message: "No longer in use.")
    var body: String? {
        switch self {
        case .methodWithRequestParameters(_, let requestParameters):
            for parameter in requestParameters {
                switch parameter {
                case .body(let s):
                    return s

                default:
                    break
                }
            }

        default:
            return nil
        }

        return nil
    }

    var encoding: ParameterEncoding {
        switch self {
        case .methodWithRequestParameters(let router, let requestParameters):
            for parameter in requestParameters {
                switch parameter {
                case .json:
                    return JSONEncoding.default

                default:
                    break
                }
            }

            return router.encoding

        case .pattern(let router, _):
            return router.encoding

        default:
            return URLEncoding.default
        }
    }

    public func asURLRequest() throws -> URLRequest {
        var URL = Foundation.URL(string: T.BaseURL)!
        URL = URL.appendingPathComponent(path)
        let request = NSMutableURLRequest(url: URL)

        request.httpMethod = HTTPMethod
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")

        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        switch authentication {
        case .basic(let username, let password):
            // MARK: TODO. Add back dispatch_once
            let credentialData = "\(username):\(password)".data(using: String.Encoding.utf8)!
            let base64Credentials = credentialData.base64EncodedString(options: [])
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
            
        case .headers(let headers):
            for header in headers {
                request.setValue(header.value, forHTTPHeaderField: header.name)
            }

        case .bearer(let token):
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        case .none:
            break
        }

        return try encoding.encode(request, with: parameters)
    }

    public var urlString: String {
        guard let request = try? asURLRequest(),
            let string = request.url?.absoluteString else {
                return ""
        }
        return string
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

    // MARK: -

    public func with(_ parameters: JSONDictionary) -> AlamofireRouter {
        return with(.urlParameters(parameters))
    }

    public func with(_ parameters: AlamofireRequestParameter...) -> AlamofireRouter {
        return with(parameters: parameters)
    }

    public func with(parameters: [AlamofireRequestParameter]) -> AlamofireRouter {
        if case AlamofireRouter.methodWithRequestParameters(let router, var requestParameters) = self {
            requestParameters.append(contentsOf: parameters)
            return AlamofireRouter.methodWithRequestParameters(router, requestParameters)
        } else {
            return AlamofireRouter.methodWithRequestParameters(self, parameters)
        }
    }

    /**

     ```
     Router<Endpoint>.GET(.Users).responseJSON { (response: [JSONDictionary]?) in

     }
     ```
     */
    public func responseJSON<T>(_ success: @escaping (T) -> Void, failure: @escaping (APIError) -> Void) {
        AlamofireClient.request(self).responseJSON { response in
            switch response.result {
            case .success(let value):
                if let value = value as? T {
                    success(value)
                } else {
                    failure(APIError.unspecified)
                }

            case .failure:
                failure(APIError.unspecified)
            }
        }
    }
}

open class AlamofireClient<T: AlamofireEndpoint> where T.RawValue == String {
    public typealias Router = AlamofireRouter<T>

    public static var theManager: SessionManager {
        if let Manager = T.CustomManager {
            return Manager.sharedManager
        } else {
            return SessionManager.default
        }
    }

    public static func upload(_ URLRequest: Router, multipartFormData: @escaping (MultipartFormData) -> Void, completion: @escaping (SessionManager.MultipartFormDataEncodingResult) -> Void) -> Void {
        theManager.upload(multipartFormData: multipartFormData, with: URLRequest, encodingCompletion: completion)
    }

    public static func request(_ URLRequest: Router) -> DataRequest {
        return theManager.request(URLRequest)
    }
}
