//
//  VaporHTTPServer-4.x.swift
//  Swift Toolbox
//
//  Created by Stevo on 2/24/23.
//  Copyright © 2023 Stevo Brock. All rights reserved.
//

import Vapor

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
public class VaporHTTPServer : HTTPServer, @unchecked Sendable {

	// MARK: Properties
	private	let	application = Application()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	required public init(port :Int, maxBodySize :Int) {
		// Complete application configuration
		self.application.http.server.configuration.port = port
		self.application.routes.defaultMaxBodySize = ByteCount(value: maxBodySize)

		// Run in task
		Task {
			// Catch errors
			do {
				// Execute application
				try await self.application.execute()
			} catch {
				// Error
				NSLog("VaporHTTPServer encountered error when executing application: \(error)")
			}
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

		// Register route
		self.application.on(httpEndpoint.method.httpMethod, pathComponents)
				{ [unowned self] in await self.perform(request: $0, httpEndpoint: httpEndpoint) }
	}

	// MARK: Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func perform(request :Request, httpEndpoint :HTTPEndpoint) async -> Response {
		// Compose info
		let	urlComponents = URLComponents(url: URL(string: request.url.string)!, resolvingAgainstBaseURL: false)!
		let	pathComponents =
					request.url.string
							.components(separatedBy: "?")[0]
							.components(separatedBy: "/")[1...]
							.map({ $0.removingPercentEncoding! })

		var	headersIterator = request.headers.makeIterator()
		var	headers = [String : String]()
		while let header = headersIterator.next() { headers[header.name] = header.value }

		// Catch errors
		do {
			// Get body data
			var	byteBuffer :ByteBuffer? = request.body.data
			if byteBuffer == nil {
				// Try to load
				byteBuffer = try? await request.body.collect(upTo: Int.max)
			}

			// Get data
			let	bodyData = byteBuffer?.getData(at: 0, length: byteBuffer?.readableBytes ?? 0)

			// Perform
			let	(responseStatus, responseHeaders, responseBody) =
						try httpEndpoint.perform(
								performInfo: (pathComponents, urlComponents.queryItemsMap, headers),
								bodyData: bodyData)

			return Response(status: HTTPResponseStatus(statusCode: responseStatus.rawValue),
					headers: HTTPHeaders(responseHeaders ?? []),
					body: (responseBody != nil) ? Response.Body(data: responseBody!.data) : .empty)
		} catch {
			// Handle error
			let	httpEndpointError = error as! HTTPEndpointError
			let	jsonBody = ["error": httpEndpointError.message]
			let	jsonData = try! JSONSerialization.data(withJSONObject: jsonBody, options: [])

			return Response(status: HTTPResponseStatus(statusCode: httpEndpointError.status.rawValue),
					body: Response.Body(data: jsonData))
		}
	}
}
