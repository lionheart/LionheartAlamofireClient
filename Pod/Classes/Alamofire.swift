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

public protocol Number {}
extension Int: Number {}
extension Float: Number {}
extension Double: Number {}

public protocol JSONDataTypeType {}

indirect public enum JSONDataType: JSONDataTypeType {
    case number(Number)
    case string(String)
    case bool(Bool)
    case null
    case array([JSONDataType])
    case object([String: JSONDataType])

    public var unwrapped: Any? {
        switch self {
        case .number(let value): return value
        case .string(let value): return value
        case .bool(let value): return value
        case .null: return nil
        case .array(let values): return values.map { $0.unwrapped }
        case .object(let elements):
            var dict: [String: Any] = [:]
            for (key, value) in elements {
                dict[key] = value.unwrapped
            }
            return dict
        }
    }

    mutating func set(value: Any, forKey key: String) {
        guard case .object(var object) = self else { return }

        if let value = value as? String {
            object[key] = .string(value)
        } else if let value = value as? Bool {
            object[key] = .bool(value)
        } else if let value = value as? Number {
            object[key] = .number(value)
        } else if let value = value as? JSONDataType {
            object[key] = value
        } else if let values = value as? [JSONDataType] {
            object[key] = .array(values)
        } else {
            object[key] = .null
        }

        self = .object(object)
    }

    func get(key: String) -> JSONDataType {
        guard case .object(let object) = self else { return .null }
        return object[key] ?? .null
    }

    func get<T>(key: String) -> T? {
        let value: JSONDataType = get(key: key)
        switch value {
        case .number(let number): return number as? T
        case .bool(let bool): return bool as? T
        case .string(let string): return string as? T
        case .array(let values): return values as? T
        case .object(let object): return object as? T
        case .null: return nil
        }
    }

    public subscript(key: String) -> JSONDataType {
        set { set(value: newValue, forKey: key) }
        get { return get(key: key) }
    }

    public subscript(key: String) -> String? {
        set { set(value: newValue, forKey: key) }
        get { return get(key: key) }
    }

    public subscript(key: String) -> Bool? {
        set { set(value: newValue, forKey: key) }
        get { return get(key: key) }
    }

    public subscript(key: String) -> Number? {
        set { set(value: newValue, forKey: key) }
        get { return get(key: key) }
    }

    public init(_ value: Int?) {
        if let value = value {
            self = .number(value)
        } else {
            self = .null
        }
    }

    public init(_ value: String?) {
        if let value = value {
            self = .string(value)
        } else {
            self = .null
        }
    }

    public init(_ value: Bool?) {
        if let value = value {
            self = .bool(value)
        } else {
            self = .null
        }
    }
}

extension JSONDataType: ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public typealias Value = Any

    public init(dictionaryLiteral elements: (Key, Value)...) {
        var params: JSONDataType = .object([:])
        for (key, value) in elements {
            params.set(value: value, forKey: key)
        }
        self = params
    }
}

// MARK: -

public enum AlamofireAuthentication {
    case basic(String, String)
    case bearer(String)
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

    case json(JSONDataType)
    case file(Data)
    case body(String)
    case urlParameters(Parameters)
    case contentType(String)
    case authentication(AlamofireAuthentication)

    public init(dictionaryLiteral elements: (Key, Value)...) {
        var parameters: Parameters = [:]
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

    case post(T)
    case get(T)
    case patch(T)
    case head(T)
    case put(T)
    case delete(T)

    indirect case pattern(AlamofireRouter, [String])
    indirect case methodWithRequestParameters(AlamofireRouter, [AlamofireRequestParameter])

    var endpoint: T {
        switch self {
        case .post(let endpoint):
            return endpoint

        case .get(let endpoint):
            return endpoint

        case .patch(let endpoint):
            return endpoint

        case .head(let endpoint):
            return endpoint

        case .put(let endpoint):
            return endpoint

        case .delete(let endpoint):
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
            for character in endpoint.rawValue.characters {
                if character == Character("?") {
                    let value = parameters.removeFirst()
                    path += String(value)
                }
                else {
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
        case .post:
            return "POST"

        case .get:
            return "GET"

        case .patch:
            return "PATCH"

        case .head:
            return "HEAD"

        case .put:
            return "PUT"

        case .delete:
            return "DELETE"

        case .methodWithRequestParameters(let router, _):
            return router.HTTPMethod

        case .pattern(let router, _):
            return router.HTTPMethod
        }
    }

    var parameters: Parameters? {
        switch self {
        case .pattern(let router, _):
            return router.parameters

        case .methodWithRequestParameters(_, let requestParameters):
            for parameter in requestParameters {
                switch parameter {
                case .json(let parameters):
                    if case .object(let value) = parameters {
                        // MARK: TODO Might want to just return unwrapped here for the main object.
                        var params: Parameters = [:]
                        for (key, value) in value {
                            params[key] = value.unwrapped
                        }
                        return params
                    }

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

        switch authentication {
        case .basic(let username, let password):
            var base64Credentials: String!
            // MARK: TODO. Add back dispatch_once
            let credentialData = "\(username):\(password)".data(using: String.Encoding.utf8)!
            base64Credentials = credentialData.base64EncodedString(options: [])
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")

        case .bearer(let token):
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        case .none:
            break
        }

        return try! encoding.encode(request, with: parameters)
    }

    public var urlString: String {
        guard let request = try? asURLRequest(),
            let string = request.url?.absoluteString else {
                return ""
        }
        return string
    }

    init(_ stringValue: String) {
        self = .get(T(rawValue: stringValue)!)
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

    public func with(_ parameters: Parameters) -> AlamofireRouter {
        return with(.urlParameters(parameters))
    }

    public func with(_ parameters: AlamofireRequestParameter...) -> AlamofireRouter {
        if case AlamofireRouter.methodWithRequestParameters(let router, var requestParameters) = self {
            requestParameters.append(contentsOf: parameters)
            return AlamofireRouter.methodWithRequestParameters(router, requestParameters)
        } else {
            return AlamofireRouter.methodWithRequestParameters(self, parameters)
        }
    }

    /**

     ```
     Router<Endpoint>.GET(.Users).responseJSON { (response: [Parameters]?) in

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

    open static var theManager: SessionManager {
        if let Manager = T.CustomManager {
            return Manager.sharedManager
        } else {
            return SessionManager.default
        }
    }
    
    open static func upload(_ URLRequest: Router, multipartFormData: @escaping (MultipartFormData) -> Void, completion: @escaping (SessionManager.MultipartFormDataEncodingResult) -> Void) -> Void {
        theManager.upload(multipartFormData: multipartFormData, with: URLRequest, encodingCompletion: completion)
    }
    
    open static func request(_ URLRequest: Router) -> DataRequest {
        return theManager.request(URLRequest)
    }
}
