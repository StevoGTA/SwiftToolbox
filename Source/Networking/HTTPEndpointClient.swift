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
			queryParameters?.forEach() { key, value in
				// Check value types
				if let values = value as? [Any] {
					// Array
					switch multiValueQueryParameterHandling {
						case .repeatKey:
							// Repeat key
							values.forEach() { queryString += queryString.isEmpty ? "?\(key)=\($0)" : "&\(key)=\($0)" }

						case .useComma:
							// Use comma
							queryString += queryString.isEmpty ? "?\(key)=" : "&\(key)="
							values.enumerated().forEach()
								{ queryString += ($0.offset == 0) ? "\($0.element)" : ",\($0.element)" }
					}
				} else {
					// Value
					queryString += queryString.isEmpty ? "?\(key)=\(value)" : "&\(key)=\(value)"
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
public class HTTPEndpointClient {

	// MARK: Types
	public enum Priority : Int {
		case normal
		case background
	}

	public enum MultiValueQueryParameterHandling {
		case repeatKey
		case useComma
	}

	typealias HTTPEndpointRequestInfo =
				(httpEndpointRequest :HTTPEndpointRequest, identifier :String, priority :Priority)

	// MARK: Properties
			var	logTransactions = false

	private	let	serverPrefix :String
	private	let	multiValueQueryParameterHandling :MultiValueQueryParameterHandling
	private	let	maximumURLLength :Int
	private	let	urlSession :URLSession
	private	let	maximumConcurrentHTTPEndpointRequests :Int

	private	let	updateActiveHTTPEndpointRequestsLock = Lock()

	private	var	activeHTTPEndpointRequestInfos = LockingArray<HTTPEndpointRequestInfo>()
	private	var	queuedHTTPEndpointRequestInfos = LockingArray<HTTPEndpointRequestInfo>()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(serverPrefix :String, multiValueQueryParameterHandling :MultiValueQueryParameterHandling = .repeatKey,
			maximumURLLength :Int = 1024, urlSession :URLSession = URLSession.shared,
			maximumConcurrentHTTPEndpointRequests :Int? = nil) {
		// Store
		self.serverPrefix = serverPrefix
		self.multiValueQueryParameterHandling = multiValueQueryParameterHandling
		self.maximumURLLength = maximumURLLength
		self.urlSession = urlSession
		self.maximumConcurrentHTTPEndpointRequests =
				maximumConcurrentHTTPEndpointRequests ?? urlSession.configuration.httpMaximumConnectionsPerHost
	}

	//------------------------------------------------------------------------------------------------------------------
	convenience public init(scheme :String, hostName :String, port :Int? = nil,
			multiValueQueryParameterHandling :MultiValueQueryParameterHandling = .repeatKey,
			maximumURLLength :Int = 1024, urlSession :URLSession = URLSession.shared,
			maximumConcurrentHTTPEndpointRequests :Int? = nil) {
		// Setup
		let	serverPrefix = (port != nil) ? "\(scheme)://\(hostName):\(port!)" : "\(scheme)://\(hostName)"

		self.init(serverPrefix: serverPrefix, multiValueQueryParameterHandling: multiValueQueryParameterHandling,
				maximumURLLength: maximumURLLength, urlSession: urlSession,
				maximumConcurrentHTTPEndpointRequests: maximumConcurrentHTTPEndpointRequests)
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func queue(_ httpEndpointRequest :HTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal) {
		// Add to queue
		self.queuedHTTPEndpointRequestInfos.append((httpEndpointRequest, identifier, priority))

		// Update active
		updateActiveHTTPEndpointRequests()
	}

	//------------------------------------------------------------------------------------------------------------------
	public func queue(_ successHTTPEndpointRequest :SuccessHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal, completionProc :@escaping (_ error :Error?) -> Void) {
		// Setup
		successHTTPEndpointRequest.completionProc = completionProc

		// Perform
		queue(successHTTPEndpointRequest, identifier: identifier, priority: priority)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func queue(_ headHTTPEndpointRequest :HeadHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal,
			completionProc :@escaping (_ headers :[AnyHashable : Any]?, _ error :Error?) -> Void) {
		// Setup
		headHTTPEndpointRequest.completionProc = completionProc

		// Perform
		queue(headHTTPEndpointRequest, identifier: identifier, priority: priority)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func queue(_ dataHTTPEndpointRequest :DataHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal, completionProc :@escaping (_ data :Data?, _ error :Error?) -> Void) {
		// Setup
		dataHTTPEndpointRequest.completionProc = completionProc

		// Perform
		queue(dataHTTPEndpointRequest, identifier: identifier, priority: priority)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func queue(_ stringHTTPEndpointRequest :StringHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal, completionProc :@escaping (_ string :String?, _ error :Error?) -> Void) {
		// Setup
		stringHTTPEndpointRequest.completionProc = completionProc

		// Perform
		queue(stringHTTPEndpointRequest, identifier: identifier, priority: priority)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func queue<T>(_ jsonHTTPEndpointRequest :JSONHTTPEndpointRequest<T>, identifier :String = "",
			priority :Priority = .normal, completionProc :@escaping(_ info :T?, _ error :Error?) -> Void) {
		// Setup
		jsonHTTPEndpointRequest.completionProc = completionProc

		// Perform
		queue(jsonHTTPEndpointRequest, identifier: identifier, priority: priority)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func cancel(identifier :String) {
		// One at a time please...
		self.updateActiveHTTPEndpointRequestsLock.perform() {
			// Iterate all
			self.activeHTTPEndpointRequestInfos.forEach() {
				// Check identifier
				if $0.identifier == identifier {
					// Identifier matches, cancel
					$0.httpEndpointRequest.cancel()
				}
			}
			self.queuedHTTPEndpointRequestInfos.removeAll() {
				// Check identifier
				guard $0.identifier == identifier else { return false }

				// Identifier matches, cancel
				$0.httpEndpointRequest.cancel()

				return true
			}
		}
	}

	// MARK: Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func updateActiveHTTPEndpointRequests() {
		// One at a time please...
		self.updateActiveHTTPEndpointRequestsLock.perform() {
			// Remove finished
			self.activeHTTPEndpointRequestInfos.removeAll() { $0.httpEndpointRequest.state == .finished }

			// Ensure we have available active "slots"
			guard self.activeHTTPEndpointRequestInfos.count < self.maximumConcurrentHTTPEndpointRequests else { return }

			// Sort queued
			self.queuedHTTPEndpointRequestInfos.sort() { $0.priority.rawValue < $1.priority.rawValue }

			// Activate up to the maximum
			while (self.queuedHTTPEndpointRequestInfos.count > 0) &&
					(self.activeHTTPEndpointRequestInfos.count < self.maximumConcurrentHTTPEndpointRequests) {
				// Get first queued
				let	httpEndpointRequestInfo = self.queuedHTTPEndpointRequestInfos.removeFirst()
				let	httpEndpointRequest = httpEndpointRequestInfo.httpEndpointRequest
				guard !httpEndpointRequest.isCancelled else { continue }

				// Activate
				httpEndpointRequest.transition(to: .active)
				self.activeHTTPEndpointRequestInfos.append(httpEndpointRequestInfo)

				// Perform in background
				DispatchQueue.global().async() { [weak self] in
					// Ensure we are still around
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
						// Transition to finished
						httpEndpointRequest.transition(to: .finished)

						// Check if cancelled
						if !httpEndpointRequest.isCancelled {
							// Process results
							httpEndpointRequest.processResults(response: $1 as? HTTPURLResponse, data: $0, error: $2)
						}

						// Update
						strongSelf.updateActiveHTTPEndpointRequests()
					}).resume()
				}
			}
		}
	}
}
