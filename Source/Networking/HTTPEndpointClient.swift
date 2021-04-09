//
//  HTTPEndpointClient.swift
//  Swift Toolbox
//
//  Created by Stevo on 3/23/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: String extension
fileprivate extension String {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func urlQueryEncoded(encodePlus :Bool) -> String {
		//
		return encodePlus ?
				self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
						.replacingOccurrences(of: "+", with: "%2B") :
				self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HTTPEndpointRequest extension
fileprivate extension HTTPEndpointRequest {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func urlRequests(with serverPrefix :String, options :HTTPEndpointClient.Options, maximumURLLength :Int) ->
			[URLRequest] {
		// Setup
		var	urlRequests = [URLRequest]()
		let	addURLRequestProc :(_ url :URL) -> Void = {
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

					// Add URLRequest
					urlRequests.append(urlRequest)
				}

		// Check path
		if self.path.hasPrefix("http") || self.path.hasPrefix("https") {
			// Already have fully-formed URL
			addURLRequestProc(URL(string: self.path)!)
		} else {
			// Compose URLRequests
			let	queryComponents =
						self.queryComponents?.map() {
							// Return string
							"\($0.key)=\($0.value)"
									.urlQueryEncoded(encodePlus: options.contains(.percentEncodePlusCharacter))
						}
			let	queryString = String(combining: queryComponents ?? [], with: "&")
			let	hasQuery = !queryString.isEmpty || (self.multiValueQueryComponent != nil)
			let	urlRoot =
						serverPrefix + self.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)! +
								(hasQuery ? "?" : "") + queryString

			if let (key, values) = self.multiValueQueryComponent, !values.isEmpty {
				// Setup
				let	keyUse = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
				let	valuesUse =
							values.map()
								{ "\($0)".urlQueryEncoded(encodePlus: options.contains(.percentEncodePlusCharacter)) }

				// Check options
				var	queryComponent = ""
				if options.contains(.multiValueQueryUseComma) {
					// Use comma
					let	urlBase = !queryString.isEmpty ? "\(urlRoot)&\(keyUse)=" : "\(urlRoot)?\(keyUse)="
					valuesUse.forEach() {
						// Compose string with next value
						let	queryComponentTry = !queryComponent.isEmpty ? "\(queryComponent),\($0)" : "\(keyUse)=\($0)"
						if (urlBase.count + queryComponentTry.count) <= maximumURLLength {
							// We good
							queryComponent = queryComponentTry
						} else {
							// Add URL Request
							addURLRequestProc(URL(string: urlRoot + queryComponent)!)

							// Restart
							queryComponent = $0
						}
					}

					// Add final URL Request
					addURLRequestProc(URL(string: urlRoot + queryComponent)!)
				} else {
					// Repeat key
					let	urlBase = !queryString.isEmpty ? "\(urlRoot)&" : "\(urlRoot)?"
					valuesUse.forEach() {
						// Check if can add
						let	queryComponentTry =
									!queryComponent.isEmpty ? "\(queryComponent)&\(keyUse)=\($0)" : "\(keyUse)=\($0)"
						if (urlBase.count + queryComponentTry.count) <= maximumURLLength {
							// We good
							queryComponent = queryComponentTry
						} else {
							// Add URL Request
							addURLRequestProc(URL(string: urlRoot + queryComponent)!)

							// Restart
							queryComponent = "\(keyUse)=\($0)"
						}
					}

					// Add final URL Request
					addURLRequestProc(URL(string: urlRoot + queryComponent)!)
				}
			}

			// Check if have any URLRequests
			if urlRequests.isEmpty {
				// Generate URL Request
				addURLRequestProc(URL(string: urlRoot)!)
			}
		}

		return urlRequests
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HTTPEndpointClient
open class HTTPEndpointClient {

	// MARK: Types
	public struct Options : OptionSet {

		// MARK: Properties
		static	public	let	multiValueQueryUseComma = Options(rawValue: 1 << 0)
		static	public	let	percentEncodePlusCharacter = Options(rawValue: 1 << 1)

				public	let	rawValue :Int

		// MARK: Lifecycle methods
		public init(rawValue :Int) { self.rawValue = rawValue }
	}

	public enum Priority : Int {
		case normal
		case background
	}

	public struct LogOptions : OptionSet {

		// MARK: Properties
		static	public	let	requestAndResponse = LogOptions(rawValue: 1 << 0)
		static	public	let	requestQuery = LogOptions(rawValue: 1 << 1)
		static	public	let	requestHeaders = LogOptions(rawValue: 1 << 2)
		static	public	let	requestBody = LogOptions(rawValue: 1 << 3)
		static	public	let	requestBodySize = LogOptions(rawValue: 1 << 4)
		static	public	let	responseHeaders = LogOptions(rawValue: 1 << 5)
		static	public	let	responseBody = LogOptions(rawValue: 1 << 6)

				public	let	rawValue :Int

		// MARK: Lifecycle methods
		public init(rawValue :Int) { self.rawValue = rawValue }
	}

	class HTTPEndpointRequestInfo {

		// MARK: Properties
				let	httpEndpointRequest :HTTPEndpointRequest
				let	identifier :String
				let	priority :Priority

		private	var	totalPerformInfosCount = 0
		private	var	finishedPerformInfosCount = LockingNumeric<Int>()

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(httpEndpointRequest :HTTPEndpointRequest, identifier :String, priority :Priority) {
			// Store
			self.httpEndpointRequest = httpEndpointRequest
			self.identifier = identifier
			self.priority = priority
		}

		// MARK: Instance methods
		//--------------------------------------------------------------------------------------------------------------
		func httpEndpointRequestPerformInfos(serverPrefix :String, options :Options, maximumURLLength :Int) ->
				[HTTPEndpointRequestPerformInfo] {
			// Setup
			let	urlRequests =
						self.httpEndpointRequest.urlRequests(with: serverPrefix, options: options,
								maximumURLLength: maximumURLLength)
			self.totalPerformInfosCount = urlRequests.count

			// Check HTTPEndpointRequest type
			if let httpEndpointRequestProcessResults = self.httpEndpointRequest as? HTTPEndpointRequestProcessResults {
				// Will only ever be a single URLRequest
				return urlRequests
						.map({ HTTPEndpointRequestPerformInfo(httpEndpointRequestInfo: self, urlRequest: $0,
								completionProc: {
									// Process results
									httpEndpointRequestProcessResults.processResults(response: $0, data: $1, error: $2)
								}) })
			} else {
				// Can end up being multiple URLRequests
				let	httpEndpointRequestProcessMultiResults =
							self.httpEndpointRequest as! HTTPEndpointRequestProcessMultiResults
				let	urlRequestsCount = self.totalPerformInfosCount

				return urlRequests
						.map({ HTTPEndpointRequestPerformInfo(httpEndpointRequestInfo: self, urlRequest: $0,
								completionProc: {
									// Process results
									httpEndpointRequestProcessMultiResults.processResults(response: $0, data: $1,
											error: $2, totalRequests: urlRequestsCount)
								}) })
			}
		}

		//--------------------------------------------------------------------------------------------------------------
		func transition(to state :HTTPEndpointRequest.State) {
			// Check state
			if (state == .active) && (self.httpEndpointRequest.state == .queued) {
				// Transition to active
				self.httpEndpointRequest.transition(to: .active)
			} else if state == .finished {
				// One more finished
				if self.finishedPerformInfosCount.add(1) == self.totalPerformInfosCount {
					// Finished finished
					self.httpEndpointRequest.transition(to: .finished)
				}
			}
		}
	}

	class HTTPEndpointRequestPerformInfo {

		// MARK: Types
		typealias CompletionProc = (_ response :HTTPURLResponse?, _ data :Data?, _ error :Error?) -> Void

		// MARK: Properties
						let	urlRequest :URLRequest

						var	httpEndpointRequest :HTTPEndpointRequest
								{ self.httpEndpointRequestInfo.httpEndpointRequest }
						var	identifier :String { self.httpEndpointRequestInfo.identifier }
						var	priority :Priority { self.httpEndpointRequestInfo.priority }
						var	isCancelled :Bool { self.httpEndpointRequestInfo.httpEndpointRequest.isCancelled }

		private(set)	var	state :HTTPEndpointRequest.State = .queued

		private			let	httpEndpointRequestInfo :HTTPEndpointRequestInfo
		private			let	completionProc :CompletionProc

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(httpEndpointRequestInfo :HTTPEndpointRequestInfo, urlRequest :URLRequest,
				completionProc :@escaping CompletionProc) {
			// Store
			self.urlRequest = urlRequest

			self.httpEndpointRequestInfo = httpEndpointRequestInfo
			self.completionProc = completionProc
		}

		// MARK: Instance methods
		//--------------------------------------------------------------------------------------------------------------
		func transition(to state :HTTPEndpointRequest.State) {
			// Update state
			self.state = state

			// Inform HTTPEndpointRequestInfo
			self.httpEndpointRequestInfo.transition(to: state)
		}

		//--------------------------------------------------------------------------------------------------------------
		func cancel() { self.httpEndpointRequestInfo.httpEndpointRequest.cancel() }

		//--------------------------------------------------------------------------------------------------------------
		func processResults(response :HTTPURLResponse?, data :Data?, error :Error?) {
			// Process results
			if response != nil {
				// Have a response
				let	statusCode = response!.statusCode
				if statusCode == HTTPEndpointStatus.ok.rawValue {
					// Success
					self.completionProc(response, data, nil)
				} else {
					// Some other response
					self.completionProc(response, nil,
							HTTPEndpointStatusError(status: HTTPEndpointStatus(rawValue: statusCode)!))
				}
			} else {
				// Error
				self.completionProc(response, nil, error)
			}
		}
	}

	// MARK: Properties
	static	public	var	logProc :(_ messages :[String]) -> Void = { $0.forEach() { NSLog($0) } }

			public	var	logOptions = LogOptions()

			private	let	serverPrefix :String
			private	let	options :Options
			private	let	maximumURLLength :Int
			private	let	urlSession :URLSession
			private	let	maximumConcurrentURLRequests :Int

			private	let	updateActiveHTTPEndpointRequestPerformInfosLock = Lock()

			private	var	activeHTTPEndpointRequestPerformInfos = LockingArray<HTTPEndpointRequestPerformInfo>()
			private	var	queuedHTTPEndpointRequestPerformInfos = LockingArray<HTTPEndpointRequestPerformInfo>()
			private	var	httpRequestIndex = 0

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(serverPrefix :String, options :Options = [], maximumURLLength :Int = 1024,
			urlSession :URLSession = URLSession.shared, maximumConcurrentURLRequests :Int? = nil) {
		// Store
		self.serverPrefix = serverPrefix
		self.options = options
		self.maximumURLLength = maximumURLLength
		self.urlSession = urlSession
		self.maximumConcurrentURLRequests =
				maximumConcurrentURLRequests ?? urlSession.configuration.httpMaximumConnectionsPerHost
	}

	//------------------------------------------------------------------------------------------------------------------
	public init(scheme :String, hostName :String, port :Int? = nil, options :Options = [], maximumURLLength :Int = 1024,
			urlSession :URLSession = URLSession.shared, maximumConcurrentURLRequests :Int? = nil) {
		// Store
		self.serverPrefix = (port != nil) ? "\(scheme)://\(hostName):\(port!)" : "\(scheme)://\(hostName)"
		self.options = options
		self.maximumURLLength = maximumURLLength
		self.urlSession = urlSession
		self.maximumConcurrentURLRequests =
				maximumConcurrentURLRequests ?? urlSession.configuration.httpMaximumConnectionsPerHost
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func queue(_ httpEndpointRequest :HTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal) {
		// Add to queue
		let	httpEndpointRequestInfo =
					HTTPEndpointRequestInfo(httpEndpointRequest: httpEndpointRequest, identifier: identifier,
							priority: priority)
		self.queuedHTTPEndpointRequestPerformInfos +=
				httpEndpointRequestInfo.httpEndpointRequestPerformInfos(serverPrefix: self.serverPrefix,
						options: self.options, maximumURLLength: self.maximumURLLength)

		// Update active
		updateHTTPEndpointRequestPerformInfos()
	}

	//------------------------------------------------------------------------------------------------------------------
	public func queue(_ dataHTTPEndpointRequest :DataHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal, completionProc :@escaping DataHTTPEndpointRequest.CompletionProc) {
		// Setup
		dataHTTPEndpointRequest.completionProc = completionProc

		// Queue
		queue(dataHTTPEndpointRequest, identifier: identifier, priority: priority)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func queue(_ fileHTTPEndpointRequest :FileHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal, completionProc :@escaping FileHTTPEndpointRequest.CompletionProc) {
		// Setup
		fileHTTPEndpointRequest.completionProc = completionProc

		// Queue
		queue(fileHTTPEndpointRequest, identifier: identifier, priority: priority)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func queue(_ headHTTPEndpointRequest :HeadHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal, completionProc :@escaping HeadHTTPEndpointRequest.CompletionProc) {
		// Setup
		headHTTPEndpointRequest.completionProc = completionProc

		// Queue
		queue(headHTTPEndpointRequest, identifier: identifier, priority: priority)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func queue(_ integerHTTPEndpointRequest :IntegerHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal, completionProc :@escaping IntegerHTTPEndpointRequest.CompletionProc) {
		// Setup
		integerHTTPEndpointRequest.completionProc = completionProc

		// Queue
		queue(integerHTTPEndpointRequest, identifier: identifier, priority: priority)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func queue<T>(_ jsonHTTPEndpointRequest :JSONHTTPEndpointRequest<T>, identifier :String = "",
			priority :Priority = .normal,
			completionProc :@escaping JSONHTTPEndpointRequest<T>.SingleResponseCompletionProc) {
		// Setup
		jsonHTTPEndpointRequest.completionProc = completionProc

		// Queue
		queue(jsonHTTPEndpointRequest, identifier: identifier, priority: priority)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func queue<T>(_ jsonHTTPEndpointRequest :JSONHTTPEndpointRequest<T>, identifier :String = "",
			priority :Priority = .normal,
			partialResultsProc :@escaping JSONHTTPEndpointRequest<T>.MultiResponsePartialResultsProc,
			completionProc :@escaping JSONHTTPEndpointRequest<T>.MultiResponseCompletionProc) {
		// Setup
		jsonHTTPEndpointRequest.multiResponsePartialResultsProc = partialResultsProc
		jsonHTTPEndpointRequest.multiResponseCompletionProc = completionProc

		// Queue
		queue(jsonHTTPEndpointRequest, identifier: identifier, priority: priority)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func queue(_ stringHTTPEndpointRequest :StringHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal, completionProc :@escaping StringHTTPEndpointRequest.CompletionProc) {
		// Setup
		stringHTTPEndpointRequest.completionProc = completionProc

		// Queue
		queue(stringHTTPEndpointRequest, identifier: identifier, priority: priority)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func queue(_ successHTTPEndpointRequest :SuccessHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal, completionProc :@escaping SuccessHTTPEndpointRequest.CompletionProc) {
		// Setup
		successHTTPEndpointRequest.completionProc = completionProc

		// Queue
		queue(successHTTPEndpointRequest, identifier: identifier, priority: priority)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func cancel(identifier :String = "") {
		// One at a time please...
		self.updateActiveHTTPEndpointRequestPerformInfosLock.perform() {
			// Iterate all
			self.activeHTTPEndpointRequestPerformInfos.forEach() {
				// Check identifier
				if $0.identifier == identifier {
					// Identifier matches, cancel
					$0.cancel()
				}
			}
			self.queuedHTTPEndpointRequestPerformInfos.removeAll() {
				// Check identifier
				guard $0.identifier == identifier else { return false }

				// Identifier matches, cancel
				$0.cancel()

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
			self.queuedHTTPEndpointRequestPerformInfos.sort() { $0.priority.rawValue < $1.priority.rawValue }

			// Activate up to the maximum
			while (self.queuedHTTPEndpointRequestPerformInfos.count > 0) &&
					(self.activeHTTPEndpointRequestPerformInfos.count < self.maximumConcurrentURLRequests) {
				// Get first queued
				let	httpEndpointRequestPerformInfo = self.queuedHTTPEndpointRequestPerformInfos.removeFirst()
				guard !httpEndpointRequestPerformInfo.isCancelled else { continue }

				let	urlRequest = httpEndpointRequestPerformInfo.urlRequest

				let	httpRequestIndex = self.httpRequestIndex
				self.httpRequestIndex += 1

				// Make active
				httpEndpointRequestPerformInfo.transition(to: .active)
				self.activeHTTPEndpointRequestPerformInfos.append(httpEndpointRequestPerformInfo)

				// Perform in background
				DispatchQueue.global().async() { [weak self] in
					// Ensure we are still around
					guard let strongSelf = self else { return }

					// Log
					let	logOptions = strongSelf.logOptions
					let	className = String(describing: type(of: strongSelf))
					let	urlRequestInfo =
								"\(urlRequest.url!.host ?? "unknown"):\(urlRequest.url!.path) (\(httpRequestIndex))"
					if logOptions.contains(.requestAndResponse) {
						// Setup
						var	logMessages = [String]()

						// Log request
						logMessages.append("\(className): \(urlRequest.httpMethod!) to \(urlRequestInfo)")
						if logOptions.contains(.requestQuery) {
							// Log query
							logMessages.append("    Query: \(urlRequest.url!.query ?? "n/a")")
						}
						if logOptions.contains(.requestHeaders) {
							// Log headers
							logMessages.append("    Headers: \(urlRequest.allHTTPHeaderFields ?? [:])")
						}
						if logOptions.contains(.requestBody) {
							// Log body
							logMessages.append(
									"    Body: \(String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? "unable to decode")")
						}
						if logOptions.contains(.requestBodySize) &&
								httpEndpointRequestPerformInfo.httpEndpointRequest.method.supportsBodyData {
							// Log body size
							logMessages.append(
									"    Body size: \((urlRequest.httpBody ?? Data()).count) bytes")
						}
						HTTPEndpointClient.logProc(logMessages)
					}

					// Resume data task
					let	startDate = Date()
					strongSelf.urlSession.dataTask(with: urlRequest, completionHandler: {
						// Log
						if logOptions.contains(.requestAndResponse) {
							// Setup
							let	deltaTime = Date().timeIntervalSince(startDate)
							var	logMessages = [String]()

							// Log response
							if $1 != nil {
								// Success
								let	httpURLResponse = $1 as! HTTPURLResponse
								logMessages.append(
										"    \(className) received status \(httpURLResponse.statusCode) for \(urlRequestInfo) in \(String(format: "%0.3f", deltaTime))s")
								if logOptions.contains(.responseHeaders) {
									// Log headers
									logMessages.append("        Headers: \(httpURLResponse.allHeaderFields)")
								}
								if logOptions.contains(.responseBody) {
									// Log body
									logMessages.append(
											"        Body: \(String(data: $0 ?? Data(), encoding: .utf8) ?? "unable to decode")")
								}
							} else {
								// Error
								logMessages.append("    \(className) received error \($2!) for \(urlRequestInfo)")
							}
							HTTPEndpointClient.logProc(logMessages)
						}

						// Transition to finished
						httpEndpointRequestPerformInfo.transition(to: .finished)

						// Check if cancelled
						if !httpEndpointRequestPerformInfo.isCancelled {
							// Process results
							httpEndpointRequestPerformInfo.processResults(response: $1 as? HTTPURLResponse, data: $0,
									error: $2)
						}

						// Update
						strongSelf.updateHTTPEndpointRequestPerformInfos()
					}).resume()
				}
			}
		}
	}
}
