//
//  FixedNumericArray.swift
//  Swift Toolbox
//
//  Created by Stevo on 8/11/25.
//  Copyright © 2025 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK FixedNumericArray
public class FixedNumericArray<T : Numeric> : RandomAccessCollection {

	// MARK: Properties
	public	let	startIndex :Int
	public	let	endIndex :Int

	public	var	sum :T {
						// Compute sum
						var	sum :T = 0
						for i in 0 ..< self.count { sum += self.buffer[i] }

						return sum
					}

	private	let	buffer :UnsafeMutablePointer<T>

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(_ count :Int) {
		// Store
		self.startIndex = 0
		self.endIndex = count

		// Setup
		self.buffer = UnsafeMutablePointer<T>.allocate(capacity: count)
		self.buffer.initialize(to: 0)
	}

	//------------------------------------------------------------------------------------------------------------------
	deinit {
		// Cleanup
		self.buffer.deallocate()
	}

	// MARK: ???
	//------------------------------------------------------------------------------------------------------------------
	public subscript(index :Int) -> T {
		get {
			// Ensure index is in bounds
			guard self.indices.contains(index) else { fatalError("index out of bounds") }

			return self.buffer[index]
		}
		set {
			// Ensure index is in bounds
			guard self.indices.contains(index) else { fatalError("index out of bounds") }

			// Update
			self.buffer[index] = newValue
		}
	}
}
