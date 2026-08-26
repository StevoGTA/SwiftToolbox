//
//  HTTPEndpointRequest+Decodable.swift
//  Swift Toolbox
//
//  Created by Stevo on 8/26/26.
//  Copyright © 2026 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: DecodableHTTPEndpointRequest
public class DecodableHTTPEndpointRequest<T : Decodable> : HTTPEndpointRequest {

	// MARK: Types
	public typealias CompletionProc = (_ response :HTTPURLResponse?, _ info :T?, _ error :Error?) -> Void

	// MARK: Properties
	public	var	completionProc :CompletionProc = { _,_,_ in }

			let	jsonDecoder :JSONDecoder

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(method :HTTPEndpointMethod = .get, path :String, queryComponents :[String : Any]? = nil,
			multiValueQueryComponent :MultiValueQueryComponent? = nil, headers :[String : String] = [:],
			timeoutInterval :TimeInterval = defaultTimeoutInterval.value, options :Options = [],
			jsonDecoder :JSONDecoder = JSONDecoder()) {
		// Store
		self.jsonDecoder = jsonDecoder

		// Do super
		super.init(method: method, path: path, queryComponents: queryComponents,
				multiValueQueryComponent: multiValueQueryComponent, headers: headers, timeoutInterval: timeoutInterval,
				options: options)
	}

	//------------------------------------------------------------------------------------------------------------------
	public init(method :HTTPEndpointMethod, path :String, queryComponents :[String : Any]? = nil,
			multiValueQueryComponent :MultiValueQueryComponent? = nil, headers :[String : String] = [:], jsonBody :Any,
			timeoutInterval :TimeInterval = defaultTimeoutInterval.value, options :Options = [],
			jsonDecoder :JSONDecoder = JSONDecoder()) {
		// Store
		self.jsonDecoder = jsonDecoder

		// Do super
		super.init(method: method, path: path, queryComponents: queryComponents,
				multiValueQueryComponent: multiValueQueryComponent, headers: headers, jsonBody: jsonBody,
				timeoutInterval: timeoutInterval, options: options)
	}

	// MARK: HTTPEndpointRequest methods
	//------------------------------------------------------------------------------------------------------------------
	override func adjustHeaders() {
		// Setup
		self.headers = self.headers ?? [:]
		self.headers!["Accept"] = "application/json"
	}
}

extension DecodableHTTPEndpointRequest : HTTPEndpointRequestProcessResults {

	// MARK: HTTPEndpointRequestProcessResults methods
	//------------------------------------------------------------------------------------------------------------------
	func processResults(response :HTTPURLResponse?, data :Data?, error :Error?) {
		// Check cancelled
		if !self.isCancelled {
			// Handle results
			var	info :T? = nil
			var	localError = error
			if (localError == nil) && (data != nil) {
				// Catch errors
				do {
					// Try to decode info from data
					info = try self.jsonDecoder.decode(T.self, from: data!)
				} catch {
					// Error
					localError = error
				}
			}

			// Call proc
			self.completionProc(response, info, localError)
		}
	}
}
