//
//  Lock.swift
//
//  Created by Stevo on 10/16/18.
//  Copyright © 2018 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: Lock
class Lock {

	// MARK: Properties
	private	var	mutex = pthread_mutex_t()

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func perform(_ proc :() -> Void) {
		// Lock
		pthread_mutex_lock(&self.mutex)

		// Call proc
		proc()

		// Unlock
		pthread_mutex_unlock(&self.mutex)
	}

	//------------------------------------------------------------------------------------------------------------------
	func perform(_ proc :() throws -> Void) throws {
		// Lock
		pthread_mutex_lock(&self.mutex)

		// Call proc
		try proc()

		// Unlock
		pthread_mutex_unlock(&self.mutex)
	}

	//------------------------------------------------------------------------------------------------------------------
	func perform<T>(_ proc :() -> T) -> T {
		// Lock
		pthread_mutex_lock(&self.mutex)

		// Call proc
		let	t = proc()

		// Unlock
		pthread_mutex_unlock(&self.mutex)

		return t
	}

	//------------------------------------------------------------------------------------------------------------------
	func perform<T>(_ proc :() throws -> T) throws -> T {
		// Lock
		pthread_mutex_lock(&self.mutex)

		// Call proc
		let	t = try proc()

		// Unlock
		pthread_mutex_unlock(&self.mutex)

		return t
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - ReadWriteLock
protocol ReadWriteLock {

	// MARK: Instance methods
	func read(_ proc :() -> Void)
	func read(_ proc :() throws -> Void) throws
	func read<T>(_ proc :() -> T) -> T
	func read<T>(_ proc :() throws -> T) throws -> T
	func write(_ proc :() -> Void)
	func write(_ proc :() throws -> Void) throws
	func write<T>(_ proc :() -> T) -> T
	func write<T>(_ proc :() throws -> T) throws -> T
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - ReadPreferringReadWriteLock
class ReadPreferringReadWriteLock : ReadWriteLock {

	// MARK: ReadWriteLock implementation
	//------------------------------------------------------------------------------------------------------------------
	func read(_ proc :() -> Void) {
		// Lock
		pthread_rwlock_rdlock(&self.lock)

		// Call proc
		proc()

		// Unlock
		pthread_rwlock_unlock(&self.lock)
	}

	//------------------------------------------------------------------------------------------------------------------
	func read(_ proc :() throws -> Void) throws {
		// Lock
		pthread_rwlock_rdlock(&self.lock)

		// Call proc
		try proc()

		// Unlock
		pthread_rwlock_unlock(&self.lock)
	}

	//------------------------------------------------------------------------------------------------------------------
	func read<T>(_ proc :() -> T) -> T {
		// Lock
		pthread_rwlock_rdlock(&self.lock)

		// Call proc
		let	t = proc()

		// Unlock
		pthread_rwlock_unlock(&self.lock)

		return t
	}

	//------------------------------------------------------------------------------------------------------------------
	func read<T>(_ proc :() throws -> T) throws -> T {
		// Lock
		pthread_rwlock_rdlock(&self.lock)

		// Call proc
		let	t = try proc()

		// Unlock
		pthread_rwlock_unlock(&self.lock)

		return t
	}

	//------------------------------------------------------------------------------------------------------------------
	func write(_ proc :() -> Void) {
		// Lock
		pthread_rwlock_wrlock(&self.lock)

		// Call proc
		proc()

		// Unlock
		pthread_rwlock_unlock(&self.lock)
	}

	//------------------------------------------------------------------------------------------------------------------
	func write(_ proc :() throws -> Void) throws {
		// Lock
		pthread_rwlock_wrlock(&self.lock)

		// Call proc
		try proc()

		// Unlock
		pthread_rwlock_unlock(&self.lock)
	}

	//------------------------------------------------------------------------------------------------------------------
	func write<T>(_ proc :() -> T) -> T {
		// Lock
		pthread_rwlock_wrlock(&self.lock)

		// Call proc
		let	t = proc()

		// Unlock
		pthread_rwlock_unlock(&self.lock)

		return t
	}

	//------------------------------------------------------------------------------------------------------------------
	func write<T>(_ proc :() throws -> T) throws -> T {
		// Lock
		pthread_rwlock_wrlock(&self.lock)

		// Call proc
		let	t = try proc()

		// Unlock
		pthread_rwlock_unlock(&self.lock)

		return t
	}

	// MARK: Properties
	private	var	lock = pthread_rwlock_t()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init() {
		// Setup
		pthread_rwlock_init(&self.lock, nil)
	}

	//------------------------------------------------------------------------------------------------------------------
	deinit {
		// Cleanup
		pthread_rwlock_destroy(&self.lock)
	}
}
