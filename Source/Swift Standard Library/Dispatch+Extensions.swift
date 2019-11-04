//
//  Dispatch+Extensions.swift
//  LIFramework_OSX
//
//  Created by Stevo on 11/4/19.
//  Copyright © 2019 Light Iron. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: Dispatch extensions
extension DispatchQueue {

	// MARK: Class methods
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
