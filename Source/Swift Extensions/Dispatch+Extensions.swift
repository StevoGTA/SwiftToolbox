//
//  Dispatch+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 11/4/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: Dispatch extensions
extension DispatchQueue {

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static public func performAsync(performQueue :DispatchQueue = DispatchQueue.global(),
			performProc :@escaping () -> Void, completionQueue :DispatchQueue = DispatchQueue.main,
			completionProc :@escaping () -> Void) {
		// Switch to perform queue
		performQueue.async() {
			// Perform
			performProc()

			// Switch to completion queue
			completionQueue.async() {
				// Call completion
				completionProc()
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	static public func performAsync<T>(performQueue :DispatchQueue = DispatchQueue.global(),
			performProc :@escaping () -> T, completionQueue :DispatchQueue = DispatchQueue.main,
			completionProc :@escaping (_ t :T) -> Void) {
		// Switch to perform queue
		performQueue.async() {
			// Perform
			let	t = performProc()

			// Switch to completion queue
			completionQueue.async() {
				// Call completion
				completionProc(t)
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	static public func performBlocking(proc :(_ completionProc :@escaping () -> Void) -> Void) {
		// Setup
		let	dispatchGroup = DispatchGroup()
		dispatchGroup.enter()

		// Call proc
		proc() {
			// Finished
			dispatchGroup.leave()
		}

		// Wait
		dispatchGroup.wait()
	}

	//------------------------------------------------------------------------------------------------------------------
	static public func performBlocking<T>(proc :(_ completionProc :@escaping (_ t :T) -> Void) -> Void) -> T {
		// Setup
		let	dispatchGroup = DispatchGroup()
		dispatchGroup.enter()

		// Call proc
		var	t :T!
		proc() {
			// Finished
			t = $0
			dispatchGroup.leave()
		}

		// Wait
		dispatchGroup.wait()

		return t
	}

	//------------------------------------------------------------------------------------------------------------------
	static public func performConcurrentlyAndWait<T>(_ ts :[T], dispatchQueue :DispatchQueue = .global(),
			proc :@escaping (_ t :T) -> Void) {
		// Setup
		let	tsRemaining = LockingNumeric<Int>(ts.count)

		// Iterate all ts
		ts.forEach() { t in
			// Queue work
			dispatchQueue.async() {
				// Call proc
				proc(t)

				// One more done
				tsRemaining.subtract(1)
			}
		}

		// Wait
		tsRemaining.wait()
	}
}
