//
//  HTTPServiceRequest.swift
//  Swift Toolbox
//
//  Created by Stevo on 12/5/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: HTTPServiceRequest
struct HTTPServiceRequest {

	// MARK: Options
	public	struct Options : OptionSet {

//				static	public	let	multiValueQueryParametersUseMultipleKeys = Options(rawValue: 1 << 0)

						public	let	rawValue :Int

				// MARK: Lifecycle methods
				public init(rawValue :Int) { self.rawValue = rawValue }
			}

	// MARK: Properties
	let	method :HTTPServiceMethod
	let	path :String
	let	queryParameters :[String : Any]?
	let	headers :[String : String]?
	let	timeoutInterval :TimeInterval
	let	bodyData :Data?

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(method :HTTPServiceMethod, path :String, queryParameters :[String : Any]? = nil,
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
	init(method :HTTPServiceMethod, path :String, queryParameters :[String : Any]? = nil,
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
	init(method :HTTPServiceMethod, path :String, queryParameters :[String : Any]? = nil,
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
	func urlRequest(with serverPrefix :String, options :Options = []) -> URLRequest {
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
