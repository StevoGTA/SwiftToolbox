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
	@objc func load(on queue :DispatchQueue = .global(qos: .userInitiated),
			completionProc :@escaping(_ data :Data?, _ error :Error?) -> Void) {
		// Queue
		queue.async() { [weak self] in
			// Catch errors
			let	data :Data?
			let	loadError :Error?
			do {
				// Load
				data = try self?.loadProc()
				loadError = nil
			} catch {
				// Error
				data = nil
				loadError = error
			}

			// Switch to main queue
			DispatchQueue.main.async() { [weak self] in
				// Check things
				guard self != nil else { return }

				// Call completion
				completionProc(data, loadError)
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	@objc func loadInBackground(completionProc :@escaping(_ data :Data?, _ error :Error?) -> Void) {
		// Load on default queue
		load(completionProc: completionProc)
	}

	//------------------------------------------------------------------------------------------------------------------
	@objc func cancel() { self.cancelProc() }
}
