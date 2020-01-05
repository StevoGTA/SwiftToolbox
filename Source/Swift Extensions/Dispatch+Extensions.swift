//
//  Dispatch+Extensions.swift
//  LIFramework_OSX
//
//  Created by Stevo on 11/4/19.
//  Copyright © 2019 Light Iron. All rights reserved.
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
	static public func performBlocking(_ proc :(_ completionProc :@escaping () -> Void) -> Void) {
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
	static public func performBlocking<T>(_ proc :(_ completionProc :@escaping (_ t :T) -> Void) -> Void) -> T {
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
}
