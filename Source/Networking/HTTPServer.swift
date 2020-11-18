//
//  HTTPServer.swift
//  Swift Toolbox
//
//  Created by Stevo on 10/10/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: HTTPServer protocol
public protocol HTTPServer {

	// MARK: Lifecycle methods
	init(port :Int, maxBodySize :Int)

	// MARK: Instance Methods
	func register(_ httpEndpoint :HTTPEndpoint)
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HTTPServer extension
public extension HTTPServer {

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(port :Int) {
		// Call init
		self.init(port: port, maxBodySize: 1_000_000)
	}
}
