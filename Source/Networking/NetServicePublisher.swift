//
//  NetServicePublisher.swift
//  Swift Toolbox
//
//  Created by Stevo on 12/21/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: NetServicePublisher
class NetServicePublisher : NSObject, NetServiceDelegate {

	// MARK: Properties
	private	let	netService :NetService

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(domain :String, type :String, name :String, port :Int? = nil) {
		// Setup
		self.netService =
				(port != nil) ?
						NetService(domain: domain, type: type, name: name, port: Int32(port!)) :
						NetService(domain: domain, type: type, name: name)

		// Do super
		super.init()

		// Finish setupy
		self.netService.delegate = self
	}

	// MARK: NetServiceDelegate methods
	//------------------------------------------------------------------------------------------------------------------
	func netServiceWillPublish(_ sender :NetService) {}

	//------------------------------------------------------------------------------------------------------------------
	func netServiceDidPublish(_ sender :NetService) {}

	//------------------------------------------------------------------------------------------------------------------
	func netService(_ sender :NetService, didNotPublish errorDict :[String  :NSNumber]) {}

	//------------------------------------------------------------------------------------------------------------------
	func netServiceWillResolve(_ sender :NetService) {}

	//------------------------------------------------------------------------------------------------------------------
	func netServiceDidResolveAddress(_ sender :NetService) {}

	//------------------------------------------------------------------------------------------------------------------
	func netService(_ sender :NetService, didNotResolve errorDict :[String : NSNumber]) {}

	//------------------------------------------------------------------------------------------------------------------
	func netServiceDidStop(_ sender :NetService) {}

	//------------------------------------------------------------------------------------------------------------------
	func netService(_ sender :NetService, didUpdateTXTRecord data :Data) {}

	//------------------------------------------------------------------------------------------------------------------
	func netService(_ sender :NetService, didAcceptConnectionWith inputStream :InputStream,
			outputStream :OutputStream) {}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func start() { self.netService.publish() }

	//------------------------------------------------------------------------------------------------------------------
	func stop() { self.netService.stop() }
}
