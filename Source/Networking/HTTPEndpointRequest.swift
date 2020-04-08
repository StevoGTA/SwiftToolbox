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
	enum MultiValueQueryParameterHandling {
		case useComma
		case repeatKey
	}

	struct Options {

		// MARK: Properties
		let	multiValueQueryParameterHandling = MultiValueQueryParameterHandling.repeatKey
		let	maximumURLLength = 1024
	}

	// MARK: Properties
	let	method :HTTPEndpointMethod
	let	path :String
	let	queryParameters :[String : Any]?
	let	headers :[String : String]?
	let	timeoutInterval :TimeInterval
	let	bodyData :Data?

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
	func urlRequest(with serverPrefix :String, options :Options = Options()) -> URLRequest {
		// Setup
		var	urlRequest = URLRequest(url: URL(string: "\(serverPrefix)\(self.path)")!)
		switch self.method {
			case .get:		urlRequest.httpMethod = "GET"
			case .head:		urlRequest.httpMethod = "HEAD"
			case .patch:	urlRequest.httpMethod = "PATCH"
			case .post:		urlRequest.httpMethod = "POST"
			case .put:		urlRequest.httpMethod = "PUT"
		}

		// Query parameters
// TODO: Query parameters

		self.headers?.forEach() { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
		urlRequest.timeoutInterval = self.timeoutInterval
		urlRequest.httpBody = self.bodyData

		return urlRequest
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HTTPEndpointRequestResultsHandler
protocol HTTPEndpointRequestResultsHandler {

	// MARK: Types
	associatedtype Results

	// MARK: Methods
	func transformResults(data :Data?, response :HTTPURLResponse?, error :Error?) -> Results
	func resultsProc(_ results :Results) -> Void
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - BasicHTTPEndpointRequest
class BasicHTTPEndpointRequest : HTTPEndpointRequest, HTTPEndpointRequestResultsHandler {

	// MARK: HTTPEndpointRequestResultsHandler implementation
	typealias Results = Error?

	func transformResults(data: Data?, response: HTTPURLResponse?, error: Error?) -> Error? { error }

	func resultsProc(_ results: Error?) { self.completionProc(results) }

	// MARK: Properties
	var	completionProc :(_ error :Error?) -> Void = { _ in }
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HeadHTTPEndpointRequest
class HeadHTTPEndpointRequest : HTTPEndpointRequest, HTTPEndpointRequestResultsHandler {

	// MARK: HTTPEndpointRequestResultsHandler implementation
	typealias Results = (headers :[AnyHashable : Any]?, error :Error?)

	func transformResults(data: Data?, response: HTTPURLResponse?, error: Error?) ->
			(headers: [AnyHashable : Any]?, error: Error?) { ( response?.allHeaderFields, error ) }

	func resultsProc(_ results: (headers: [AnyHashable : Any]?, error: Error?)) {
		// Call proc
		self.headersProc(results.headers, results.error)
	}

	// MARK: Properties
	var	headersProc :(_ headers :[AnyHashable : Any]?, _ error :Error?) -> Void = { _,_ in }
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - StringHTTPEndpointRequest
class StringHTTPEndpointRequest : HTTPEndpointRequest, HTTPEndpointRequestResultsHandler {

	// MARK: HTTPEndpointRequestResultsHandler implementation
	typealias Results = (string :String?, error :Error?)

	func transformResults(data: Data?, response: HTTPURLResponse?, error: Error?) -> (string: String?, error: Error?) {
		// Handle results
		if data != nil {
			// Try to copmose string from data
			if let string = String(data: data!, encoding: .utf8) {
				// Success
				return (string, nil)
			} else {
				// Unable to transform results
				return (nil, HTTPEndpointRequestError.unableToProcessResponseData)
			}
		} else {
			// Error
			return (nil, error)
		}
	}

	func resultsProc(_ results: (string: String?, error: Error?)) { self.stringProc(results.string, results.error) }

	// MARK: Properties
	var	stringProc :(_ string :String?, _ error :Error?) -> Void = { _,_ in }
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - JSONHTTPEndpointRequest
class JSONHTTPEndpointRequest<T> : HTTPEndpointRequest, HTTPEndpointRequestResultsHandler {

	// MARK: HTTPEndpointRequestResultsHandler implementation
	typealias Results = (info :T?, error :Error?)

	func transformResults(data: Data?, response: HTTPURLResponse?, error: Error?) -> Results {
		// Handle results
		if data != nil {
			// Try to compose info from data
			if let info = try? JSONSerialization.jsonObject(with: data!, options: []) as? T {
				// Success
				return (info, nil)
			} else {
				// Unable to transform results
				return (nil, HTTPEndpointRequestError.unableToProcessResponseData)
			}
		} else {
			// Error
			return (nil, error)
		}
	}

	func resultsProc(_ results: (info: T?, error: Error?)) { self.infoProc(results.info, results.error) }

	// MARK: Properties
	var	infoProc :(_ info :T?, _ error :Error?) -> Void = { _,_ in }
}
