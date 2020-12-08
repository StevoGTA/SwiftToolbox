//
//  HTTPEndpointClient.swift
//  Swift Toolbox
//
//  Created by Stevo on 3/23/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: HTTPEndpointRequest extension
extension HTTPEndpointRequest {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	fileprivate func urlRequests(with serverPrefix :String,
			multiValueQueryParameterHandling :HTTPEndpointClient.MultiValueQueryParameterHandling,
			maximumURLLength :Int) -> [URLRequest] {
		// Setup
		let	urlRequestProc :(_ url :URL) -> URLRequest = {
					// Setup URLRequest
					var	urlRequest = URLRequest(url: $0)
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

		var	urlRequests = [URLRequest]()
		if self.path.hasPrefix("http") || self.path.hasPrefix("https") {
			// Already have fully-formed URL
			urlRequests.append(urlRequestProc(URL(string: self.path)!))
		} else {
			// Compose URL
			let	queryString =
						String(combining: self.queryComponents?.map({ "\($0.key)=\($0.value)" }) ?? [],
										with: "&")
								.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
			let	urlRequestRoot =
						serverPrefix + self.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)! +
								(!queryString.isEmpty ? "?" + queryString : "")

			var	multiValueQueryString = ""
			let	canAppendQueryComponentProc :( _ queryComponent :String) -> Bool = {
						// Compose target string
						let	string =
									urlRequestRoot + (queryString.isEmpty ? "?" : "&") +
											(multiValueQueryString.isEmpty ? $0 : multiValueQueryString + "&" + $0)
													.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

						return string.count <= maximumURLLength
					}
			let	appendQueryComponentProc :(_ queryComponent :String) -> Void =
					{ multiValueQueryString = multiValueQueryString.isEmpty ? $0 : multiValueQueryString + "&" + $0 }
			let	generateURLRequestProc :() -> Void = {
						// Append URL Request
						let	string =
									urlRequestRoot + (queryString.isEmpty ? "?" : "&") +
											multiValueQueryString
													.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
						urlRequests.append(urlRequestProc(URL(string: string)!))

						// Reset
						multiValueQueryString = ""
					}
			let	processQueryComponentProc :(_ queryComponent :String) -> Void = {
						// Check if can append
						if !canAppendQueryComponentProc($0) {
							// Generate URL Request
							generateURLRequestProc()
						}

						// Append query component
						appendQueryComponentProc($0)
					}

			if let (key, values) = self.multiValueQueryComponent {
				// Check type
				switch multiValueQueryParameterHandling {
					case .repeatKey:
						// Repeat key
						values.forEach() { processQueryComponentProc("\(key)=\($0)") }

					case .useComma:
						// Use comma
						var	queryComponent = ""
						values.forEach() {
							// Compose string with next value
							let	queryComponentTry = (!queryComponent.isEmpty ? "," : "\(key)=") + "\($0)"
							if canAppendQueryComponentProc(queryComponentTry) {
								// We good
								queryComponent = queryComponentTry
							} else {
								// Generate URL Request
								appendQueryComponentProc(queryComponent)
								generateURLRequestProc()

								// Reset
								queryComponent = ""
							}
						}

						// Check if have any remaining
						if !queryComponent.isEmpty {
							// Append
							appendQueryComponentProc(queryComponent)
						}
				}
			}

			// Check if have query string remaining
			if urlRequests.isEmpty || !multiValueQueryString.isEmpty {
				// Generate URL Request
				generateURLRequestProc()
			}
		}

		return urlRequests
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

	class HTTPEndpointRequestInfo {

		// MARK: Properties
				let	httpEndpointRequest :HTTPEndpointRequest
				let	identifier :String
				let	priority :Priority

				let	urlRequests :[URLRequest]

		private	var	finishedURLRequestsCount = 0

		// MARK: Lifecycle methods
		init(httpEndpointRequest :HTTPEndpointRequest, serverPrefix :String,
					multiValueQueryParameterHandling :HTTPEndpointClient.MultiValueQueryParameterHandling,
					maximumURLLength :Int, identifier :String, priority :Priority) {
			// Store
			self.httpEndpointRequest = httpEndpointRequest
			self.identifier = identifier
			self.priority = priority

			// Setup
			self.urlRequests =
					httpEndpointRequest.urlRequests(with: serverPrefix,
							multiValueQueryParameterHandling: multiValueQueryParameterHandling,
							maximumURLLength: maximumURLLength)
		}

		// MARK: Instance methods
		func transition(urlRequest :URLRequest, to state :HTTPEndpointRequest.State) {
			// Check state
			if (state == .active) && (self.httpEndpointRequest.state == .queued) {
				// Transition to active
				self.httpEndpointRequest.transition(to: .active)
			} else if state == .finished {
				// One more finished
				self.finishedURLRequestsCount += 1

				// Check if finished finished
				if self.finishedURLRequestsCount == self.urlRequests.count {
					// Finished finished
					self.httpEndpointRequest.transition(to: .finished)
				}
			}
		}
	}

	class HTTPEndpointRequestPerformInfo {

		// MARK: Properties
						let	httpEndpointRequestInfo :HTTPEndpointRequestInfo
						let	urlRequest :URLRequest

		private(set)	var	state :HTTPEndpointRequest.State = .queued

						var	isCancelled :Bool { self.httpEndpointRequestInfo.httpEndpointRequest.isCancelled }

		// MARK: Lifecycle methods
		init(httpEndpointRequestInfo :HTTPEndpointRequestInfo, urlRequest :URLRequest) {
			// Store
			self.httpEndpointRequestInfo = httpEndpointRequestInfo
			self.urlRequest = urlRequest
		}

		// MARK: Instance methods
		func transition(to state :HTTPEndpointRequest.State) { self.state = state }
	}

	// MARK: Properties
			var	logTransactions = false

	private	let	serverPrefix :String
	private	let	multiValueQueryParameterHandling :MultiValueQueryParameterHandling
	private	let	maximumURLLength :Int
	private	let	urlSession :URLSession
	private	let	maximumConcurrentURLRequests :Int

	private	let	updateActiveHTTPEndpointRequestPerformInfosLock = Lock()

	private	var	activeHTTPEndpointRequestPerformInfos = LockingArray<HTTPEndpointRequestPerformInfo>()
	private	var	queuedHTTPEndpointRequestPerformInfos = LockingArray<HTTPEndpointRequestPerformInfo>()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(serverPrefix :String, multiValueQueryParameterHandling :MultiValueQueryParameterHandling = .repeatKey,
			maximumURLLength :Int = 1024, urlSession :URLSession = URLSession.shared,
			maximumConcurrentURLRequests :Int? = nil) {
		// Store
		self.serverPrefix = serverPrefix
		self.multiValueQueryParameterHandling = multiValueQueryParameterHandling
		self.maximumURLLength = maximumURLLength
		self.urlSession = urlSession
		self.maximumConcurrentURLRequests =
				maximumConcurrentURLRequests ?? urlSession.configuration.httpMaximumConnectionsPerHost
	}

	//------------------------------------------------------------------------------------------------------------------
	convenience public init(scheme :String, hostName :String, port :Int? = nil,
			multiValueQueryParameterHandling :MultiValueQueryParameterHandling = .repeatKey,
			maximumURLLength :Int = 1024, urlSession :URLSession = URLSession.shared,
			maximumConcurrentURLRequests :Int? = nil) {
		// Setup
		let	serverPrefix = (port != nil) ? "\(scheme)://\(hostName):\(port!)" : "\(scheme)://\(hostName)"

		self.init(serverPrefix: serverPrefix, multiValueQueryParameterHandling: multiValueQueryParameterHandling,
				maximumURLLength: maximumURLLength, urlSession: urlSession,
				maximumConcurrentURLRequests: maximumConcurrentURLRequests)
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func queue(_ httpEndpointRequest :HTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal) {
		// Setup
		let	httpEndpointRequestInfo =
					HTTPEndpointRequestInfo(httpEndpointRequest: httpEndpointRequest, serverPrefix: self.serverPrefix,
							multiValueQueryParameterHandling: self.multiValueQueryParameterHandling,
							maximumURLLength: self.maximumURLLength, identifier: identifier, priority: priority)
		httpEndpointRequestInfo.urlRequests.forEach() {
			// Add to queued
			self.queuedHTTPEndpointRequestPerformInfos.append(
					HTTPEndpointRequestPerformInfo(httpEndpointRequestInfo: httpEndpointRequestInfo, urlRequest: $0))
		}

		// Update active
		updateHTTPEndpointRequestPerformInfos()
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
	public func queue(_ fileHTTPEndpointRequest :FileHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal, completionProc :@escaping (_ error :Error?) -> Void) {
		// Setup
		fileHTTPEndpointRequest.completionProc = completionProc

		// Perform
		queue(fileHTTPEndpointRequest, identifier: identifier, priority: priority)
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
	public func queue<T>(_ jsonHTTPEndpointRequest :JSONHTTPEndpointRequest<T>, identifier :String = "",
			priority :Priority = .normal, completionProc :@escaping(_ info :T?, _ error :Error?) -> Void) {
		// Setup
		jsonHTTPEndpointRequest.completionProc = completionProc

		// Perform
		queue(jsonHTTPEndpointRequest, identifier: identifier, priority: priority)
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
	public func queue(_ successHTTPEndpointRequest :SuccessHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal, completionProc :@escaping (_ error :Error?) -> Void) {
		// Setup
		successHTTPEndpointRequest.completionProc = completionProc

		// Perform
		queue(successHTTPEndpointRequest, identifier: identifier, priority: priority)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func cancel(identifier :String) {
		// One at a time please...
		self.updateActiveHTTPEndpointRequestPerformInfosLock.perform() {
			// Iterate all
			self.activeHTTPEndpointRequestPerformInfos.forEach() {
				// Check identifier
				if $0.httpEndpointRequestInfo.identifier == identifier {
					// Identifier matches, cancel
					$0.httpEndpointRequestInfo.httpEndpointRequest.cancel()
				}
			}
			self.queuedHTTPEndpointRequestPerformInfos.removeAll() {
				// Check identifier
				guard $0.httpEndpointRequestInfo.identifier == identifier else { return false }

				// Identifier matches, cancel
				$0.httpEndpointRequestInfo.httpEndpointRequest.cancel()

				return true
			}
		}
	}

	// MARK: Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func updateHTTPEndpointRequestPerformInfos() {
		// One at a time please...
		self.updateActiveHTTPEndpointRequestPerformInfosLock.perform() {
			// Remove finished
			self.activeHTTPEndpointRequestPerformInfos.removeAll() { $0.state == .finished }

			// Ensure we have available active "slots"
			guard self.activeHTTPEndpointRequestPerformInfos.count < self.maximumConcurrentURLRequests else { return }

			// Sort queued
			self.queuedHTTPEndpointRequestPerformInfos.sort()
				{ $0.httpEndpointRequestInfo.priority.rawValue < $1.httpEndpointRequestInfo.priority.rawValue }

			// Activate up to the maximum
			while (self.queuedHTTPEndpointRequestPerformInfos.count > 0) &&
					(self.activeHTTPEndpointRequestPerformInfos.count < self.maximumConcurrentURLRequests) {
				// Get first queued
				let	httpEndpointRequestPerformInfo = self.queuedHTTPEndpointRequestPerformInfos.removeFirst()
				guard !httpEndpointRequestPerformInfo.isCancelled else { continue }

				let	httpEndpointRequestInfo = httpEndpointRequestPerformInfo.httpEndpointRequestInfo
				let	urlRequest = httpEndpointRequestPerformInfo.urlRequest

				// Activate
				httpEndpointRequestPerformInfo.transition(to: .active)
				httpEndpointRequestInfo.transition(urlRequest: urlRequest, to: .active)
				self.activeHTTPEndpointRequestPerformInfos.append(httpEndpointRequestPerformInfo)

				// Perform in background
				DispatchQueue.global().async() { [weak self] in
					// Ensure we are still around
					guard let strongSelf = self else { return }
					let	logTransactions = strongSelf.logTransactions

					// Log
					if logTransactions { NSLog("HTTPEndpointClient - sending \(urlRequest)") }

					// Resume data task
					strongSelf.urlSession.dataTask(with: urlRequest, completionHandler: {
						// Log
						if logTransactions {
							// Check situation
							if $1 != nil {
								// Success
								NSLog("HTTPEndpointClient - received \($1!)")
							} else {
								// Error
								NSLog("HTTPEndpointClinet - received error \($2!) for request \(urlRequest)")
							}
						}

						// Transition to finished
						httpEndpointRequestPerformInfo.transition(to: .finished)
						httpEndpointRequestInfo.transition(urlRequest: urlRequest, to: .finished)

						// Check if cancelled
						if !httpEndpointRequestPerformInfo.isCancelled {
							// Process results
							httpEndpointRequestPerformInfo.httpEndpointRequestInfo.httpEndpointRequest.processResults(
									response: $1 as? HTTPURLResponse, data: $0, error: $2)
						}

						// Update
						strongSelf.updateHTTPEndpointRequestPerformInfos()
					}).resume()
				}
			}
		}
	}
}
