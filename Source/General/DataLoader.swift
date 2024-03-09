//
//  DataLoader.swift
//  Swift Toolbox
//
//  Created by Stevo on 3/8/24.
//  Copyright © 2024 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: DataLoader
@objc class DataLoader : NSObject {

	// MARK: Properties
	private	let	loadProc :() throws -> Data
	private	let	cancelProc :() -> Void

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	@objc init(loadProc :@escaping () -> Data, cancelProc :@escaping () -> Void) {
		// Store
		self.loadProc = loadProc
		self.cancelProc = cancelProc
	}

	//------------------------------------------------------------------------------------------------------------------
	@objc init(loadProc :@escaping () -> Data) {
		// Store
		self.loadProc = loadProc
		self.cancelProc = {}
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	@objc func load() throws -> Data { return try self.loadProc() }

	//------------------------------------------------------------------------------------------------------------------
	@objc func cancel() { self.cancelProc() }
}
