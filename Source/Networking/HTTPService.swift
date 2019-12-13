//
//  HTTPService.swift
//  Media Tools
//
//  Created by Stevo on 11/30/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: HTTPServiceMethod
enum HTTPServiceMethod {
	case get
	case head
	case patch
	case post
	case put
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HTTPServiceResponseBody
enum HTTPServiceResponseBody {

	// MARK: Values
	case data(_ value :Data)
	case integer(_ value :Int)
	case json(_ value :Any)
	case string(_ value :String)

	// MARK: Properties
	var	data :Data {
		// Check value
		switch self {
			case .data(let value):		return value
			case .integer(let value):	return "\(value)".data(using: .utf8)!
			case .json(let value):		return try! JSONSerialization.data(withJSONObject: value, options: [])
			case .string(let value):	return value.data(using: .utf8)!
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HTTPServiceStatus
enum HTTPServiceStatus : UInt {
	case ok = 200

	case badRequest = 400
	case unauthorized = 401
	case forbidden = 403
	case notFound = 404
	case conflict = 409
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HTTPServiceError
struct HTTPServiceError : Error, LocalizedError {

	// MARK: LocalizedError implementation
	var	errorDescription :String? { return "\(self.status): \(self.message)" }

	// MARK: Properties
	static	let	missingBody = HTTPServiceError(status: .badRequest, message: "Missing body")
	static	let	unableToConvertBodyToJSON = HTTPServiceError(status: .badRequest, message: "Invalid body")

			let	status :HTTPServiceStatus
			let	message :String

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func badRequest(with message :String) -> HTTPServiceError
			{ return HTTPServiceError(status: .badRequest, message: message) }
	static func unquthorized(with message :String) -> HTTPServiceError
			{ return HTTPServiceError(status: .unauthorized, message: message) }
	static func forbidden(with message :String) -> HTTPServiceError
			{ return HTTPServiceError(status: .forbidden, message: message) }
	static func notFound(with message :String) -> HTTPServiceError
			{ return HTTPServiceError(status: .notFound, message: message) }
	static func conflict(with message :String) -> HTTPServiceError
			{ return HTTPServiceError(status: .conflict, message: message) }

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(status :HTTPServiceStatus, message :String) {
		// Store
		self.status = status
		self.message = message
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HTTPService
protocol HTTPService {

	// MARK: Types
	typealias PerformResult =
				(status :HTTPServiceStatus, headers :[(String, String)], responseBody :HTTPServiceResponseBody?)

	// MARK: Properties
	var	method :HTTPServiceMethod { get }
	var	path :String { get }

	// MARK: Instance methods
	func perform(urlComponents :URLComponents, headers :[String : String], bodyData :Data?) throws -> PerformResult
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - BasicHTTPService
struct BasicHTTPService<T> : HTTPService {

	// MARK: HTTPService implementation
	let	method :HTTPServiceMethod
	let	path :String

	func perform(urlComponents :URLComponents, headers :[String : String], bodyData :Data?) throws -> PerformResult {
		// Perform
		let	info = try self.validateProc(urlComponents, headers)

		return try self.performProc(info)
	}

	// MARK: Types
	typealias ValidateProc = (_ urlComponents :URLComponents, _ headers :[String : String]) throws -> T
	typealias PerformProc = (_ info :T) throws -> PerformResult

	// MARK: Properties
	let	validateProc :ValidateProc

	var	performProc :PerformProc!

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(method :HTTPServiceMethod, path :String, validateProc :@escaping ValidateProc) {
		// Store
		self.method = method
		self.path = path

		self.validateProc = validateProc
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - DataHTTPService
struct DataHTTPService<T> :HTTPService {

	// MARK: HTTPService implementation
	let	method :HTTPServiceMethod
	let	path :String

	func perform(urlComponents :URLComponents, headers :[String : String], bodyData :Data?) throws -> PerformResult {
		// Validate
		guard bodyData != nil else { throw HTTPServiceError.missingBody }

		// Perform
		let	info = try self.validateProc(urlComponents, headers, bodyData!)

		return try self.performProc(info)
	}

	// MARK: Types
	typealias ValidateProc =
				(_ urlComponents :URLComponents, _ headers :[String : String], _ bodyData :Data) throws -> T
	typealias PerformProc = (_ info :T) throws -> PerformResult

	// MARK: Properties
	let	validateProc :ValidateProc

	var	performProc :PerformProc!

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(method :HTTPServiceMethod, path :String, validateProc :@escaping ValidateProc) {
		// Store
		self.method = method
		self.path = path

		// Store
		self.validateProc = validateProc
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - JSONHTTPService
struct JSONHTTPService<T, U> :HTTPService {

	// MARK: HTTPService implementation
	let	method :HTTPServiceMethod
	let	path :String

	func perform(urlComponents :URLComponents, headers :[String : String], bodyData :Data?) throws -> PerformResult {
		// Validate
		guard bodyData != nil else { throw HTTPServiceError.missingBody }
		guard let json = try? JSONSerialization.jsonObject(with: bodyData!, options: []) as? T else
				{ throw HTTPServiceError.unableToConvertBodyToJSON }

		// Perform
		let	info = try self.validateProc(urlComponents, headers, json!)

		return try self.performProc(info)
	}

	// MARK: Types
	typealias ValidateProc = (_ urlComponents :URLComponents, _ headers :[String : String], _ info :T) throws -> U
	typealias PerformProc = (_ info :U) throws -> PerformResult

	// MARK: Properties
	let	validateProc :ValidateProc

	var	performProc :PerformProc!

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(method :HTTPServiceMethod, path :String, validateProc :@escaping ValidateProc) {
		// Store
		self.method = method
		self.path = path

		// Store
		self.validateProc = validateProc
	}
}
