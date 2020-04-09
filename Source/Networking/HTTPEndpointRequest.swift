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

	// MARK: Properties
					let	method :HTTPEndpointMethod
					let	path :String
					let	queryParameters :[String : Any]?
					let	headers :[String : String]?
					let	timeoutInterval :TimeInterval
					let	bodyData :Data?

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

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func cancel() {
		// Mark as cancelled
		self.isCancelled = true
	}

	// MARK: Internal Methods
	//------------------------------------------------------------------------------------------------------------------
	func resultsProc(data :Data?, response :HTTPURLResponse?, error :Error?, completionProcQueue :DispatchQueue) ->
			Void {}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - BasicHTTPEndpointRequest
class BasicHTTPEndpointRequest : HTTPEndpointRequest {

	// MARK: HTTPEndpointRequest methods
	//------------------------------------------------------------------------------------------------------------------
	override func resultsProc(data :Data?, response :HTTPURLResponse?, error :Error?,
			completionProcQueue :DispatchQueue) {
		// Queue
		completionProcQueue.async() {
			// Check if cancelled
			if !self.isCancelled {
				// Call proc
				self.completionProc(error)
			}
		}
	}

	// MARK: Properties
	var	completionProc :(_ error :Error?) -> Void = { _ in }
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HeadHTTPEndpointRequest
class HeadHTTPEndpointRequest : HTTPEndpointRequest {

	// MARK: HTTPEndpointRequest methods
	//------------------------------------------------------------------------------------------------------------------
	override func resultsProc(data :Data?, response :HTTPURLResponse?, error :Error?,
			completionProcQueue :DispatchQueue) {
		// Queue
		completionProcQueue.async() {
			// Check if cancelled
			if !self.isCancelled {
				// Call proc
				self.headersProc(response?.allHeaderFields, error)
			}
		}
	}

	// MARK: Properties
	var	headersProc :(_ headers :[AnyHashable : Any]?, _ error :Error?) -> Void = { _,_ in }
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - StringHTTPEndpointRequest
class StringHTTPEndpointRequest : HTTPEndpointRequest {

	// MARK: HTTPEndpointRequest methods
	//------------------------------------------------------------------------------------------------------------------
	override func resultsProc(data :Data?, response :HTTPURLResponse?, error :Error?,
			completionProcQueue :DispatchQueue) {
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

		// Queue
		completionProcQueue.async() {
			// Check if cancelled
			if !self.isCancelled {
				// Call proc
				self.stringProc(string, returnError)
			}
		}
	}

	// MARK: Properties
	var	stringProc :(_ string :String?, _ error :Error?) -> Void = { _,_ in }
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - JSONHTTPEndpointRequest
class JSONHTTPEndpointRequest<T> : HTTPEndpointRequest {

	// MARK: HTTPEndpointRequest methods
	//------------------------------------------------------------------------------------------------------------------
	override func resultsProc(data :Data?, response :HTTPURLResponse?, error :Error?,
			completionProcQueue :DispatchQueue) {
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

		// Queue
		completionProcQueue.async() {
			// Check if cancelled
			if !self.isCancelled {
				// Call proc
				self.infoProc(info, returnError)
			}
		}
	}

	// MARK: Properties
	var	infoProc :(_ info :T?, _ error :Error?) -> Void = { _,_ in }
}
