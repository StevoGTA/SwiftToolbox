//
//  VaporHTTPServer.swift
//  Swift Toolbox
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
// MARK: HTTPEndpoint.Method extension
extension HTTPEndpointMethod {

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
// MARK: - ServerResponder
fileprivate class ServerResponder : HTTPServerResponder {

	// MARK: Properties
	private	var	trieRouters = [HTTPMethod : TrieRouter<HTTPEndpoint>]()

	// MARK: HTTPServerResponder implementation
	//------------------------------------------------------------------------------------------------------------------
    func respond(to request: HTTPRequest, on worker: Worker) -> Future<HTTPResponse> {
		// Get TrieRouter for method
		guard let trieRouter = self.trieRouters[request.method] else
				{ return worker.eventLoop.newSucceededFuture(result: HTTPResponse(status: .notFound)) }

		// Compose info
		let	urlComponents = URLComponents(url: request.url, resolvingAgainstBaseURL: false)!
		let	pathComponents = urlComponents.path.pathComponents

		var parameters = Parameters()
		guard let httpEndpoint = trieRouter.route(path: pathComponents, parameters: &parameters) else {
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
						try httpEndpoint.perform(urlComponents: urlComponents, headers: headers,
								bodyData: request.body.data)

			return worker.eventLoop.newSucceededFuture(
					result:
							HTTPResponse(status: HTTPResponseStatus(statusCode: responseStatus.rawValue),
									headers: HTTPHeaders(responseHeaders ?? []),
									body: responseBody?.data ?? HTTPBody()))
		} catch {
			// Handle error
			let	httpEndpointError = error as! HTTPEndpointError
			let	jsonBody = ["message": httpEndpointError.message]
			let	jsonData = try! JSONSerialization.data(withJSONObject: jsonBody, options: [])

			return worker.eventLoop.newSucceededFuture(
					result:
							HTTPResponse(status: HTTPResponseStatus(statusCode: httpEndpointError.status.rawValue),
									body: jsonData))
		}
    }

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func register(_ httpEndpoint :HTTPEndpoint) {
		// Setup
		let	pathComponents =
					httpEndpoint.path.pathComponents.map()
							{
								// Create PathComponent for either constant or parameter value
								return !$0.hasPrefix(":") ?
										PathComponent.constant($0) :
										PathComponent.parameter($0.substring(fromCharacterIndex: 1))
							}

		// Retrieve/Create TrieRouter
		let	httpMethod = httpEndpoint.method.httpMethod
		var	trieRouter = self.trieRouters[httpMethod]
		if trieRouter == nil {
			// Create new TrieRouter for this method
			trieRouter = TrieRouter<HTTPEndpoint>()
			self.trieRouters[httpMethod] = trieRouter
		}

		// Register route
		trieRouter!.register(route: Route(path: pathComponents, output: httpEndpoint))
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - VaporHTTPServer
public class VaporHTTPServer : HTTPServer {

	// MARK: Properties
	private	let	serverResponder = ServerResponder()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	required public init(port :Int, maxBodySize :Int) {
		// Run in the background
		DispatchQueue.global().async() {
			// Setup
			let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
			defer { try! group.syncShutdownGracefully() }

			// Catch errors
			var	server :Vapor.HTTPServer? = nil
			do {
				// Start server
				server =
						try Vapor.HTTPServer.start(hostname: "0.0.0.0", port: port, responder: self.serverResponder,
								maxBodySize: maxBodySize, on: group).wait()
			} catch {
				// Error
				NSLog("VaporHTTPServer encountered error when starting server: \(error)")
			}

			do {
				try server?.onClose.wait()
			} catch {
				// Error
				NSLog("VaporHTTPServer encountered error when closing server: \(error)")
			}
		}
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func register(_ httpEndpoint :HTTPEndpoint) { self.serverResponder.register(httpEndpoint) }
}
