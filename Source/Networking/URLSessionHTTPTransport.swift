//
//  URLSessionHTTPTransport.swift
//  Swift Toolbox
//
//  Created by Stevo on 10/30/26.
//  Copyright © 2026 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: URLSessionTask extension
extension URLSessionTask : HTTPTransportTask {}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - URLSessionHTTPTransport
public final class URLSessionHTTPTransport : NSObject, HTTPTransport {

	//------------------------------------------------------------------------------------------------------------------
	// MARK: URLSessionDelegate
	private final class URLSessionDelegate : NSObject, Foundation.URLSessionDelegate, URLSessionDataDelegate,
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
				completionProc((error == nil) ? task.response as? HTTPURLResponse : nil, nil, error)
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
				completionProc(downloadTask.response as? HTTPURLResponse, location, nil)
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
	@objc	public	var	maximumConcurrentRequests :Int { self.urlSession.configuration.httpMaximumConnectionsPerHost }

			private	let	urlSession :URLSession
			private	let	urlSessionDelegate :URLSessionDelegate

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	@objc public init(configuration :URLSessionConfiguration = .default) {
		// Setup
		let	urlSessionDelegate = URLSessionDelegate()

		// Store
		self.urlSession = URLSession(configuration: configuration, delegate: urlSessionDelegate, delegateQueue: nil)
		self.urlSessionDelegate = urlSessionDelegate

		// Do super
		super.init()
	}

	//------------------------------------------------------------------------------------------------------------------
	deinit {
		// Cleanup
		self.urlSession.finishTasksAndInvalidate()
	}

	// MARK: HTTPTransport methods
	//------------------------------------------------------------------------------------------------------------------
	@objc public func perform(_ urlRequest :URLRequest, redirectBody :Data?,
			completionProc :@escaping DataCompletionProc) -> HTTPTransportTask {
		// Setup
		let	urlSessionDataTask = self.urlSession.dataTask(with: urlRequest)
		var	data :Data? = nil

		// Register with URLSessionDelegate
		self.urlSessionDelegate.register(task: urlSessionDataTask, redirectBody: redirectBody,
				dataProc: { data = (data != nil) ? data! + $0 : $0 },
				completionProc: { completionProc($0, ($2 == nil) ? data : nil, $2) })

		// Resume
		urlSessionDataTask.resume()

		return urlSessionDataTask
	}

	//------------------------------------------------------------------------------------------------------------------
	public func perform(_ urlRequest :URLRequest, dataProc :@escaping StreamDataProc,
			completionProc :@escaping StreamCompletionProc) -> HTTPTransportTask {
		// Setup
		let	urlSessionDataTask = self.urlSession.dataTask(with: urlRequest)

		// Register with URLSessionDelegate
		self.urlSessionDelegate.register(task: urlSessionDataTask, dataProc: dataProc,
				completionProc: { completionProc($0, $2) })

		// Resume
		urlSessionDataTask.resume()

		return urlSessionDataTask
	}

	//------------------------------------------------------------------------------------------------------------------
	public func perform(_ urlRequest :URLRequest, progressProc :@escaping FileProgressProc,
			completionProc :@escaping FileCompletionProc) -> HTTPTransportTask {
		// Setup
		let	urlSessionDownloadTask = self.urlSession.downloadTask(with: urlRequest)

		// Register with URLSessionDelegate
		self.urlSessionDelegate.register(task: urlSessionDownloadTask, progressProc: progressProc,
				completionProc: completionProc)

		// Resume
		urlSessionDownloadTask.resume()

		return urlSessionDownloadTask
	}
}
