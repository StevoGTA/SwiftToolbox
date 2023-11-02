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

extension HTTPEndpointRequestError : CustomStringConvertible, LocalizedError {

	// MARK: Properties
	public 	var	description :String { self.localizedDescription }
	public	var	errorDescription :String? {
						// What are we
						switch self {
							case .unableToProcessResponseData:
									return "Unable to process response data"
						}
					}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HTTPEndpointRequest
public class HTTPEndpointRequest {

	// MARK: Options
	public struct Options : OptionSet {

		// MARK: Properties
		static	public	let	queryContainsSecureInfo = Options(rawValue: 1 << 0)

				public	let	rawValue :Int

		// MARK: Lifecycle methods
		public init(rawValue :Int) { self.rawValue = rawValue }
	}

	// MARK: State
	enum State {
		case queued
		case active
		case finished
	}

	// MARK: Types
	public typealias MultiValueQueryComponent = (key :String, values :[Any])

	// MARK: Properties
	static	public			var	defaultTimeoutInterval = 60.0

							let	method :HTTPEndpointMethod
							let	path :String
							let	queryComponents :[String : Any]?
							let	multiValueQueryComponent :MultiValueQueryComponent?
							let	bodyData :Data?
							let	timeoutInterval :TimeInterval
							let	options :Options

							var	headers :[String : String]?

			private(set)	var	state :State = .queued
			private(set)	var	isCancelled = false

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
//	public init(method :HTTPEndpointMethod, path :String, queryComponents :[String : Any]? = nil,
//			multiValueQueryComponent :MultiValueQueryComponent? = nil, headers :[String : String]? = nil,
//			timeoutInterval :TimeInterval = defaultTimeoutInterval, options :Options = []) {
//		// Store
//		self.method = method
//		self.path = path
//		self.queryComponents = queryComponents
//		self.multiValueQueryComponent = multiValueQueryComponent
//		self.bodyData = nil
//		self.timeoutInterval = timeoutInterval
//		self.options = options
//
//		self.headers = headers
//		adjustHeaders()
//	}
//
	//------------------------------------------------------------------------------------------------------------------
	public init(method :HTTPEndpointMethod, path :String, queryComponents :[String : Any]? = nil,
			multiValueQueryComponent :MultiValueQueryComponent? = nil, headers :[String : String]? = nil,
			bodyData :Data? = nil, timeoutInterval :TimeInterval = defaultTimeoutInterval, options :Options = []) {
		// Store
		self.method = method
		self.path = path
		self.queryComponents = queryComponents
		self.multiValueQueryComponent = multiValueQueryComponent
		self.bodyData = bodyData
		self.timeoutInterval = timeoutInterval
		self.options = options

		self.headers = headers ?? [:]
		self.headers!["Content-Type"] = "application/octet-stream"
		adjustHeaders()
	}

	//------------------------------------------------------------------------------------------------------------------
	public init(method :HTTPEndpointMethod, path :String, queryComponents :[String : Any]? = nil,
			multiValueQueryComponent :MultiValueQueryComponent? = nil, headers :[String : String]? = nil,
			jsonBody :Any, timeoutInterval :TimeInterval = defaultTimeoutInterval, options :Options = []) {
		// Store
		self.method = method
		self.path = path
		self.queryComponents = queryComponents
		self.multiValueQueryComponent = multiValueQueryComponent
		self.bodyData = try! JSONSerialization.data(withJSONObject: jsonBody, options: [])
		self.timeoutInterval = timeoutInterval
		self.options = options

		self.headers = headers ?? [:]
		self.headers!["Content-Type"] = "application/json"
		adjustHeaders()
	}

	//------------------------------------------------------------------------------------------------------------------
	public init(method :HTTPEndpointMethod, path :String, queryComponents :[String : Any]? = nil,
			multiValueQueryComponent :MultiValueQueryComponent? = nil, headers :[String : String]? = nil,
			xmlBody :Data, timeoutInterval :TimeInterval = defaultTimeoutInterval, options :Options = []) {
		// Store
		self.method = method
		self.path = path
		self.queryComponents = queryComponents
		self.multiValueQueryComponent = multiValueQueryComponent
		self.bodyData = xmlBody
		self.timeoutInterval = timeoutInterval
		self.options = options

		self.headers = headers ?? [:]
		self.headers!["Content-Type"] = "application/xml"
		adjustHeaders()
	}

