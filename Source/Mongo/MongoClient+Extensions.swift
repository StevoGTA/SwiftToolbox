//
//  MongoClient+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 2/1/24.
//  Copyright © 2024 Stevo Brock. All rights reserved.
//

import MongoSwift
import NIOCore

//----------------------------------------------------------------------------------------------------------------------
// MARK: MongoClient extension
public extension MongoClient {

	// MARK: ConnectionInfo
	struct ConnectionInfo {

		// MARK: Properties
		public	let	host :String?
		public	let	port :Int?

		public	var	info :[String : Any] {
							// Setup
							var	info = [String : Any]()
							info["host"] = self.host
							info["port"] = port

							return info
						}

		var	connectionString :String { "mongodb://\(self.host ?? "localhost"):\(self.port ?? 27017)" }

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		public init(host :String?, port :Int?) {
			// Store
			self.host = host
			self.port = port
		}

		//--------------------------------------------------------------------------------------------------------------
		public init(_ info :[String : Any]) {
			// Setup
			self.host = info["host"] as? String
			self.port = info["port"] as? Int
		}
	}

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	convenience init(_ connectionInfo :ConnectionInfo, using eventLoopGroup :EventLoopGroup) {
		// Do init knowing we won't fail as we control the connection string
		try! self.init(connectionInfo.connectionString, using: eventLoopGroup)
	}
}
