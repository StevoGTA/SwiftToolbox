//
//  HTTPEndpointClient.swift
//  Swift Toolbox
//
//  Created by Stevo on 3/23/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

/*
	Rework needed:
		HTTPEndpointRequest may generate multiple URLRequests
*/

//----------------------------------------------------------------------------------------------------------------------
// MARK: HTTPEndpointRequest extension
extension HTTPEndpointRequest {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	fileprivate func urlRequest(with serverPrefix :String,
			multiValueQueryParameterHandling :HTTPEndpointClient.MultiValueQueryParameterHandling,
			maximumURLLength :Int) -> URLRequest {
		// Setup
		var	url :URL
		if self.path.hasPrefix("http") || self.path.hasPrefix("https") {
			// Already have fully-formed URL
			url = URL(string: self.path)!
		} else {
			// Compose URL
			var	queryString = ""
			if let queryParameters = self.queryParameters {
				// Iterate all query parameters
				queryParameters.forEach() { key, value in
					// Check value types
					if let values = value as? [String] {
						// [String]
						switch multiValueQueryParameterHandling {
							case .repeatKey:
								// Repeat key
								values.forEach() {
									// Add this value
									if queryString.isEmpty { queryString = "?" } else { queryString += "&" }
									queryString += "\(key)=\($0)"
								}

							case .useComma:
								// Use comma
								if queryString.isEmpty { queryString = "?" } else { queryString += "&" }
								queryString += "\(key)=\(String(combining: values, with: ","))"
						}
					} else {
						// Use string interpolation
						if queryString.isEmpty { queryString = "?" } else { queryString += "&" }
						queryString += "\(key)=\(value)"
					}
				}
			}

			// Setup URL
			let	string =
						serverPrefix +
								self.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)! +
								queryString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
			url = URL(string: string)!
		}

		// Setup URLRequest
		var	urlRequest = URLRequest(url: url)
		switch self.method {
			case .get:		urlRequest.httpMethod = "GET"
			case .head:		urlRequest.httpMethod = "HEAD"
			case .patch:	urlRequest.httpMethod = "PATCH"
			case .post:		urlRequest.httpMethod = "POST"
			case .put:		urlRequest.httpMethod = "PUT"
		}

		self.headers?.forEach() { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
		urlRequest.timeoutInterval = self.timeoutInterval
		urlRequest.httpBody = self.bodyData

		return urlRequest
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HTTPEndpointClient
class HTTPEndpointClient {

	// MARK: Types
	enum MultiValueQueryParameterHandling {
		case useComma
		case repeatKey
	}

	// MARK: Properties
			var	logTransactions = true

	private	let	serverPrefix :String
	private	let	multiValueQueryParameterHandling :MultiValueQueryParameterHandling
	private	let	maximumURLLength :Int
	private	let	urlSession :URLSession

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(serverPrefix :String, multiValueQueryParameterHandling :MultiValueQueryParameterHandling = .repeatKey,
			maximumURLLength :Int = 1024, urlSession :URLSession = URLSession.shared) {
		// Store
		self.serverPrefix = serverPrefix
		self.multiValueQueryParameterHandling = multiValueQueryParameterHandling
		self.maximumURLLength = maximumURLLength
		self.urlSession = urlSession
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func queue(_ httpEndpointRequest :HTTPEndpointRequest, completionProcQueue :DispatchQueue = .main) {
		// Perform in background
		DispatchQueue.global().async() { [weak self] in
			//
			guard let strongSelf = self else { return }

			// Setup
			let	urlRequest =
						httpEndpointRequest.urlRequest(with: strongSelf.serverPrefix,
								multiValueQueryParameterHandling: strongSelf.multiValueQueryParameterHandling,
								maximumURLLength: strongSelf.maximumURLLength)

			// Log
			if strongSelf.logTransactions { NSLog("HTTPEndpointClient - sending \(urlRequest)") }

			// Resume data task
			strongSelf.urlSession.dataTask(with: urlRequest, completionHandler: {
				// Check if cancelled
				guard !httpEndpointRequest.isCancelled else { return }

				// Handle results
				httpEndpointRequest.resultsProc(data: $0, response: $1 as? HTTPURLResponse, error: $2,
						completionProcQueue: completionProcQueue)
			}).resume()
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func queue(_ successHTTPEndpointRequest :SuccessHTTPEndpointRequest, completionProcQueue :DispatchQueue = .main,
			completionProc :@escaping (_ error :Error?) -> Void) {
		// Setup
		successHTTPEndpointRequest.completionProc = completionProc

		// Perform
		queue(successHTTPEndpointRequest, completionProcQueue: completionProcQueue)
	}

	//------------------------------------------------------------------------------------------------------------------
	func queue(_ headHTTPEndpointRequest :HeadHTTPEndpointRequest, completionProcQueue :DispatchQueue = .main,
			headersProc :@escaping (_ headers :[AnyHashable : Any]?, _ error :Error?) -> Void) {
		// Setup
		headHTTPEndpointRequest.headersProc = headersProc

		// Perform
		queue(headHTTPEndpointRequest, completionProcQueue: completionProcQueue)
	}

	//------------------------------------------------------------------------------------------------------------------
	func queue(_ dataHTTPEndpointRequest :DataHTTPEndpointRequest, completionProcQueue :DispatchQueue = .main,
			dataProc :@escaping (_ data :Data?, _ error :Error?) -> Void) {
		// Setup
		dataHTTPEndpointRequest.dataProc = dataProc

		// Perform
		queue(dataHTTPEndpointRequest, completionProcQueue: completionProcQueue)
	}

	//------------------------------------------------------------------------------------------------------------------
	func queue(_ stringHTTPEndpointRequest :StringHTTPEndpointRequest, completionProcQueue :DispatchQueue = .main,
			stringProc :@escaping (_ string :String?, _ error :Error?) -> Void) {
		// Setup
		stringHTTPEndpointRequest.stringProc = stringProc

		// Perform
		queue(stringHTTPEndpointRequest, completionProcQueue: completionProcQueue)
	}

	//------------------------------------------------------------------------------------------------------------------
	func queue<T>(_ jsonHTTPEndpointRequest :JSONHTTPEndpointRequest<T>, completionProcQueue :DispatchQueue = .main,
			infoProc :@escaping(_ info :T?, _ error :Error?) -> Void) {
		// Setup
		jsonHTTPEndpointRequest.infoProc = infoProc

		// Perform
		queue(jsonHTTPEndpointRequest, completionProcQueue: completionProcQueue)
	}
}
