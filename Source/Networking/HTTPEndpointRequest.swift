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
public class HTTPEndpointRequest {

	// MARK: Types
	enum State {
		case queued
		case active
		case finished
	}

	public typealias MultiValueQueryComponent = (key :String, values :[Any])

	// MARK: Properties
					let	method :HTTPEndpointMethod
					let	path :String
					let	queryComponents :[String : Any]?
					let	multiValueQueryComponent :MultiValueQueryComponent?
					let	headers :[String : String]?
					let	timeoutInterval :TimeInterval
					let	bodyData :Data?

	private(set)	var	state :State = .queued
	private(set)	var	isCancelled = false

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(method :HTTPEndpointMethod, path :String, queryComponents :[String : Any]? = nil,
			multiValueQueryComponent :MultiValueQueryComponent? = nil, headers :[String : String]? = nil,
			timeoutInterval :TimeInterval = 60.0) {
		// Store
		self.method = method
		self.path = path
		self.queryComponents = queryComponents
		self.multiValueQueryComponent = multiValueQueryComponent
		self.headers = headers
		self.timeoutInterval = timeoutInterval
		self.bodyData = nil
	}

	//------------------------------------------------------------------------------------------------------------------
	public init(method :HTTPEndpointMethod, path :String, queryComponents :[String : Any]? = nil,
			multiValueQueryComponent :MultiValueQueryComponent? = nil, headers :[String : String]? = nil,
			timeoutInterval :TimeInterval = 60.0, bodyData :Data) {
		// Store
		self.method = method
		self.path = path
		self.queryComponents = queryComponents
		self.multiValueQueryComponent = multiValueQueryComponent
		self.headers = headers
		self.timeoutInterval = timeoutInterval
		self.bodyData = bodyData
	}

	//------------------------------------------------------------------------------------------------------------------
	public init(method :HTTPEndpointMethod, path :String, queryComponents :[String : Any]? = nil,
			multiValueQueryComponent :MultiValueQueryComponent? = nil, headers :[String : String]? = nil,
			timeoutInterval :TimeInterval = 60.0, jsonBody :Any) {
		// Setup
		var	headersUse = headers ?? [:]
		headersUse["Content-Type"] = "application/json"

		// Store
		self.method = method
		self.path = path
		self.queryComponents = queryComponents
		self.multiValueQueryComponent = multiValueQueryComponent
		self.headers = headersUse
		self.timeoutInterval = timeoutInterval
		self.bodyData = try! JSONSerialization.data(withJSONObject: jsonBody, options: [])
	}

	//------------------------------------------------------------------------------------------------------------------
	public init(method :HTTPEndpointMethod, path :String, queryComponents :[String : Any]? = nil,
			multiValueQueryComponent :MultiValueQueryComponent? = nil, headers :[String : String]? = nil,
			timeoutInterval :TimeInterval = 60.0, urlEncodedBody :[String : Any]) {
		// Setup
		var	headersUse = headers ?? [:]
		headersUse["Content-Type"] = "application/x-www-form-urlencoded"

		// Store
		self.method = method
		self.path = path
		self.queryComponents = queryComponents
		self.multiValueQueryComponent = multiValueQueryComponent
		self.headers = headersUse
		self.timeoutInterval = timeoutInterval
		self.bodyData =
				String(combining: urlEncodedBody.map({ "\($0.key)=\($0.value)" }), with: "&")
					.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
					.data(using: .utf8)
	}