	//------------------------------------------------------------------------------------------------------------------
	public init(method :HTTPEndpointMethod, path :String, queryComponents :[String : Any]? = nil,
			multiValueQueryComponent :MultiValueQueryComponent? = nil, headers :[String : String]? = nil,
			urlEncodedBody :[String : Any], timeoutInterval :TimeInterval = defaultTimeoutInterval,
			options :Options = []) {
		// Store
		self.method = method
		self.path = path
		self.queryComponents = queryComponents
		self.multiValueQueryComponent = multiValueQueryComponent
		self.bodyData =
				String(combining: urlEncodedBody.map({ "\($0.key)=\($0.value)" }), with: "&")
					.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
					.data(using: .utf8)
		self.timeoutInterval = timeoutInterval
		self.options = options

		self.headers = headers ?? [:]
		self.headers!["Content-Type"] = "application/x-www-form-urlencoded"
		adjustHeaders()
	}

	//------------------------------------------------------------------------------------------------------------------
	public init(method :HTTPEndpointMethod = .get, url :URL, headers :[String : String]? = nil,
			bodyData :Data? = nil, timeoutInterval :TimeInterval = defaultTimeoutInterval, options :Options = []) {
		// Store
		self.method = method
		self.path = url.absoluteString
		self.queryComponents = nil
		self.multiValueQueryComponent = nil
		self.bodyData = bodyData
		self.timeoutInterval = timeoutInterval
		self.options = options

		self.headers = headers
		adjustHeaders()
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func cancel() { self.isCancelled = true }

	//------------------------------------------------------------------------------------------------------------------
	func transition(to state :State) { self.state = state }

	// MARK: Subclass methods
	//------------------------------------------------------------------------------------------------------------------
	func adjustHeaders() {}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HTTPEndpointRequestProcessResults
protocol HTTPEndpointRequestProcessResults : HTTPEndpointRequest {

	// MARK: Methods
	//------------------------------------------------------------------------------------------------------------------
	func processResults(response :HTTPURLResponse?, data :Data?, error :Error?)
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HTTPEndpointRequestProcessMultiResults
protocol HTTPEndpointRequestProcessMultiResults : HTTPEndpointRequest {

	// MARK: Methods
	//------------------------------------------------------------------------------------------------------------------
	func processResults(response :HTTPURLResponse?, data :Data?, error :Error?, totalRequests :Int)
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - DataHTTPEndpointRequest
public class DataHTTPEndpointRequest : HTTPEndpointRequest {

	// MARK: Types
	public	typealias CompletionProc = (_ response :HTTPURLResponse?, _ data :Data?, _ error :Error?) -> Void

	// MARK: Properties
	public	var	completionProc :CompletionProc = { _,_,_ in }
}

extension DataHTTPEndpointRequest : HTTPEndpointRequestProcessResults {

	// MARK: HTTPEndpointRequestProcessResults methods
	//------------------------------------------------------------------------------------------------------------------
	func processResults(response :HTTPURLResponse?, data :Data?, error :Error?) {
		// Check cancelled
		if !self.isCancelled {
			// Call proc
			self.completionProc(response, data, error)
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - FileHTTPEndpointRequest
public class FileHTTPEndpointRequest : HTTPEndpointRequest {

	// MARK: Types
	public	typealias ProgressProc = (_ progress :Double) -> Void
	public	typealias CompletionProc = (_ response :HTTPURLResponse?, _ error :Error?) -> Void

	// MARK: Properties
	public	var	progressProc :ProgressProc = { _ in }
	public	var	completionProc :CompletionProc = { _,_ in }

	private	let	destinationURL :URL

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(method :HTTPEndpointMethod = .get, path :String, queryComponents :[String : Any]? = nil,
			headers :[String : String]? = nil, timeoutInterval :TimeInterval = defaultTimeoutInterval,
			destinationURL :URL) {
		// Store
		self.destinationURL = destinationURL

		// Do super
		super.init(method: method, path: path, queryComponents: queryComponents, headers: headers,
				timeoutInterval: timeoutInterval)
	}

	//------------------------------------------------------------------------------------------------------------------
	init(method :HTTPEndpointMethod = .get, path :String, queryComponents :[String : Any]? = nil,
			headers :[String : String]? = nil, timeoutInterval :TimeInterval = defaultTimeoutInterval,
			destinationFile :File) {
		// Store
		self.destinationURL = destinationFile.url

		// Do super
		super.init(method: method, path: path, queryComponents: queryComponents, headers: headers,
				timeoutInterval: timeoutInterval)
	}

	//------------------------------------------------------------------------------------------------------------------
	init(url :URL, timeoutInterval :TimeInterval = defaultTimeoutInterval, options :Options = [], destinationURL :URL) {
		// Store
		self.destinationURL = destinationURL

		// Do super
		super.init(method: .get, url: url, timeoutInterval: timeoutInterval, options: options)
	}

	//------------------------------------------------------------------------------------------------------------------
	init(url :URL, timeoutInterval :TimeInterval = defaultTimeoutInterval, options :Options = [],
			destinationFile :File) {
		// Store
		self.destinationURL = destinationFile.url

		// Do super
		super.init(method: .get, url: url, timeoutInterval: timeoutInterval, options: options)
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func processResults(response :HTTPURLResponse?, url :URL?, error :Error?) {
		// Check cancelled
		if !self.isCancelled {
			// Handle results
			if url != nil {
				do {
					// Move file
					try FileManager.default.create(Folder(self.destinationURL.deletingLastPathComponent()))
					try FileManager.default.moveItem(at: url!, to: self.destinationURL)

					// Call completion
					self.completionProc(response, nil)
				} catch {
					// Error
					self.completionProc(response, error)
				}
			} else {
				// Error
				self.completionProc(response, error)
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HeadHTTPEndpointRequest
public class HeadHTTPEndpointRequest : HTTPEndpointRequest {

	// MARK: Types
	public	typealias	CompletionProc = (_ response :HTTPURLResponse?, _ error :Error?) -> Void

	// MARK: Properties
	public	var	completionProc :CompletionProc = { _,_ in }
}

extension HeadHTTPEndpointRequest : HTTPEndpointRequestProcessResults {

	// MARK: HTTPEndpointRequestProcessResults methods
	//------------------------------------------------------------------------------------------------------------------
	func processResults(response :HTTPURLResponse?, data :Data?, error :Error?) {
		// Check cancelled
		if !self.isCancelled {
			// Call proc
			self.completionProc(response, error)
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - IntegerHTTPEndpointRequest
public class IntegerHTTPEndpointRequest : HTTPEndpointRequest {

	// MARK: Types
	public	typealias	CompletionProc = (_ response :HTTPURLResponse?, _ value :Int?, _ error :Error?) -> Void

	// MARK: Properties
	public	var	completionProc :CompletionProc = { _,_,_ in }
}

extension IntegerHTTPEndpointRequest : HTTPEndpointRequestProcessResults {

	// MARK: HTTPEndpointRequestProcessResults methods
	//------------------------------------------------------------------------------------------------------------------
	func processResults(response :HTTPURLResponse?, data :Data?, error :Error?) {
		// Check cancelled
		if !self.isCancelled {
			// Handle results
			var	value :Int? = nil
			var	returnError :Error? = error
			if data != nil {
				// Try to compose string from response
				if let string = String(data: data!, encoding: .utf8) {
					// Try to convert to Int
					value = Int(string)
				}

				if value == nil {
					// Unable to transform results
					returnError = HTTPEndpointRequestError.unableToProcessResponseData
				}
			}

			// Call proc
			self.completionProc(response, value, returnError)
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - JSONHTTPEndpointRequest
public class JSONHTTPEndpointRequest<T> : HTTPEndpointRequest {

	// MARK: Types
	public typealias SingleResponseCompletionProc = (_ response :HTTPURLResponse?, _ info :T?, _ error :Error?) -> Void
	public typealias MultiResponsePartialResultsProc =
						(_ response :HTTPURLResponse?, _ info :T?, _ error :Error?) -> Void
	public typealias MultiResponseCompletionProc = (_ errors :[Error]) -> Void

	// MARK: Properties
	public	var	completionProc :SingleResponseCompletionProc?
	public	var	multiResponsePartialResultsProc :MultiResponsePartialResultsProc?
	public	var	multiResponseCompletionProc :MultiResponseCompletionProc?

	private	let	completedRequestsCount = LockingNumeric<Int>()

	private	var	errors = [Error]()

	// MARK: HTTPEndpointRequest methods
	//------------------------------------------------------------------------------------------------------------------
	override func adjustHeaders() {
		// Setup
		self.headers = self.headers ?? [:]
		self.headers!["Accept"] = "application/json"
	}
}

extension JSONHTTPEndpointRequest : HTTPEndpointRequestProcessMultiResults {

	// MARK: HTTPEndpointRequestProcessMultiResults methods
	//------------------------------------------------------------------------------------------------------------------
	func processResults(response :HTTPURLResponse?, data :Data?, error :Error?, totalRequests :Int) {
		// Check cancelled
		if !self.isCancelled {
			// Handle results
			var	info :T? = nil
			var	localError = error
			if data != nil {
				// Catch errors
				do {
					// Try to compose info from data
					info = try JSONSerialization.jsonObject(with: data!, options: []) as? T

					// Check if got response data
					if info == nil {
						// Nope
						localError = localError ?? HTTPEndpointRequestError.unableToProcessResponseData
					}
				} catch {
					// Error
					localError = localError ?? error
				}
			}

			// Check error
			if localError != nil { self.errors.append(localError!) }

			// Call proc
			if totalRequests == 1 {
				// Single request (but could have been multiple
				if self.completionProc != nil {
					// Single response expected
					self.completionProc!(response, info, localError)
				} else {
					// Multi-responses possible
					self.multiResponsePartialResultsProc!(response, info, localError)
					self.multiResponseCompletionProc!(self.errors)
				}
			} else {
				// Multiple requests
				self.multiResponsePartialResultsProc!(response, info, localError)
				if self.completedRequestsCount.add(1) == totalRequests {
					// All done
					self.multiResponseCompletionProc!(self.errors)
				}
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - StringHTTPEndpointRequest
public class StringHTTPEndpointRequest : HTTPEndpointRequest {

	// MARK: Types
	public	typealias	CompletionProc = (_ response :HTTPURLResponse?, _ string :String?, _ error :Error?) -> Void

	// MARK: Properties
	public	var	completionProc :CompletionProc = { _,_,_ in }
}

extension StringHTTPEndpointRequest : HTTPEndpointRequestProcessResults {

	// MARK: HTTPEndpointRequestProcessResults methods
	//------------------------------------------------------------------------------------------------------------------
	func processResults(response :HTTPURLResponse?, data :Data?, error :Error?) {
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
			self.completionProc(response, string, returnError)
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - SuccessHTTPEndpointRequest
public class SuccessHTTPEndpointRequest : HTTPEndpointRequest {

	// MARK: Types
	public	typealias	CompletionProc = (_ response :HTTPURLResponse?, _ error :Error?) -> Void

	// MARK: Properties
	public var	completionProc :CompletionProc = { _,_ in }
}

extension SuccessHTTPEndpointRequest : HTTPEndpointRequestProcessResults {

	// MARK: HTTPEndpointRequestProcessResults methods
	//------------------------------------------------------------------------------------------------------------------
	func processResults(response :HTTPURLResponse?, data :Data?, error :Error?) {
		// Check cancelled
		if !self.isCancelled {
			// Call proc
			self.completionProc(response, error)
		}
	}
}
