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
		// Return encoded string
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
						case .delete:	urlRequest.httpMethod = "DELETE"
						case .get:		urlRequest.httpMethod = "GET"
						case .head:		urlRequest.httpMethod = "HEAD"
						case .patch:	urlRequest.httpMethod = "PATCH"
						case .post:		urlRequest.httpMethod = "POST"
						case .put:		urlRequest.httpMethod = "PUT"
					}
					self.headers?.forEach() { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
					urlRequest.timeoutInterval = self.timeoutInterval
					urlRequest.httpBody = !self.options.contains(.deferBodyUntilRedirect) ? self.bodyData : nil

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
						self.queryComponents?
								.flatMap({ key, value in
									// Check type
									if let array = value as? [String] {
										// Array of Strings
										return array.map({ (key, $0) })
									} else {
										// String
										return [(key, "\(value)")]
									}
								})
								.map({
									"\($0.0)=\($0.1)"
											.urlQueryEncoded(
													encodePlus: options.contains(.percentEncodePlusCharacter))
								})
			let	queryString = String(combining: queryComponents ?? [], with: "&")
			let	hasQuery = !queryString.isEmpty || (self.multiValueQueryComponent != nil)
			let	urlRoot = serverPrefix + self.path + (hasQuery ? "?" : "") + queryString

			if let (key, values) = self.multiValueQueryComponent, !values.isEmpty {
				// Setup
				let	keyUse = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
				let	valuesUse =
							values.map() { value -> String in
									// Check value type
									if let string = value as? String {
										// String
										return string.urlQueryEncoded(
												encodePlus: options.contains(.percentEncodePlusCharacter))
									} else {
										// Not string
										return "\(value)"
									}
								}

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
							addURLRequestProc(URL(string: urlBase + queryComponent)!)

							// Restart
							queryComponent = $0
						}
					}

					// Add final URL Request
					addURLRequestProc(URL(string: urlBase + queryComponent)!)
				} else {
					// Repeat key
					let	urlBase = !queryString.isEmpty ? "\(urlRoot)&" : urlRoot
					valuesUse.forEach() {
						// Check if can add
						let	queryComponentTry =
									!queryComponent.isEmpty ? "\(queryComponent)&\(keyUse)=\($0)" : "\(keyUse)=\($0)"
						if (urlBase.count + queryComponentTry.count) <= maximumURLLength {
							// We good
							queryComponent = queryComponentTry
						} else {
							// Add URL Request
							addURLRequestProc(URL(string: urlBase + queryComponent)!)

							// Restart
							queryComponent = "\(keyUse)=\($0)"
						}
					}

					// Add final URL Request
					addURLRequestProc(URL(string: urlBase + queryComponent)!)
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
open class HTTPEndpointClient : NSObject, URLSessionDelegate {

	// MARK: Options
	public struct Options : OptionSet {

		// MARK: Properties
		static	public	let	multiValueQueryUseComma = Options(rawValue: 1 << 0)
		static	public	let	percentEncodePlusCharacter = Options(rawValue: 1 << 1)

				public	let	rawValue :Int

		// MARK: Lifecycle methods
		public init(rawValue :Int) { self.rawValue = rawValue }
	}

	// MARK: Priority
	public enum Priority : Int {
		case normal
		case background
	}

	// MARK: LogOptions
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

	//------------------------------------------------------------------------------------------------------------------
	// MARK: HTTPEndpointRequestInfo
	private class HTTPEndpointRequestInfo {

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
			if let fileHTTPEndpointRequest = self.httpEndpointRequest as? FileHTTPEndpointRequest {
				// FileHTTPEndpointRequest
				return urlRequests
						.map({ HTTPEndpointRequestPerformInfo(httpEndpointRequestInfo: self, urlRequest: $0,
								urlCompletionProc: {
									// Process results
									fileHTTPEndpointRequest.processResults(response: $0, url: $1, error: $2)
								}) })
			} else if let streamHTTPEndpointRequest = self.httpEndpointRequest as? StreamHTTPEndpointRequest {
				// StreamHTTPEndpointRequest
				return urlRequests
						.map({ HTTPEndpointRequestPerformInfo(httpEndpointRequestInfo: self, urlRequest: $0,
								urlCompletionProc: { streamHTTPEndpointRequest.completionProc($2) }) })
			} else if let httpEndpointRequestProcessResults =
					self.httpEndpointRequest as? HTTPEndpointRequestProcessResults {
				// Will only ever be a single URLRequest
				return urlRequests
						.map({ HTTPEndpointRequestPerformInfo(httpEndpointRequestInfo: self, urlRequest: $0,
								dataCompletionProc: {
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
								dataCompletionProc: {
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

	//------------------------------------------------------------------------------------------------------------------
	// MARK: HTTPEndpointRequestPerformInfo
	private class HTTPEndpointRequestPerformInfo {

		// MARK: Types
		typealias DataCompletionProc = (_ response :HTTPURLResponse?, _ data :Data?, _ error :Error?) -> Void
		typealias URLCompletionProc = (_ response :HTTPURLResponse?, _ url :URL?, _ error :Error?) -> Void

		// MARK: Properties
						let	urlRequest :URLRequest

						var	httpEndpointRequest :HTTPEndpointRequest
								{ self.httpEndpointRequestInfo.httpEndpointRequest }
						var	identifier :String { self.httpEndpointRequestInfo.identifier }
						var	priority :Priority { self.httpEndpointRequestInfo.priority }
						var	isCancelled :Bool { self.httpEndpointRequestInfo.httpEndpointRequest.isCancelled }

		private(set)	var	state :HTTPEndpointRequest.State = .queued

		private			let	httpEndpointRequestInfo :HTTPEndpointRequestInfo
		private			let	dataCompletionProc :DataCompletionProc?
		private			let	urlCompletionProc :URLCompletionProc?

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(httpEndpointRequestInfo :HTTPEndpointRequestInfo, urlRequest :URLRequest,
				dataCompletionProc :@escaping DataCompletionProc) {
			// Store
			self.urlRequest = urlRequest

			self.httpEndpointRequestInfo = httpEndpointRequestInfo
			self.dataCompletionProc = dataCompletionProc
			self.urlCompletionProc = nil
		}

		//--------------------------------------------------------------------------------------------------------------
		init(httpEndpointRequestInfo :HTTPEndpointRequestInfo, urlRequest :URLRequest,
				urlCompletionProc :@escaping URLCompletionProc) {
			// Store
			self.urlRequest = urlRequest

			self.httpEndpointRequestInfo = httpEndpointRequestInfo
			self.dataCompletionProc = nil
			self.urlCompletionProc = urlCompletionProc
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
				let	httpEndpointStatus = HTTPEndpointStatus(rawValue: response!.statusCode)!
				if httpEndpointStatus.isSuccess {
					// Success
					self.dataCompletionProc!(response, data, nil)
				} else if data != nil {
					// Other response with payload
					self.dataCompletionProc!(response, data,
							HTTPEndpointStatusError(status: httpEndpointStatus,
									info: String(data: data!, encoding: .utf8)))
				} else {
					// Some other response
					self.dataCompletionProc!(response, data, HTTPEndpointStatusError(status: httpEndpointStatus))
				}
			} else {
				// Some other error
				self.dataCompletionProc!(nil, nil, error)
			}
		}

		//--------------------------------------------------------------------------------------------------------------
		func processResults(response :HTTPURLResponse?, url :URL?, error :Error?) {
			// Process results
			if response != nil {
				// Have a response
				let	statusCode = response!.statusCode
				if statusCode == HTTPEndpointStatus.ok.rawValue {
					// Success
					self.urlCompletionProc!(response, url, nil)
				} else {
					// Some other response
					self.urlCompletionProc!(response, nil,
							HTTPEndpointStatusError(status: HTTPEndpointStatus(rawValue: statusCode)!))
				}
			} else {
				// Error
				self.urlCompletionProc!(response, nil, error)
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	// MARK: URLSessionDelegate
	private class URLSessionDelegate : NSObject, Foundation.URLSessionDelegate, URLSessionDataDelegate,
			URLSessionDownloadDelegate {

		// MARK: Types
		typealias DataProc = (_ data :Data) -> Void
		typealias ProgressProc = (_ progress :Double) -> Void
		typealias CompletionProc = (_ response :HTTPURLResponse?, _ url :URL?, _ error :Error?) -> Void

		// MARK: Info
		private struct Info {

			// MARK: Properties
			let	redirectBody :Data?

			let	dataProc :DataProc?
			let	progressProc :ProgressProc?
			let	completionProc :CompletionProc?
		}

		// MARK: Properties
		private	let	taskMap = LockingDictionary<URLSessionTask, Info>()

		// MARK: URLSessionDelegate methods
		//--------------------------------------------------------------------------------------------------------------
		func urlSession(_ session :URLSession, task :URLSessionTask, didCompleteWithError error :Error?) {
			// Retrieve info
			if let info = self.taskMap.value(for: task), let completionProc = info.completionProc {
				// Call proc
				completionProc(task.response as? HTTPURLResponse, nil, task.error)
			}

			// Cleanup
			self.taskMap.remove(task)
		}

		// MARK: URLSessionDataDelegate methods
		//--------------------------------------------------------------------------------------------------------------
		func urlSession(_ session :URLSession, dataTask :URLSessionDataTask, didReceive data :Data) {
			// Retrieve info
			if let info = self.taskMap.value(for: dataTask), let dataProc = info.dataProc {
				// Call proc
				dataProc(data)
			}
		}

		//--------------------------------------------------------------------------------------------------------------
		func urlSession(_ session :URLSession, task :URLSessionTask,
				willPerformHTTPRedirection response :HTTPURLResponse, newRequest request :URLRequest,
				completionHandler :@escaping (_ request :URLRequest?) -> Void) {
			// Setup
			var	requestUse = request

			// Retrieve info
			if let info = self.taskMap.value(for: task), info.redirectBody != nil {
				// Update request
				requestUse.httpBody = info.redirectBody
			}

			// Call completion handler
			completionHandler(requestUse)
		}

		// MARK: URLSessionDownloadDelegate methods
		//--------------------------------------------------------------------------------------------------------------
		func urlSession(_ session :URLSession, downloadTask :URLSessionDownloadTask, didWriteData bytesWritten :Int64,
				totalBytesWritten :Int64, totalBytesExpectedToWrite :Int64) {
			// Retrieve info
			if let info = self.taskMap.value(for: downloadTask), let progressProc = info.progressProc {
				// Call proc
				progressProc(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
			}
		}

		//--------------------------------------------------------------------------------------------------------------
		func urlSession(_ session :URLSession, downloadTask :URLSessionDownloadTask,
				didFinishDownloadingTo location :URL) {
			// Retrieve info
			if let info = self.taskMap.value(for: downloadTask), let completionProc = info.completionProc {
				// Call proc
				completionProc(downloadTask.response as? HTTPURLResponse, location, downloadTask.error)
			}

			// Cleanup
			self.taskMap.remove(downloadTask)
		}

		// MARK: Instance methods
		//--------------------------------------------------------------------------------------------------------------
		fileprivate func register(task :URLSessionTask, redirectBody :Data? = nil, dataProc :DataProc? = nil,
				progressProc :ProgressProc? = nil, completionProc :CompletionProc? = nil) {
			// Add to map
			self.taskMap.set(
					Info(redirectBody: redirectBody, dataProc: dataProc, progressProc: progressProc,
							completionProc: completionProc),
					for: task)
		}
	}

	// MARK: Properties
	static	public	var	logProc :(_ messages :[String]) -> Void = { $0.forEach() { NSLog("%@", $0) } }

			public	var	logOptions = LogOptions()

			private	let	serverPrefix :String
			private	let	options :Options
			private	let	maximumURLLength :Int
			private	let	urlSession :URLSession
			private	let	urlSessionDelegate :URLSessionDelegate?
			private	let	maximumConcurrentURLRequests :Int

			private	let	updateActiveHTTPEndpointRequestPerformInfosLock = Lock()

			private	var	activeHTTPEndpointRequestPerformInfos = LockingArray<HTTPEndpointRequestPerformInfo>()
			private	var	queuedHTTPEndpointRequestPerformInfos = LockingArray<HTTPEndpointRequestPerformInfo>()
			private	var	httpRequestIndex = 0

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(serverPrefix :String, options :Options = [], maximumURLLength :Int = 1024,
			urlSession :URLSession? = nil, maximumConcurrentURLRequests :Int? = nil) {
		// Setup
		let	urlSessionConfiguration = urlSession?.configuration ?? .default

		// Store
		self.serverPrefix = serverPrefix
		self.options = options
		self.maximumURLLength = maximumURLLength
		if urlSession != nil {
			// Was given URLSession
			self.urlSessionDelegate = nil
			self.urlSession = urlSession!
			self.maximumConcurrentURLRequests =
					maximumConcurrentURLRequests ?? urlSessionConfiguration.httpMaximumConnectionsPerHost
		} else {
			// Was not given URLSession
			self.urlSessionDelegate = URLSessionDelegate()
			self.urlSession =
					URLSession(configuration: .default, delegate: self.urlSessionDelegate!, delegateQueue: nil)
			self.maximumConcurrentURLRequests =
					maximumConcurrentURLRequests ?? urlSessionConfiguration.httpMaximumConnectionsPerHost
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public init(scheme :String, hostName :String, port :Int? = nil, options :Options = [], maximumURLLength :Int = 1024,
			urlSession :URLSession? = nil, maximumConcurrentURLRequests :Int? = nil) {
		// Setup
		let	urlSessionConfiguration = urlSession?.configuration ?? .default

		// Store
		self.serverPrefix = (port != nil) ? "\(scheme)://\(hostName):\(port!)" : "\(scheme)://\(hostName)"
		self.options = options
		self.maximumURLLength = maximumURLLength
		if urlSession != nil {
			// Was given URLSession
			self.urlSessionDelegate = nil
			self.urlSession = urlSession!
			self.maximumConcurrentURLRequests =
					maximumConcurrentURLRequests ?? urlSessionConfiguration.httpMaximumConnectionsPerHost
		} else {
			// Was not given URLSession
			self.urlSessionDelegate = URLSessionDelegate()
			self.urlSession =
					URLSession(configuration: .default, delegate: self.urlSessionDelegate!, delegateQueue: nil)
			self.maximumConcurrentURLRequests =
					maximumConcurrentURLRequests ?? urlSessionConfiguration.httpMaximumConnectionsPerHost
		}
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
			priority :Priority = .normal, progressProc :@escaping FileHTTPEndpointRequest.ProgressProc = { _ in },
			completionProc :@escaping FileHTTPEndpointRequest.CompletionProc) {
		// Setup
		fileHTTPEndpointRequest.progressProc = progressProc
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
	public func queue(_ streamHTTPEndpointRequest :StreamHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal, completionProc :@escaping StreamHTTPEndpointRequest.CompletionProc) {
		// Setup
		streamHTTPEndpointRequest.completionProc = completionProc

		// Queue
		queue(streamHTTPEndpointRequest, identifier: identifier, priority: priority)
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

					var	urlRequestInfo = "\(urlRequest.url!.scheme!)://\(urlRequest.url!.host ?? "unknown")"
					if urlRequest.url!.port != nil { urlRequestInfo += ":\(urlRequest.url!.port!)" }
					urlRequestInfo += "\(urlRequest.url!.path) (\(httpRequestIndex))"

					if logOptions.contains(.requestAndResponse) {
						// Setup
						var	logMessages = [String]()

						// Log request
						logMessages.append("\(className): \(urlRequest.httpMethod!) to \(urlRequestInfo)")
						if logOptions.contains(.requestQuery), let query = urlRequest.url!.query {
							// Log query
							if httpEndpointRequestPerformInfo.httpEndpointRequest.options.contains(
									.queryContainsSecureInfo) {
								// Redact secure info
								logMessages.append("    Query: <redacted>)")
							} else {
								// Proceed as usual
								logMessages.append("    Query: \(query)")
							}
						}
						if logOptions.contains(.requestHeaders) {
							// Log headers
							logMessages.append("    Headers: \(urlRequest.allHTTPHeaderFields ?? [:])")
						}
						if logOptions.contains(.requestBody), let httpBody = urlRequest.httpBody {
							// Log body
							if httpEndpointRequestPerformInfo.httpEndpointRequest.options.contains(
									.queryContainsSecureInfo) {
								// Redact secure info
								logMessages.append("    Body: <redacted>")
							} else {
								// Proceed as usual
								logMessages.append(
										"    Body: \(String(data: httpBody, encoding: .utf8) ?? "unable to decode")")
							}
						}
						if logOptions.contains(.requestBodySize), let httpBody = urlRequest.httpBody {
							// Log body size
							logMessages.append("    Body size: \(httpBody.count) bytes")
						}
						HTTPEndpointClient.logProc(logMessages)
					}

					let	startDate = Date()
					let	completionLogProc
								:(_ response :HTTPURLResponse?, _ error :Error?, _ bodyData :Data?) -> Void =
									{ response, error, bodyData in
										// Log
										if logOptions.contains(.requestAndResponse) {
											// Setup
											let	deltaTime = Date().timeIntervalSince(startDate)
											var	logMessages = [String]()

											// Log response
											if response != nil {
												// Success
												logMessages.append(
														"    \(className) received status \(response!.statusCode) for \(urlRequestInfo) in \(String(format: "%0.3f", deltaTime))s")
												if logOptions.contains(.responseHeaders) {
													// Log headers
													logMessages.append("        Headers: \(response!.allHeaderFields)")
												}
												if logOptions.contains(.responseBody), let bodyData {
													// Log body
													logMessages.append(
															"        Body: \(String(data: bodyData, encoding: .utf8) ?? "unable to decode")")
												}
											} else {
												// Error
												logMessages.append("    \(className) received error \(error!) for \(urlRequestInfo)")
											}
											HTTPEndpointClient.logProc(logMessages)
										}
									}

					// Run task
					if let fileHTTPEndpointRequest =
							httpEndpointRequestPerformInfo.httpEndpointRequest as? FileHTTPEndpointRequest {
						// FileHTTPEndpointRequest
						let	urlSessionDownloadTask = strongSelf.urlSession.downloadTask(with: urlRequest)

						// Register with URLSessionDelegate
						self?.urlSessionDelegate?.register(task: urlSessionDownloadTask,
								progressProc: fileHTTPEndpointRequest.progressProc,
								completionProc: {
									// Log
									completionLogProc($0, $2, nil)

									// Transition to finished
									httpEndpointRequestPerformInfo.transition(to: .finished)

									// Check if cancelled
									if !httpEndpointRequestPerformInfo.isCancelled {
										// Process results
										httpEndpointRequestPerformInfo.processResults(response: $0, url: $1, error: $2)
									}

									// Update
									strongSelf.updateHTTPEndpointRequestPerformInfos()
								})

						// Resume
						urlSessionDownloadTask.resume()
					} else if let streamHTTPEndpointRequest =
							httpEndpointRequestPerformInfo.httpEndpointRequest as? StreamHTTPEndpointRequest {
						// StreamHTTPEndpointRequest
						let	urlSessionDataTask = strongSelf.urlSession.dataTask(with: urlRequest)

						// Register with URLSessionDelegate
						self?.urlSessionDelegate?.register(task: urlSessionDataTask,
								dataProc: streamHTTPEndpointRequest.dataProc,
								completionProc: {
									// Log
									completionLogProc($0, $2, nil)

									// Transition to finished
									httpEndpointRequestPerformInfo.transition(to: .finished)

									// Check if cancelled
									if !httpEndpointRequestPerformInfo.isCancelled {
										// Process results
										httpEndpointRequestPerformInfo.processResults(response: $0, url: $1, error: $2)
									}

									// Update
									strongSelf.updateHTTPEndpointRequestPerformInfos()
								})

						// Resume
						urlSessionDataTask.resume()
					} else {
						// Check if have URLSessionDelegate
						if let urlSessionDelegate = self?.urlSessionDelegate {
							// Create Data Task
							let	urlSessionDataTask = strongSelf.urlSession.dataTask(with: urlRequest)

							// Register with URLSessionDelegate
							let	httpEndpointRequest = httpEndpointRequestPerformInfo.httpEndpointRequest
							var	data :Data? = nil
							urlSessionDelegate.register(task: urlSessionDataTask,
									redirectBody:
											httpEndpointRequest.options.contains(.deferBodyUntilRedirect) ?
													httpEndpointRequest.bodyData : nil,
									dataProc: { data = $0 },
									completionProc: {
										// Log
										completionLogProc($0, $2, data)

										// Transition to finished
										httpEndpointRequestPerformInfo.transition(to: .finished)

										// Check if cancelled
										if !httpEndpointRequestPerformInfo.isCancelled {
											// Process results
											httpEndpointRequestPerformInfo.processResults(response: $0, data: data,
													error: $2)
										}

										// Update
										strongSelf.updateHTTPEndpointRequestPerformInfos()
									})

							// Resume
							urlSessionDataTask.resume()
						} else {
							// Let's go
							strongSelf.urlSession.dataTask(with: urlRequest, completionHandler: {
								// Log
								completionLogProc($1 as? HTTPURLResponse, $2, $0 ?? Data())

								// Transition to finished
								httpEndpointRequestPerformInfo.transition(to: .finished)

								// Check if cancelled
								if !httpEndpointRequestPerformInfo.isCancelled {
									// Process results
									httpEndpointRequestPerformInfo.processResults(response: $1 as? HTTPURLResponse,
											data: $0, error: $2)
								}

								// Update
								strongSelf.updateHTTPEndpointRequestPerformInfos()
							}).resume()
						}
					}
				}
			}
		}
	}
}
