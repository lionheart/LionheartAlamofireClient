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

public enum APIError: ErrorType {
    case Unspecified
}

public typealias JSONDictionary = [String: AnyObject]

public enum AlamofireAuthentication {
    case Basic(String, String)
    case Bearer(String)
    case None
}

public protocol AlamofireManagerSingleton: class {
    static var sharedManager: Manager { get }
}

public protocol AlamofireEndpoint: RawRepresentable {
    associatedtype RawValue = StringLiteralType
    static var BaseURL: String { get }
    static var DefaultContentType: String { get }
    static var CustomManager: AlamofireManagerSingleton.Type? { get }
    var Authentication: AlamofireAuthentication { get }
}

public enum AlamofireRequestParameter: DictionaryLiteralConvertible {
    public typealias Key = String
    public typealias Value = AnyObject

    case JSON(JSONDictionary)
    case File(NSData)
    case Body(String)
    case URLParameters(JSONDictionary)
    case ContentType(String)
    case Authentication(AlamofireAuthentication)

    public init(dictionaryLiteral elements: (Key, Value)...) {
        var parameters: JSONDictionary = [:]
        for (key, value) in elements {
            parameters[key] = value
        }
        self = .URLParameters(parameters)
    }
}

public enum AlamofireRouter<T: AlamofireEndpoint where T.RawValue == StringLiteralType>: URLRequestConvertible, StringLiteralConvertible {
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public typealias UnicodeScalarLiteralType = StringLiteralType

    case POST(T)
    case GET(T)
    case PATCH(T)
    case HEAD(T)
    case PUT(T)
    case DELETE(T)

    indirect case Pattern(AlamofireRouter, [String])
    indirect case MethodWithRequestParameters(AlamofireRouter, [AlamofireRequestParameter])

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

        case .MethodWithRequestParameters(let method, _):
            return method.endpoint

        case .Pattern(let router, _):
            return router.endpoint
        }
    }

    var path: String {
        switch self {
        case .Pattern(_, var parameters):
            var path = ""
            for character in endpoint.rawValue.characters {
                if character == Character("?") {
                    let value = parameters.removeFirst()
                    path += String(value)
                }
                else {
                    character.writeTo(&path)
                }
            }
            return path

        case .MethodWithRequestParameters(let router, _):
            return router.path

        default:
            return endpoint.rawValue
        }
    }

    var contentType: String {
        switch self {
        case .MethodWithRequestParameters(let router, let requestParameters):
            for parameter in requestParameters {
                if case .ContentType(let contentType) = parameter {
                    return contentType
                }
            }

            return router.contentType

        case .Pattern(let router, _):
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

        case .MethodWithRequestParameters(let router, _):
            return router.HTTPMethod

        case .Pattern(let router, _):
            return router.HTTPMethod
        }
    }

    var parameters: JSONDictionary? {
        switch self {
        case .Pattern(let router, _):
            return router.parameters

        case .MethodWithRequestParameters(_, let requestParameters):
            for parameter in requestParameters {
                switch parameter {
                case .JSON(let parameters):
                    return parameters

                case .URLParameters(let parameters):
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
        case .MethodWithRequestParameters(_, let requestParameters):
            for parameter in requestParameters {
                switch parameter {
                case .Authentication(let authentication):
                    return authentication

                default:
                    break
                }
            }

        case .Pattern(let router, _):
            return router.authentication

        default:
            break
        }

        return endpoint.Authentication
    }

    @available(*, deprecated=1.0, message="No longer in use.")
    var body: String? {
        switch self {
        case .MethodWithRequestParameters(let router, let requestParameters):
            for parameter in requestParameters {
                switch parameter {
                case .Body(let s):
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
        case .MethodWithRequestParameters(let router, let requestParameters):
            for parameter in requestParameters {
                switch parameter {
                case .JSON:
                    return ParameterEncoding.JSON

                default:
                    break
                }
            }

            return router.encoding

        case .Pattern(let router, _):
            return router.encoding

        default:
            return ParameterEncoding.URL
        }
    }

    public var URLRequest: NSMutableURLRequest {
        var URL = NSURL(string: T.BaseURL)!
        URL = URL.URLByAppendingPathComponent(path)
        let request = NSMutableURLRequest(URL: URL)

        request.HTTPMethod = HTTPMethod
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")

        switch authentication {
        case .Basic(let username, let password):
            var base64Credentials: String!
            var dispatchToken: dispatch_once_t = 0
            dispatch_once(&dispatchToken) {
                let credentialData = "\(username):\(password)".dataUsingEncoding(NSUTF8StringEncoding)!
                base64Credentials = credentialData.base64EncodedStringWithOptions([])
            }
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")

        case .Bearer(let token):
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        case .None:
            break
        }

        let result = encoding.encode(request, parameters: parameters)
        if let error = result.1 {
            fatalError(String(error.code))
        }

        return result.0
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

    public func with(parameters: JSONDictionary) -> AlamofireRouter {
        return with(.URLParameters(parameters))
    }

    public func with(parameters: AlamofireRequestParameter...) -> AlamofireRouter {
        if case AlamofireRouter.MethodWithRequestParameters(let router, var requestParameters) = self {
            requestParameters.appendContentsOf(parameters)
            return AlamofireRouter.MethodWithRequestParameters(router, requestParameters)
        } else {
            return AlamofireRouter.MethodWithRequestParameters(self, parameters)
        }
    }

    /**

     ```
     Router<Endpoint>.GET(.Users).responseJSON { (response: [JSONDictionary]?) in

     }
     ```
     */
    public func responseJSON<T>(success: T -> Void, failure: APIError -> Void) {
        let request = AlamofireClient.request(self).responseJSON { response in
            switch response.result {
            case .Success(let value):
                if let value = value as? T {
                    success(value)
                } else {
                    failure(APIError.Unspecified)
                }

            case .Failure:
                failure(APIError.Unspecified)
            }
        }
    }
}

public class AlamofireClient<T: AlamofireEndpoint where T.RawValue == String> {
    public typealias Router = AlamofireRouter<T>

    static var theManager: Manager {
        if let Manager = T.CustomManager {
            return Manager.sharedManager
        } else {
            return Manager.sharedInstance
        }
    }

    static func upload(URLRequest: Router, multipartFormData: MultipartFormData -> Void, completion: Manager.MultipartFormDataEncodingResult -> Void) -> Void {
        theManager.upload(URLRequest, multipartFormData: multipartFormData, encodingCompletion: completion)
    }

    static func request(URLRequest: Router) -> Request {
        return theManager.request(URLRequest)
    }
}