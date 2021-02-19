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
	fileprivate func urlRequests(with serverPrefix :String, options :HTTPEndpointClient.Options, maximumURLLength :Int)
			-> [URLRequest] {
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
						var	string =
									urlRequestRoot +
											(!multiValueQueryString.isEmpty ?
													(queryString.isEmpty ? "?" : "&") +
															multiValueQueryString
																	.addingPercentEncoding(
																			withAllowedCharacters: .urlQueryAllowed)! :
													"")
						if options.contains(.percentEncodePlusCharacter) {
							// Percent encode "+"
							string = string.replacingOccurrences(of: "+", with: "%2B")
						}

						// Add URL
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
				if options.contains(.multiValueQueryUseComma) {
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
				} else {
					// Repeat key
					values.forEach() { processQueryComponentProc("\(key)=\($0)") }
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
		static	public	let	callAndResponse = LogOptions(rawValue: 1 << 0)
		static	public	let	query = LogOptions(rawValue: 1 << 1)
		static	public	let	callHeaders = LogOptions(rawValue: 1 << 2)
		static	public	let	callBody = LogOptions(rawValue: 1 << 3)
		static	public	let	responseHeaders = LogOptions(rawValue: 1 << 4)
		static	public	let	responseBody = LogOptions(rawValue: 1 << 5)

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
									// Call process results
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
									// Call process results
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
				if self.finishedPerformInfosCount.add(1).value == self.totalPerformInfosCount {
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

						var	identifier :String { self.httpEndpointRequestInfo.identifier }
						var	priority :Priority { self.httpEndpointRequestInfo.priority }
		private(set)	var	state :HTTPEndpointRequest.State = .queued

						var	isCancelled :Bool { self.httpEndpointRequestInfo.httpEndpointRequest.isCancelled }

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
			if let statusCode = response?.statusCode,
					let httpEndpointStatus = HTTPEndpointStatus(rawValue: statusCode) {
				// Have a response
				if httpEndpointStatus == .ok {
					// Success
					self.completionProc(response, data, nil)
				} else {
					// HTTP Request failed
					self.completionProc(response, nil, HTTPEndpointStatusError(status: httpEndpointStatus))
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
		// Setup
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

		// Perform
		queue(dataHTTPEndpointRequest, identifier: identifier, priority: priority)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func queue(_ fileHTTPEndpointRequest :FileHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal, completionProc :@escaping FileHTTPEndpointRequest.CompletionProc) {
		// Setup
		fileHTTPEndpointRequest.completionProc = completionProc

		// Perform
		queue(fileHTTPEndpointRequest, identifier: identifier, priority: priority)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func queue(_ headHTTPEndpointRequest :HeadHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal, completionProc :@escaping HeadHTTPEndpointRequest.CompletionProc) {
		// Setup
		headHTTPEndpointRequest.completionProc = completionProc

		// Perform
		queue(headHTTPEndpointRequest, identifier: identifier, priority: priority)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func queue(_ integerHTTPEndpointRequest :IntegerHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal, completionProc :@escaping IntegerHTTPEndpointRequest.CompletionProc) {
		// Setup
		integerHTTPEndpointRequest.completionProc = completionProc

		// Perform
		queue(integerHTTPEndpointRequest, identifier: identifier, priority: priority)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func queue<T>(_ jsonHTTPEndpointRequest :JSONHTTPEndpointRequest<T>, identifier :String = "",
			priority :Priority = .normal,
			completionProc :@escaping JSONHTTPEndpointRequest<T>.SingleResponseCompletionProc) {
		// Setup
		jsonHTTPEndpointRequest.completionProc = completionProc

		// Perform
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

		// Perform
		queue(jsonHTTPEndpointRequest, identifier: identifier, priority: priority)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func queue(_ stringHTTPEndpointRequest :StringHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal, completionProc :@escaping StringHTTPEndpointRequest.CompletionProc) {
		// Setup
		stringHTTPEndpointRequest.completionProc = completionProc

		// Perform
		queue(stringHTTPEndpointRequest, identifier: identifier, priority: priority)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func queue(_ successHTTPEndpointRequest :SuccessHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal, completionProc :@escaping SuccessHTTPEndpointRequest.CompletionProc) {
		// Setup
		successHTTPEndpointRequest.completionProc = completionProc

		// Perform
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

				// Activate
				httpEndpointRequestPerformInfo.transition(to: .active)
				self.activeHTTPEndpointRequestPerformInfos.append(httpEndpointRequestPerformInfo)

				// Perform in background
				DispatchQueue.global().async() { [weak self] in
					// Ensure we are still around
					guard let strongSelf = self else { return }

					// Log
					let	logOptions = strongSelf.logOptions
					let	className = String(describing: type(of: strongSelf))
					if logOptions.contains(.callAndResponse) {
						// Setup
						var	logMessages = [String]()

						// Log call
						logMessages.append(
								"\(className): \(urlRequest.httpMethod!) to \(urlRequest.url!.host ?? "unknown"):\(urlRequest.url!.path) (\(httpRequestIndex))")

						if logOptions.contains(.query) {
							// Log query
							logMessages.append("    Query: \(urlRequest.url!.query ?? "n/a")")
						}
						if logOptions.contains(.callHeaders) {
							// Log headers
							logMessages.append("    Headers: \(urlRequest.allHTTPHeaderFields ?? [:])")
						}
						if logOptions.contains(.callBody) {
							// Log body
							logMessages.append(
									"    Body: \(String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? "unable to decode")")
						}
						HTTPEndpointClient.logProc(logMessages)
					}

					// Resume data task
					let	date = Date()
					strongSelf.urlSession.dataTask(with: urlRequest, completionHandler: {
						// Log
						if logOptions.contains(.callAndResponse) {
							// Setup
							let	deltaTime = Date().timeIntervalSince(date)
							var	logMessages = [String]()

							// Log response
							if $1 != nil {
								// Success
								let	httpURLResponse = $1 as! HTTPURLResponse
								logMessages.append(
										"    \(className) received status \(httpURLResponse.statusCode) for \(urlRequest.url!.host ?? "unknown"):\(urlRequest.url!.path) (\(httpRequestIndex)) in \(String(format: "%0.3f", deltaTime))s")

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
								logMessages.append("    \(className) received error \($2!) for \(httpRequestIndex)")
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
