//
//  HTTPEndpointRequest.swift
//  Swift Toolbox
//
//  Created by Stevo on 12/5/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: HTTPEndpointRequestError
enum HTTPEndpointRequestError : Error {
	case unableToProcessResponseData
}

extension HTTPEndpointRequestError : LocalizedError {

	// MARK: Properties
	public	var	errorDescription :String? {
						// What are we
						switch self {
							case .unableToProcessResponseData:	return "Unable to process response data"
						}
					}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: HTTPEndpointRequest
class HTTPEndpointRequest {

	// MARK: Types
	enum State {
		case queued
		case active
		case finished
	}

	// MARK: Properties
					let	method :HTTPEndpointMethod
					let	path :String
					let	queryParameters :[String : Any]?
					let	headers :[String : String]?
					let	timeoutInterval :TimeInterval
					let	bodyData :Data?

	private(set)	var	state :State = .queued
	private(set)	var	isCancelled = false

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(method :HTTPEndpointMethod, path :String, queryParameters :[String : Any]? = nil,
			headers :[String : String]? = nil, timeoutInterval :TimeInterval = 60.0) {
		// Store
		self.method = method
		self.path = path
		self.queryParameters = queryParameters
		self.headers = headers
		self.timeoutInterval = timeoutInterval
		self.bodyData = nil
	}

	//------------------------------------------------------------------------------------------------------------------
	init(method :HTTPEndpointMethod, path :String, queryParameters :[String : Any]? = nil,
			headers :[String : String]? = nil, timeoutInterval :TimeInterval = 60.0, bodyData :Data) {
		// Store
		self.method = method
		self.path = path
		self.queryParameters = queryParameters
		self.headers = headers
		self.timeoutInterval = timeoutInterval
		self.bodyData = bodyData
	}

	//------------------------------------------------------------------------------------------------------------------
	init(method :HTTPEndpointMethod, path :String, queryParameters :[String : Any]? = nil,
			headers :[String : String]? = nil, timeoutInterval :TimeInterval = 60.0, jsonBody :Any) {
		// Setup
		var	headersUse = headers ?? [:]
		headersUse["Content-Type"] = "application/json"

		// Store
		self.method = method
		self.path = path
		self.queryParameters = queryParameters
		self.headers = headersUse
		self.timeoutInterval = timeoutInterval
		self.bodyData = try! JSONSerialization.data(withJSONObject: jsonBody, options: [])
	}

	//------------------------------------------------------------------------------------------------------------------
	init(method :HTTPEndpointMethod = .get, url :URL, timeoutInterval :TimeInterval = 60.0) {
		// Store
		self.method = method
		self.path = url.absoluteString
		self.queryParameters = nil
		self.headers = nil
		self.timeoutInterval = timeoutInterval
		self.bodyData = nil
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func cancel() {
		// Mark as cancelled
		self.isCancelled = true
	}

	//------------------------------------------------------------------------------------------------------------------
	func transition(to state :State) {
		// Store state
		self.state = state
	}

	// MARK: Internal Methods
	//------------------------------------------------------------------------------------------------------------------
	func processResults(response :HTTPURLResponse?, data :Data?, error :Error?) {}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - SuccessHTTPEndpointRequest
class SuccessHTTPEndpointRequest : HTTPEndpointRequest {

	// MARK: Properties
	var	completionProc :(_ error :Error?) -> Void = { _ in }

	// MARK: HTTPEndpointRequest methods
	//------------------------------------------------------------------------------------------------------------------
	override func processResults(response :HTTPURLResponse?, data :Data?, error :Error?) {
		// Check cancelled
		if !self.isCancelled {
			// Call proc
			self.completionProc(error)
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HeadHTTPEndpointRequest
class HeadHTTPEndpointRequest : HTTPEndpointRequest {

	// MARK: Properties
	var	completionProc :(_ headers :[AnyHashable : Any]?, _ error :Error?) -> Void = { _,_ in }

	// MARK: HTTPEndpointRequest methods
	//------------------------------------------------------------------------------------------------------------------
	override func processResults(response :HTTPURLResponse?, data :Data?, error :Error?) {
		// Check cancelled
		if !self.isCancelled {
			// Call proc
			self.completionProc(response?.allHeaderFields, error)
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - DataHTTPEndpointRequest
class DataHTTPEndpointRequest : HTTPEndpointRequest {

	// MARK: Properties
	var	completionProc :(_ data :Data?, _ error :Error?) -> Void = { _,_ in }

	// MARK: HTTPEndpointRequest methods
	//------------------------------------------------------------------------------------------------------------------
	override func processResults(response :HTTPURLResponse?, data :Data?, error :Error?) {
		// Check cancelled
		if !self.isCancelled {
			// Call proc
			self.completionProc(data, error)
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - StringHTTPEndpointRequest
class StringHTTPEndpointRequest : HTTPEndpointRequest {

	// MARK: Properties
	var	completionProc :(_ string :String?, _ error :Error?) -> Void = { _,_ in }

	// MARK: HTTPEndpointRequest methods
	//------------------------------------------------------------------------------------------------------------------
	override func processResults(response :HTTPURLResponse?, data :Data?, error :Error?) {
		// Handle results
		var	string :String? = nil
		var	returnError :Error? = error
		if data != nil {
			// Try to compose string from data
			string = String(data: data!, encoding: .utf8)

			if string == nil {
				// Unable to transform results
				returnError = HTTPEndpointRequestError.unableToProcessResponseData
			}
		}

		// Check cancelled
		if !self.isCancelled {
			// Call proc
			self.completionProc(string, returnError)
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - JSONHTTPEndpointRequest
class JSONHTTPEndpointRequest<T> : HTTPEndpointRequest {

	// MARK: Properties
	var	completionProc :(_ info :T?, _ error :Error?) -> Void = { _,_ in }

	// MARK: HTTPEndpointRequest methods
	//------------------------------------------------------------------------------------------------------------------
	override func processResults(response :HTTPURLResponse?, data :Data?, error :Error?) {
		// Handle results
		var	info :T? = nil
		var	returnError :Error? = error
		if data != nil {
			// Try to compose info from data
			info = try? JSONSerialization.jsonObject(with: data!, options: []) as? T

			if info == nil {
				// Unable to transform results
				returnError = HTTPEndpointRequestError.unableToProcessResponseData
			}
		}

		// Check cancelled
		if !self.isCancelled {
			// Call proc
			self.completionProc(info, returnError)
		}
	}
}
