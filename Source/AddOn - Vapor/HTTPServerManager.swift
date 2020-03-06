//
//  HTTPServerManager.swift
//  Swift Toolbox Vapor AddOn
//
//  Created by Stevo on 12/3/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

import Vapor

//----------------------------------------------------------------------------------------------------------------------
// MARK: HTTPMethod extension
extension HTTPMethod : Hashable {

	// MARK: Hashable implementation
	public func hash(into hasher :inout Hasher) { hasher.combine("\(self)") }
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: HTTPService.Method extension
extension HTTPServiceMethod {

	// MARK: Properties
	var	httpMethod :HTTPMethod {
				// Switch on self
				switch self {
					case .get:		return .GET
					case .head:		return .HEAD
					case .patch:	return .PATCH
					case .post:		return .POST
					case .put:		return .PUT
				}
			}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HTTPService.Status extension
extension HTTPServiceStatus {

	// MARK: Properties
	var	httpResponseStatus :HTTPResponseStatus {
				// Switch on self
				switch self {
					case .ok:					return .ok

					case .badRequest:			return .badRequest
					case .unauthorized:			return .unauthorized
					case .forbidden:			return .forbidden
					case .notFound:				return .notFound
					case .conflict:				return .conflict

					case .internalServerError:	return .internalServerError
				}
			}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - ServerResponder
fileprivate class ServerResponder : HTTPServerResponder {

	// MARK: HTTPServerResponder implementation
    func respond(to request: HTTPRequest, on worker: Worker) -> Future<HTTPResponse> {
		// Get TrieRouter for method
		guard let trieRouter = self.trieRouters[request.method] else
				{ return worker.eventLoop.newSucceededFuture(result: HTTPResponse(status: .notFound)) }

		// Compose info
		let	urlComponents = URLComponents(url: request.url, resolvingAgainstBaseURL: false)!
		let	pathComponents = urlComponents.path.pathComponents

		var parameters = Parameters()
		guard let httpService = trieRouter.route(path: pathComponents, parameters: &parameters) else {
			// Route not found
			return worker.eventLoop.newSucceededFuture(result: HTTPResponse(status: .notFound))
		}

		var	headersIterator = request.headers.makeIterator()
		var	headers = [String : String]()
		while let header = headersIterator.next() { headers[header.name] = header.value }

		// Catch errors
		do {
			// Perform
			let	(responseStatus, responseHeaders, responseBody) =
						try httpService.perform(urlComponents: urlComponents, headers: headers,
								bodyData: request.body.data)

			return worker.eventLoop.newSucceededFuture(
					result:
							HTTPResponse(status: responseStatus.httpResponseStatus,
									headers: HTTPHeaders(responseHeaders), body: responseBody?.data ?? HTTPBody()))
		} catch {
			// Handle error
			let	httpServiceError = error as! HTTPServiceError
			let	jsonBody = ["message": httpServiceError.message]
			let	jsonData = try! JSONSerialization.data(withJSONObject: jsonBody, options: [])

			return worker.eventLoop.newSucceededFuture(
					result: HTTPResponse(status: httpServiceError.status.httpResponseStatus, body: jsonData))
		}
    }

	// MARK: Properties
	private	var	trieRouters = [HTTPMethod : TrieRouter<HTTPService>]()

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func register(_ httpService :HTTPService) {
		// Setup
		let	pathComponents =
					httpService.path.pathComponents.map()
							{
								// Create PathComponent for either constant or parameter value
								return !$0.hasPrefix(":") ?
										PathComponent.constant($0) :
										PathComponent.parameter($0.substring(fromCharacterIndex: 1))
							}

		// Retrieve/Create TrieRouter
		let	httpMethod = httpService.method.httpMethod
		var	trieRouter = self.trieRouters[httpMethod]
		if trieRouter == nil {
			// Create new TrieRouter for this method
			trieRouter = TrieRouter<HTTPService>()
			self.trieRouters[httpMethod] = trieRouter
		}

		// Register route
		trieRouter!.register(route: Route(path: pathComponents, output: httpService))
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: HTTPServerManager
class HTTPServerManager {

	// MARK: Properties
	private	let	serverResponder = ServerResponder()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(port :Int, maxBodySize :Int = 1_000_000) {
		// Run in the background
		DispatchQueue.global().async() {
			// Setup
			let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
			defer { try! group.syncShutdownGracefully() }

			// Catch errors
			var	server :HTTPServer? = nil
			do {
				// Start server
				server =
						try HTTPServer.start(hostname: "0.0.0.0", port: port, responder: self.serverResponder,
								maxBodySize: maxBodySize, on: group).wait()
			} catch {
				// Error
				NSLog("HTTPServerManager encountered error when starting server: \(error)")
			}

			do {
				try server?.onClose.wait()
			} catch {
				// Error
				NSLog("HTTPServerManager encountered error when closing server: \(error)")
			}
		}
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func register(_ httpService :HTTPService) {
		// Register
		self.serverResponder.register(httpService)
	}
}
