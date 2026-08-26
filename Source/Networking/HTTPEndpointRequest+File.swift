//
//  HTTPEndpointRequest+File.swift
//  Swift Toolbox
//
//  Created by Stevo on 8/26/26.
//  Copyright © 2026 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: FileHTTPEndpointRequest
public class FileHTTPEndpointRequest : HTTPEndpointRequest {

	// MARK: Types
	public	typealias ProgressProc = (_ progress :Double) -> Void
	public	typealias CompletionProc = (_ response :HTTPURLResponse?, _ error :Error?) -> Void

	// MARK: Properties
	public	var	progressProc :ProgressProc = { _ in }
	public	var	completionProc :CompletionProc = { _,_ in }

	private	let	destinationURL :URL

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(method :HTTPEndpointMethod = .get, path :String, queryComponents :[String : Any]? = nil,
			headers :[String : String] = [:], timeoutInterval :TimeInterval = defaultTimeoutInterval.value,
			destinationURL :URL) {
		// Store
		self.destinationURL = destinationURL

		// Do super
		super.init(method: method, path: path, queryComponents: queryComponents, headers: headers,
				timeoutInterval: timeoutInterval)
	}

	//------------------------------------------------------------------------------------------------------------------
	init(method :HTTPEndpointMethod = .get, path :String, queryComponents :[String : Any]? = nil,
			headers :[String : String] = [:], timeoutInterval :TimeInterval = defaultTimeoutInterval.value,
			destinationFile :File) {
		// Store
		self.destinationURL = destinationFile.url

		// Do super
		super.init(method: method, path: path, queryComponents: queryComponents, headers: headers,
				timeoutInterval: timeoutInterval)
	}

	//------------------------------------------------------------------------------------------------------------------
	init(url :URL, timeoutInterval :TimeInterval = defaultTimeoutInterval.value, options :Options = [],
			destinationURL :URL) {
		// Store
		self.destinationURL = destinationURL

		// Do super
		super.init(method: .get, url: url, timeoutInterval: timeoutInterval, options: options)
	}

	//------------------------------------------------------------------------------------------------------------------
	init(url :URL, timeoutInterval :TimeInterval = defaultTimeoutInterval.value, options :Options = [],
			destinationFile :File) {
		// Store
		self.destinationURL = destinationFile.url

		// Do super
		super.init(method: .get, url: url, timeoutInterval: timeoutInterval, options: options)
	}
}

extension FileHTTPEndpointRequest : HTTPEndpointRequestProcessURLResults {

	// MARK: HTTPEndpointRequestProcessURLResults methods
	//------------------------------------------------------------------------------------------------------------------
	func processResults(response :HTTPURLResponse?, url :URL?, error :Error?) {
		// Check cancelled
		if !self.isCancelled {
			// Handle results
			if url != nil {
				do {
					// Move file
					try FileManager.default.create(Folder(self.destinationURL.deletingLastPathComponent()))
					try FileManager.default.moveItem(at: url!, to: self.destinationURL)

					// Call completion
					self.completionProc(response, nil)
				} catch {
					// Error
					self.completionProc(response, error)
				}
			} else {
				// Error
				self.completionProc(response, error)
			}
		}
	}
}
