//
//  LockingError.swift
//  Swift Toolbox
//
//  Created by Stevo on 11/5/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: LockingError
public class LockingError : @unchecked Sendable {

	// MARK: Properties
	public	var	error :Error? { self.lock.read() { self.errorInternal } }

	private	let	lock = ReadPreferringReadWriteLock()

	private	var	errorInternal :Error?

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init() {}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func set(_ error :Error?) {
		// Check for error
		if error != nil {
			// Set error
			self.lock.write() { self.errorInternal = error }
		}
	}
}
