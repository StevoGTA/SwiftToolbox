//
//  HTTPEndpointHandler.swift
//  Swift Toolbox
//
//  Created by Stevo on 3/23/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: HTTPEndpointError
struct HTTPEndpointError : Error, LocalizedError {

	// MARK: Properties
	static	let	missingBody = HTTPEndpointError(status: .badRequest, message: "Missing body")
	static	let	unableToConvertBodyToJSON = HTTPEndpointError(status: .badRequest, message: "Invalid body")

			let	status :HTTPEndpointStatus
			let	message :String

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func badRequest(with message :String) -> HTTPEndpointError
			{ return HTTPEndpointError(status: .badRequest, message: message) }
	static func unauthorized(with message :String) -> HTTPEndpointError
			{ return HTTPEndpointError(status: .unauthorized, message: message) }
	static func forbidden(with message :String) -> HTTPEndpointError
			{ return HTTPEndpointError(status: .forbidden, message: message) }
	static func notFound(with message :String) -> HTTPEndpointError
			{ return HTTPEndpointError(status: .notFound, message: message) }
	static func conflict(with message :String) -> HTTPEndpointError
			{ return HTTPEndpointError(status: .conflict, message: message) }

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(status :HTTPEndpointStatus, message :String) {
		// Store
		self.status = status
		self.message = message
	}

	// MARK: LocalizedError implementation
	var	errorDescription :String? { return "\(self.status): \(self.message)" }
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HTTPEndpointResponseBody
public enum HTTPEndpointResponseBody {

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
// MARK: - HTTPEndpoint
public protocol HTTPEndpoint {

	// MARK: Types
	typealias PerformResult =
				(status :HTTPEndpointStatus, headers :[(String, String)]?, responseBody :HTTPEndpointResponseBody?)

	// MARK: Properties
	var	method :HTTPEndpointMethod { get }
	var	path :String { get }

	// MARK: Instance methods
	func perform(urlComponents :URLComponents, headers :[String : String], bodyData :Data?) throws -> PerformResult
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - BasicHTTPEndpoint
public struct BasicHTTPEndpoint<T> : HTTPEndpoint {

	// MARK: Types
	public typealias ValidateProc = (_ urlComponents :URLComponents, _ headers :[String : String]) throws -> T
	public typealias PerformProc = (_ info :T) throws -> PerformResult

	// MARK: Properties
	public let	method :HTTPEndpointMethod
	public let	path :String

	public let	validateProc :ValidateProc

	public var	performProc :PerformProc!

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(method :HTTPEndpointMethod, path :String, validateProc :@escaping ValidateProc) {
		// Store
		self.method = method
		self.path = path

		self.validateProc = validateProc
	}

	// MARK: HTTPEndpoint implementation
	//------------------------------------------------------------------------------------------------------------------
	public func perform(urlComponents :URLComponents, headers :[String : String], bodyData :Data?) throws ->
			PerformResult {
		// Perform
		let	info = try self.validateProc(urlComponents, headers)

		return try self.performProc(info)
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - DataHTTPEndpoint
public struct DataHTTPEndpoint<T> :HTTPEndpoint {

	// MARK: Types
	public typealias ValidateProc =
				(_ urlComponents :URLComponents, _ headers :[String : String], _ bodyData :Data) throws -> T
	public typealias PerformProc = (_ info :T) throws -> PerformResult

	// MARK: Properties
	public let	method :HTTPEndpointMethod
	public let	path :String

	public let	validateProc :ValidateProc

	public var	performProc :PerformProc!

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(method :HTTPEndpointMethod, path :String, validateProc :@escaping ValidateProc) {
		// Store
		self.method = method
		self.path = path

		// Store
		self.validateProc = validateProc
	}

	// MARK: HTTPEndpoint implementation
	//------------------------------------------------------------------------------------------------------------------
	public func perform(urlComponents :URLComponents, headers :[String : String], bodyData :Data?) throws ->
			PerformResult {
		// Validate
		guard bodyData != nil else { throw HTTPEndpointError.missingBody }

		// Perform
		let	info = try self.validateProc(urlComponents, headers, bodyData!)

		return try self.performProc(info)
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - JSONHTTPEndpoint
public struct JSONHTTPEndpoint<T, U> :HTTPEndpoint {

	// MARK: Types
	public typealias ValidateProc =
				(_ urlComponents :URLComponents, _ headers :[String : String], _ info :T) throws -> U
	public typealias PerformProc = (_ info :U) throws -> PerformResult

	// MARK: Properties
	public let	method :HTTPEndpointMethod
	public let	path :String

	public let	validateProc :ValidateProc

	public var	performProc :PerformProc!

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(method :HTTPEndpointMethod, path :String, validateProc :@escaping ValidateProc) {
		// Store
		self.method = method
		self.path = path

		// Store
		self.validateProc = validateProc
	}

	// MARK: HTTPEndpoint implementation
	//------------------------------------------------------------------------------------------------------------------
	public func perform(urlComponents :URLComponents, headers :[String : String], bodyData :Data?) throws ->
			PerformResult {
		// Validate
		guard bodyData != nil else { throw HTTPEndpointError.missingBody }
		guard let json = try? JSONSerialization.jsonObject(with: bodyData!, options: []) as? T else
				{ throw HTTPEndpointError.unableToConvertBodyToJSON }

		// Perform
		let	info = try self.validateProc(urlComponents, headers, json)

		return try self.performProc(info)
	}
}
