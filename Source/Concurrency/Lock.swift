//
//  Lock.swift
//  Swift Toolbox
//
//  Created by Stevo on 10/16/18.
//  Copyright © 2018 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: Lock
public class Lock : @unchecked Sendable {

	// MARK: Properties
	private	var	mutex = pthread_mutex_t()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init() {
		// Setup
		var attr = pthread_mutexattr_t()
		pthread_mutexattr_init(&attr)

		pthread_mutex_init(&self.mutex, &attr)
		pthread_mutexattr_destroy(&attr)
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func perform<T>(_ proc :() throws -> T) rethrows -> T {
		// Lock
		pthread_mutex_lock(&self.mutex)
		defer { pthread_mutex_unlock(&self.mutex) }

		return try proc()
	}

	//------------------------------------------------------------------------------------------------------------------
	public func performIfAvailable(_ proc :() throws -> Void) rethrows {
		// Try to lock
		if pthread_mutex_trylock(&self.mutex) == 0 {
			// Setup
			defer { pthread_mutex_unlock(&self.mutex) }

			// Call proc
			try proc()
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - ReadWriteLock
// For more ideas and alternate options: https://www.cs.cmu.edu/~fp/courses/15213-s05/recitations/secF_4-25.pdf
public protocol ReadWriteLock {

	// MARK: Instance methods
	func read<T>(_ proc :() throws -> T) rethrows -> T
	func write<T>(_ proc :() throws -> T) rethrows -> T
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - ReadPreferringReadWriteLock
public class ReadPreferringReadWriteLock : ReadWriteLock {

	// MARK: Properties
	private	var	lock = pthread_rwlock_t()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init() {
		// Setup
		var attr = pthread_rwlockattr_t()
		pthread_rwlockattr_init(&attr)

		pthread_rwlock_init(&self.lock, &attr)
		pthread_rwlockattr_destroy(&attr)
	}

	//------------------------------------------------------------------------------------------------------------------
	deinit {
		// Cleanup
		pthread_rwlock_destroy(&self.lock)
	}

	// MARK: ReadWriteLock methods
	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func read<T>(_ proc :() throws -> T) rethrows -> T {
		// Lock
		pthread_rwlock_rdlock(&self.lock)
		defer { pthread_rwlock_unlock(&self.lock) }

		return try proc()
	}

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func write<T>(_ proc :() throws -> T) rethrows -> T {
		// Lock
		pthread_rwlock_wrlock(&self.lock)
		defer { pthread_rwlock_unlock(&self.lock) }

		return try proc()
	}
}
