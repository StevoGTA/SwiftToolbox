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
#if !DEBUG
			var	logProc :(_ string :String) -> Void = { _ in }
#else
			var	logProc :(_ string :String) -> Void = { NSLog($0) }
#endif

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
	func netServiceWillPublish(_ netService :NetService) {
		self.logProc("NetServicePublisher: will publish \(netService.domain)/\(netService.type)/\(netService.name)")
	}

	//------------------------------------------------------------------------------------------------------------------
	func netServiceDidPublish(_ sender :NetService) {
		self.logProc("NetServicePublisher: did publish \(netService.domain)/\(netService.type)/\(netService.name)")
	}

	//------------------------------------------------------------------------------------------------------------------
	func netService(_ sender :NetService, didNotPublish errorDict :[String : NSNumber]) {
		self.logProc(
				"NetServicePublisher: did not publish \(netService.domain)/\(netService.type)/\(netService.name) with error \(errorDict)")
	}

	//------------------------------------------------------------------------------------------------------------------
	func netServiceWillResolve(_ sender :NetService) {
		self.logProc("NetServicePublisher: will resolve \(netService.domain)/\(netService.type)/\(netService.name)")
	}

	//------------------------------------------------------------------------------------------------------------------
	func netServiceDidResolveAddress(_ sender :NetService) {
		self.logProc("NetServicePublisher: did resolve \(netService.domain)/\(netService.type)/\(netService.name)")
	}

	//------------------------------------------------------------------------------------------------------------------
	func netService(_ sender :NetService, didNotResolve errorDict :[String : NSNumber]) {
		self.logProc(
				"NetServicePublisher: did not resolve \(netService.domain)/\(netService.type)/\(netService.name) with error \(errorDict)")
	}

	//------------------------------------------------------------------------------------------------------------------
	func netServiceDidStop(_ sender :NetService) {
		self.logProc("NetServicePublisher: did stop \(netService.domain)/\(netService.type)/\(netService.name)")
	}

	//------------------------------------------------------------------------------------------------------------------
	func netService(_ sender :NetService, didUpdateTXTRecord data :Data) {
		self.logProc(
				"NetServicePublisher: did update TXT record \(netService.domain)/\(netService.type)/\(netService.name)")
	}

	//------------------------------------------------------------------------------------------------------------------
	func netService(_ sender :NetService, didAcceptConnectionWith inputStream :InputStream,
			outputStream :OutputStream) {
		self.logProc(
				"NetServicePublisher: did accept connection \(netService.domain)/\(netService.type)/\(netService.name)")
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func start() { self.netService.publish() }

	//------------------------------------------------------------------------------------------------------------------
	func stop() { self.netService.stop() }
}
