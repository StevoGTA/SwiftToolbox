//
//  HTTPEndpointClient.swift
//  Swift Toolbox
//
//  Created by Stevo on 3/23/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: HTTPEndpointClientError
enum HTTPEndpointClientError : Error {
	case invalidReturnInfo
}

extension HTTPEndpointClientError : LocalizedError {

	// MARK: Properties
	public	var	errorDescription :String? {
						// What are we
						switch self {
							case .invalidReturnInfo:	return "Invalid return info"
						}
					}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HTTPEndpointClient
class HTTPEndpointClient {

	// MARK: Properties
	static			let	shared = HTTPEndpointClient()

					var	logTransactions = true

			private	let	urlSession = URLSession.shared

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func perform(urlRequest :URLRequest, completionProcQueue :DispatchQueue = .main,
			completionProc :@escaping (_ results :String?, _ error :Error?) -> Void) {
		// Perform in background
		DispatchQueue.global().async() { [weak self] in
			// Log
			if self?.logTransactions ?? false { NSLog("HTTPEndpointClient - sending \(urlRequest)") }

			// Resume data task
			self?.urlSession.dataTask(with: urlRequest, completionHandler: { data, response, error in
				// Handle results
				var	returnResults :String?
				var	returnError = error
				if data != nil {
					// Success
					returnResults = String(data: data!, encoding: .utf8)
					if returnResults == nil {
						// Decode error
						returnError = HTTPEndpointClientError.invalidReturnInfo
					}
				}

				// Call completion proc
				completionProcQueue.async() { completionProc(returnResults, returnError) }
			}).resume()
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func perform(urlRequest :URLRequest, completionProcQueue :DispatchQueue = .main,
			completionProc :@escaping (_ info :[String : Any]?, _ error :Error?) -> Void) {
		// Perform in background
		DispatchQueue.global().async() { [weak self] in
			// Log
			if self?.logTransactions ?? false { NSLog("HTTPEndpointClient - sending \(urlRequest)") }

			// Resume data task
			self?.urlSession.dataTask(with: urlRequest, completionHandler: { data, response, error in
				// Handle results
				var	returnInfo :[String : Any]?
				var	returnError = error
				if data != nil {
					// Success
					do {
						// Decode results
						returnInfo = try JSONSerialization.jsonObject(with: data!, options: []) as? [String : Any]
						if returnInfo == nil {
							// Decode error
							returnError = HTTPEndpointClientError.invalidReturnInfo
						}
					} catch {
						// Error
						returnError = error
					}
				}

				// Call completion proc
				completionProcQueue.async() { completionProc(returnInfo, returnError) }
			}).resume()
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func perform(urlRequest :URLRequest, completionProcQueue :DispatchQueue = .main,
			completionProc :@escaping (_ infos :[[String : Any]]?, _ error :Error?) -> Void) {
		// Perform in background
		DispatchQueue.global().async() { [weak self] in
			// Log
			if self?.logTransactions ?? false { NSLog("HTTPEndpointClient - sending \(urlRequest)") }

			// Resume data task
			self?.urlSession.dataTask(with: urlRequest, completionHandler: { data, response, error in
				// Handle results
				var	returnInfos :[[String : Any]]?
				var	returnError = error
				if data != nil {
					// Success
					do {
						// Decode results
						returnInfos = try JSONSerialization.jsonObject(with: data!, options: []) as? [[String : Any]]
						if returnInfos == nil {
							// Decode error
							returnError = HTTPEndpointClientError.invalidReturnInfo
						}
					} catch {
						// Error
						returnError = error
					}
				}

				// Call completion proc
				completionProcQueue.async() { completionProc(returnInfos, returnError) }
			}).resume()
		}
	}
}