	//------------------------------------------------------------------------------------------------------------------
	public init(method :HTTPEndpointMethod = .get, url :URL, timeoutInterval :TimeInterval = 60.0) {
		// Store
		self.method = method
		self.path = url.absoluteString
		self.queryComponents = nil
		self.multiValueQueryComponent = nil
		self.headers = nil
		self.timeoutInterval = timeoutInterval
		self.bodyData = nil
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func cancel() { self.isCancelled = true }

	//------------------------------------------------------------------------------------------------------------------
	func transition(to state :State) { self.state = state }

	// MARK: Internal Methods
	//------------------------------------------------------------------------------------------------------------------
	func processResults(response :HTTPURLResponse?, data :Data?, error :Error?) {}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - DataHTTPEndpointRequest
public class DataHTTPEndpointRequest : HTTPEndpointRequest {

	// MARK: Properties
	public var	completionProc :(_ data :Data?, _ error :Error?) -> Void = { _,_ in }

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
// MARK: - FileHTTPEndpointRequest
class FileHTTPEndpointRequest : HTTPEndpointRequest {

	// MARK: Properties
	public var	completionProc :(_ error :Error?) -> Void = { _ in }

	private	let	destinationURL :URL

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(method :HTTPEndpointMethod, path :String, queryComponents :[String : Any]? = nil,
			headers :[String : String]? = nil, timeoutInterval :TimeInterval = 60.0, destinationURL :URL) {
		// Store
		self.destinationURL = destinationURL

		// Do super
		super.init(method: method, path: path, queryComponents: queryComponents, headers: headers,
				timeoutInterval: timeoutInterval)
	}

	//------------------------------------------------------------------------------------------------------------------
	init(method :HTTPEndpointMethod, path :String, queryComponents :[String : Any]? = nil,
			headers :[String : String]? = nil, timeoutInterval :TimeInterval = 60.0, bodyData :Data,
			destinationURL :URL) {
		// Store
		self.destinationURL = destinationURL

		// Do super
		super.init(method: method, path: path, queryComponents: queryComponents, headers: headers,
				timeoutInterval: timeoutInterval, bodyData: bodyData)
	}

	//------------------------------------------------------------------------------------------------------------------
	init(method :HTTPEndpointMethod, path :String, queryComponents :[String : Any]? = nil,
			headers :[String : String]? = nil, timeoutInterval :TimeInterval = 60.0, jsonBody :Any,
			destinationURL :URL) {
		// Store
		self.destinationURL = destinationURL

		// Do super
		super.init(method: method, path: path, queryComponents: queryComponents, headers: headers,
				timeoutInterval: timeoutInterval, jsonBody: jsonBody)
	}

	//------------------------------------------------------------------------------------------------------------------
	init(method :HTTPEndpointMethod, path :String, queryComponents :[String : Any]? = nil,
			headers :[String : String]? = nil, timeoutInterval :TimeInterval = 60.0, urlEncodedBody :[String : Any],
			destinationURL :URL) {
		// Store
		self.destinationURL = destinationURL

		// Do super
		super.init(method: method, path: path, queryComponents: queryComponents, headers: headers,
				timeoutInterval: timeoutInterval, urlEncodedBody: urlEncodedBody)
	}

	//------------------------------------------------------------------------------------------------------------------
	init(method :HTTPEndpointMethod = .get, url :URL, timeoutInterval :TimeInterval = 60.0, destinationURL :URL) {
		// Store
		self.destinationURL = destinationURL

		// Do super
		super.init(method: method, url: url, timeoutInterval: timeoutInterval)
	}

	// MARK: HTTPEndpointRequest methods
	//------------------------------------------------------------------------------------------------------------------
	override func processResults(response :HTTPURLResponse?, data :Data?, error :Error?) {
		// Check cancelled
		if !self.isCancelled {
			// Handle results
			if data != nil {
				do {
					// Store
					try data!.write(to: self.destinationURL)

					// Call completion
					self.completionProc(nil)
				} catch {
					// Error
					self.completionProc(error)
				}
			} else {
				// Error
				self.completionProc(error)
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HeadHTTPEndpointRequest
public class HeadHTTPEndpointRequest : HTTPEndpointRequest {

	// MARK: Properties
	public var	completionProc :(_ headers :[AnyHashable : Any]?, _ error :Error?) -> Void = { _,_ in }

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
// MARK: - JSONHTTPEndpointRequest
public class JSONHTTPEndpointRequest<T> : HTTPEndpointRequest {

	// MARK: Properties
	public var	completionProc :(_ info :T?, _ error :Error?) -> Void = { _,_ in }

	// MARK: HTTPEndpointRequest methods
	//------------------------------------------------------------------------------------------------------------------
	override func processResults(response :HTTPURLResponse?, data :Data?, error :Error?) {
		// Handle results
		var	info :T? = nil
		var	returnError :Error? = error
		if data != nil {
			// Catch errors
			do {
				// Try to compose info from data
				info = try JSONSerialization.jsonObject(with: data!, options: []) as? T
			} catch {
				// Error
				returnError = error
			}
		}

		// Check cancelled
		if !self.isCancelled {
			// Call proc
			self.completionProc(info, returnError)
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - SuccessHTTPEndpointRequest
public class SuccessHTTPEndpointRequest : HTTPEndpointRequest {

	// MARK: Properties
	public var	completionProc :(_ error :Error?) -> Void = { _ in }

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
// MARK: - StringHTTPEndpointRequest
public class StringHTTPEndpointRequest : HTTPEndpointRequest {

	// MARK: Properties
	public var	completionProc :(_ string :String?, _ error :Error?) -> Void = { _,_ in }

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
