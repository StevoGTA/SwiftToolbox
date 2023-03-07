//
//  VaporHTTPServer-4.x.swift
//  Swift Toolbox
//
//  Created by Stevo on 2/24/23.
//  Copyright © 2023 Stevo Brock. All rights reserved.
//

import Vapor

//----------------------------------------------------------------------------------------------------------------------
// MARK: HTTPMethod extension
extension HTTPMethod : Hashable {

	// MARK: Hashable implementation
	//------------------------------------------------------------------------------------------------------------------
	public func hash(into hasher :inout Hasher) { hasher.combine("\(self)") }
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: HTTPEndpoint.Method extension
extension HTTPEndpointMethod {

	// MARK: Properties
	var	httpMethod :HTTPMethod {
				// Switch on self
				switch self {
					case .delete:	return .DELETE
					case .get:		return .GET
					case .head:		return .HEAD
					case .patch:	return .PATCH
					case .post:		return .POST
					case .put:		return .PUT
				}
			}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - VaporHTTPServer
public class VaporHTTPServer : HTTPServer, Vapor.Responder {

	// MARK: Properties
	private	var	trieRouters = [HTTPMethod : TrieRouter<HTTPEndpoint>]()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	required public init(port :Int, maxBodySize :Int) {
		// Run in the background
		DispatchQueue.global(qos: .background).async() {
			// Setup
			let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
			defer { try! eventLoopGroup.syncShutdownGracefully() }

			let	server =
						Vapor.HTTPServer(application: Application(), responder: self,
								configuration: Vapor.HTTPServer.Configuration(port: port),
								on: eventLoopGroup)

			// Catch errors
			do {
				// Start server
				try server.start()
			} catch {
				// Error
				NSLog("VaporHTTPServer encountered error when starting server: \(error)")
			}

			do {
				// Wait for shutdown
				try server.onShutdown.wait()
			} catch {
				// Error
				NSLog("VaporHTTPServer encountered error when closing server: \(error)")
			}
		}
	}

	// MARK: Vapor.Responder methods
	//------------------------------------------------------------------------------------------------------------------
	public func respond(to request :Request) -> EventLoopFuture<Response> {
		// Get TrieRouter for method
		guard let trieRouter = self.trieRouters[request.method] else {
			// Method not found
			return request.eventLoop.future(Response(status: .notFound))
		}

		// Compose info
		let	urlComponents = URLComponents(url: URL(string: request.url.string)!, resolvingAgainstBaseURL: false)!
		let	pathComponents =
					request.url.string
							.components(separatedBy: "?")[0]
							.components(separatedBy: "/")[1...]
							.map({ $0.removingPercentEncoding! })

		var parameters = Parameters()
		guard let httpEndpoint = trieRouter.route(path: pathComponents, parameters: &parameters) else {
			// Route not found
			return request.eventLoop.future(Response(status: .notFound))
		}

		var	headersIterator = request.headers.makeIterator()
		var	headers = [String : String]()
		while let header = headersIterator.next() { headers[header.name] = header.value }

		// Catch errors
		do {
			// Perform
			let	(responseStatus, responseHeaders, responseBody) =
						try httpEndpoint.perform(
								performInfo: (pathComponents, urlComponents.queryItemsMap, headers),
								bodyData:
										request.body.data?.getData(at: 0,
												length: request.body.data?.readableBytes ?? 0))

			return request.eventLoop.future(
					Response(status: HTTPResponseStatus(statusCode: responseStatus.rawValue),
							headers: HTTPHeaders(responseHeaders ?? []),
							body: (responseBody != nil) ? Response.Body(data: responseBody!.data) : .empty))
		} catch {
			// Handle error
			let	httpEndpointError = error as! HTTPEndpointError
			let	jsonBody = ["error": httpEndpointError.message]
			let	jsonData = try! JSONSerialization.data(withJSONObject: jsonBody, options: [])

			return request.eventLoop.future(
					Response(status: HTTPResponseStatus(statusCode: httpEndpointError.status.rawValue),
							body: Response.Body(data: jsonData)))
		}
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func register(_ httpEndpoint :HTTPEndpoint) {
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
		trieRouter!.register(httpEndpoint, at: pathComponents)
	}
}
