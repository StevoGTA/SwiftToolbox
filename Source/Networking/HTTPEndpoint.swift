//
//  HTTPEndpoint.swift
//  Swift Toolbox
//
//  Created by Stevo on 3/23/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: HTTPEndpointMethod
public enum HTTPEndpointMethod {
	case get
	case head
	case patch
	case post
	case put
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: HTTPEndpointStatusError
enum HTTPEndpointStatusError : Error {
	// MARK: Values
	case badRequest
	case unauthorized
	case forbidden
	case notFound
	case conflict

	case internalServerError

	// MARK: Class methods
	static func `for`(_ status :HTTPEndpointStatus) -> Self {
		// Check status
		switch status {
			case .badRequest:			return .badRequest
			case .unauthorized:			return .unauthorized
			case .forbidden:			return .forbidden
			case .notFound:				return .notFound
			case .conflict:				return .conflict

			case .internalServerError:	return .internalServerError

			case .ok:					fatalError("Not an error")
		}
	}
}

extension HTTPEndpointStatusError : LocalizedError {

	// MARK: Properties
	public	var	errorDescription :String? {
						// What are we
						switch self {
							case .badRequest:			return "Bad Requeest"
							case .unauthorized:			return "Unauthorized"
							case .forbidden:				return "Forbidden"
							case .notFound:				return "Not Found"
							case .conflict:				return "Conflict"

							case .internalServerError:	return "Internal Server Error"
						}
					}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HTTPEndpointStatus
public enum HTTPEndpointStatus : Int {
	// Values
	case ok = 200

	case badRequest = 400
	case unauthorized = 401
	case forbidden = 403
	case notFound = 404
	case conflict = 409

	case internalServerError = 500

	// Properties
	var	isSuccess :Bool { return self == .ok }
}
