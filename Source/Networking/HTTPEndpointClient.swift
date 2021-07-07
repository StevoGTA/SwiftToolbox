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
open class HTTPEndpointClient : NSObject, URLSessionDelegate {

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
				let	statusCode = response!.statusCode
				if statusCode == HTTPEndpointStatus.ok.rawValue {
					// Success
					self.dataCompletionProc!(response, data, nil)
				} else {
					// Some other response
					self.dataCompletionProc!(response, nil,
							HTTPEndpointStatusError(status: HTTPEndpointStatus(rawValue: statusCode)!))
				}
			} else {
				// Error
				self.dataCompletionProc!(response, nil, error)
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

	private	class URLSessionDelegate :NSObject, Foundation.URLSessionDelegate, URLSessionDownloadDelegate {

		// MARK: Types
		typealias ProgressProc = (_ progress :Double) -> Void
		typealias CompletionProc = (_ response :HTTPURLResponse?, _ url :URL?, _ error :Error?) -> Void

		// MARK: Info
		private struct Info {

			// MARK: Properties
			let	progressProc :ProgressProc
			let	completionProc :CompletionProc
		}

		// MARK: Properties
		private	let	taskMap = LockingDictionary<URLSessionTask, Info>()

		// MARK: URLSessionDelegate methods
		//--------------------------------------------------------------------------------------------------------------
		func urlSession(_ session :URLSession, task :URLSessionTask, didCompleteWithError error :Error?) {
			// Retrieve info
			if let info = self.taskMap.value(for: task) {
				// Call proc
				info.completionProc(task.response as? HTTPURLResponse, nil, task.error)

				// Cleanup
				self.taskMap.remove(task)
			}
		}

		// MARK: URLSessionDownloadDelegate methods
		//--------------------------------------------------------------------------------------------------------------
		func urlSession(_ session :URLSession, downloadTask :URLSessionDownloadTask, didWriteData bytesWritten :Int64,
				totalBytesWritten :Int64, totalBytesExpectedToWrite :Int64) {
			// Retrieve info
			if let info = self.taskMap.value(for: downloadTask) {
				// Call proc
				info.progressProc(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
			}
		}

		//--------------------------------------------------------------------------------------------------------------
		func urlSession(_ session :URLSession, downloadTask :URLSessionDownloadTask,
				didFinishDownloadingTo location :URL) {
			// Retrieve info
			if let info = self.taskMap.value(for: downloadTask) {
				// Call proc
				info.completionProc(downloadTask.response as? HTTPURLResponse, location, downloadTask.error)
			}

			// Cleanup
			self.taskMap.remove(downloadTask)
		}

		// MARK: Instance methods
		//--------------------------------------------------------------------------------------------------------------
		fileprivate func register(downloadTask :URLSessionDownloadTask, progressProc :@escaping ProgressProc,
				completionProc :@escaping CompletionProc) {
			// Add to map
			self.taskMap.set(Info(progressProc: progressProc, completionProc: completionProc), for: downloadTask)
		}
	}

	// MARK: Properties
	static	public	var	logProc :(_ messages :[String]) -> Void = { $0.forEach() { NSLog($0) } }

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
			priority :Priority = .normal, progressProc :@escaping FileHTTPEndpointRequest.ProgressProc,
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

					// Run task
					let	startDate = Date()
					if let fileHTTPEndpointRequest =
							httpEndpointRequestPerformInfo.httpEndpointRequest as? FileHTTPEndpointRequest {
						// FileHTTPEndpointRequest
						let	urlSessionDownloadTask = strongSelf.urlSession.downloadTask(with: urlRequest)

						// Register with URLSessionDelegate
						self?.urlSessionDelegate?.register(downloadTask: urlSessionDownloadTask,
								progressProc: fileHTTPEndpointRequest.progressProc,
								completionProc: {
									// Log
									if logOptions.contains(.requestAndResponse) {
										// Setup
										let	deltaTime = Date().timeIntervalSince(startDate)
										var	logMessages = [String]()

										// Log response
										if $0 != nil {
											// Success
											logMessages.append(
													"    \(className) received status \($0!.statusCode) for \(urlRequestInfo) in \(String(format: "%0.3f", deltaTime))s")
											if logOptions.contains(.responseHeaders) {
												// Log headers
												logMessages.append("        Headers: \($0!.allHeaderFields)")
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
										httpEndpointRequestPerformInfo.processResults(response: $0, url: $1, error: $2)
									}

									// Update
									strongSelf.updateHTTPEndpointRequestPerformInfos()
								})

						// Resume
						urlSessionDownloadTask.resume()
					} else {
						// Other
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
