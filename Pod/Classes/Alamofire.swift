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

public protocol JSONDataTypeType {
    var unwrapped: AnyObject? { get }
}

public extension Array where Element: JSONDataTypeType {
    var unwrapped: [AnyObject] {
        return map({ $0.unwrapped }).flatMap { $0 }
    }
}

indirect public enum JSONDataType: JSONDataTypeType {
    case number(Number)
    case string(String)
    case bool(Bool)
    case date(Date)
    case null
    case array([JSONDataType])
    case dictionary([String: JSONDataType])
    case unknown(Any)

    public var unwrapped: AnyObject? {
        switch self {
        case .number(let value):
            if let value = value as? Int {
                return NSNumber(value: value)
            } else if let value = value as? Float {
                return NSNumber(value: value)
            } else if let value = value as? Double {
                return NSNumber(value: value)
            } else {
                return nil
            }

        case .string(let value): return NSString(string: value)
        case .bool(let value): return NSNumber(value: value)
        case .date(let value): return NSDate(timeIntervalSince1970: value.timeIntervalSince1970)
        case .null: return nil
        case .array(let values): return NSArray(array: values.map({ $0.unwrapped }).flatMap({ $0 }))
        case .dictionary(let elements):
            var dict = NSMutableDictionary()
            for (key, value) in elements {
                guard let unwrapped = value.unwrapped else {
                    continue
                }

                dict[key] = unwrapped
            }
            return dict

        case .unknown(let value): return value as AnyObject?
        }
    }

    mutating func set(value: JSONDataType, forKey key: String) {
        guard case .dictionary(var object) = self else { return }
        object[key] = value
        self = .dictionary(object)
    }

    func get(key: String) -> JSONDataType {
        guard case .dictionary(let object) = self else { return .null }
        return object[key] ?? .null
    }

    func get<T>(key: String) -> T? {
        let value: JSONDataType = get(key: key)
        switch value {
        case .number(let number): return number as? T
        case .bool(let bool): return bool as? T
        case .date(let date): return date as? T
        case .string(let string): return string as? T
        case .array(let values): return values as? T
        case .dictionary(let object): return object as? T
        case .null: return nil
        case .unknown(let value): return value as? T
        }
    }

    public subscript(key: String) -> JSONDataType {
        set { set(value: newValue, forKey: key) }
        get { return get(key: key) }
    }

    public subscript(key: String) -> [AnyObject]? {
        set { newValue.flatMap { set(value: JSONDataType($0), forKey: key) } }
        get { return get(key: key) }
    }

    public subscript(key: String) -> [String: AnyObject?]? {
        set { newValue.flatMap { set(value: JSONDataType($0), forKey: key) } }
        get { return get(key: key) }
    }

    public subscript(key: String) -> String? {
        set { set(value: JSONDataType(newValue), forKey: key) }
        get { return get(key: key) }
    }

    public subscript(key: String) -> Date? {
        set { set(value: JSONDataType(newValue), forKey: key) }
        get { return get(key: key) }
    }

    public subscript(key: String) -> Bool? {
        set { set(value: JSONDataType(newValue), forKey: key) }
        get { return get(key: key) }
    }

    public subscript(key: String) -> Int? {
        set { set(value: JSONDataType(newValue), forKey: key) }
        get { return get(key: key) }
    }

    public subscript(key: String) -> Float? {
        set { set(value: JSONDataType(newValue), forKey: key) }
        get { return get(key: key) }
    }

    public subscript(key: String) -> Double? {
        set { set(value: JSONDataType(newValue), forKey: key) }
        get { return get(key: key) }
    }

    public init(_ value: Any) {
        guard let value = value as AnyObject? else {
            self.init()
            return
        }

        if let value = value as? Int {
            self.init(value)
        } else if let value = value as? Float {
            self.init(value)
        } else if let value = value as? Double {
            self.init(value)
        } else if let value = value as? String {
            self.init(value)
        } else if let value = value as? Bool {
            self.init(value)
        } else if let value = value as? Date {
            self.init(value)
        } else if let values = value as? [AnyObject] {
            self.init(values)
        } else if let elements  = value as? [String: AnyObject?] {
            self.init(elements)
        } else {
            self.init(unknown: value)
        }
    }

    public init(unknown value: Any) {
        self = .unknown(value)
    }

    public init(_ elements: [String: AnyObject?]) {
        var params: [String: JSONDataType] = [:]
        for (key, value) in elements {
            params[key] = JSONDataType(value)
        }
        self = .dictionary(params)
    }

    public init(_ elements: [AnyObject]) {
        self = .array(elements.map({ JSONDataType($0) }))
    }

    public init(_ value: Bool) {
        self = .bool(value)
    }

    public init(_ value: Int) {
        self = .number(value)
    }

    public init(_ value: Float) {
        self = .number(value)
    }

    public init(_ value: Double) {
        self = .number(value)
    }

    public init(_ value: Date) {
        self = .date(value)
    }

    public init(_ value: String) {
        self = .string(value)
    }

    public init() {
        self = .null
    }
}

extension JSONDataType: ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public typealias Value = Any

    public init(dictionaryLiteral elements: (Key, Value)...) {
        var params: JSONDataType = .dictionary([:])
        for (key, value) in elements {
            if let value = value as? AnyObject {
                params[key] = JSONDataType(value)
            } else {
                params[key] = .null
            }
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
    public typealias Value = Any

    case json(Parameters)
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
                case .json(let parameters), .urlParameters(let parameters):
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

        let p = parameters
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
