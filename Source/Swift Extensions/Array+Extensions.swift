//
//  Array+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 10/10/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: Types
fileprivate struct MapItem<T, U> {

	// MARK: Properties
	let	key :T
	let	element :U
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - Array Extension
public extension Array {

	// MARK: Properties
	static	var	`nil` :Array? { nil }

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func collated<T, U>() -> (ts :[T], us :[U]) {
		// Setup
		var	ts = [T]()
		var	us = [U]()

		// Iterate
		forEach() {
			// Check type
			if let t = $0 as? T {
				// T
				ts.append(t)
			} else {
				// U
				us.append($0 as! U)
			}
		}

		return (ts, us)
	}

	//------------------------------------------------------------------------------------------------------------------
	func collated(proc :(_ element :Element) -> Bool) -> (bucket1 :[Element], bucket2 :[Element]) {
		// Setup
		var	bucket1 = [Element]()
		var	bucket2 = [Element]()

		// Iterate
		forEach() {
			// Call proc
			if proc($0) {
				// Bucket 1
				bucket1.append($0)
			} else {
				// Bucket 2
				bucket2.append($0)
			}
		}

		return (bucket1, bucket2)
	}

	//------------------------------------------------------------------------------------------------------------------
	func chunked(by chunkSize :Int) -> [[Element]] {
		// Check count
		if self.count == 0 {
			// Empty
			return []
		} else if self.count <= chunkSize {
			// All in one chunk
			return [self]
		} else {
			// Stride the array and map the strides to new arrays
			return stride(from: 0, to: self.count, by: chunkSize).map() {
				// Calculate end index
				let	endIndex = ($0.advanced(by: chunkSize) > self.count) ? self.count - $0 : chunkSize

				return Array(self[$0..<$0.advanced(by: endIndex)])
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func forEachChunk(chunkSize :Int, proc :(_ elements :[Element]) throws -> Void) rethrows {
		// Check count
		if self.count == 0 {
			// Nothing to do
			return
		} else if self.count <= chunkSize {
			// All in one chunk
			try proc(self)
		} else {
			// Stride the array and call the proc on the new arrays
			try stride(from: 0, to: self.count, by: chunkSize).forEach() {
				// Calculate end index
				let	endIndex = ($0.advanced(by: chunkSize) > self.count) ? self.count - $0 : chunkSize

				// Call proc
				try proc(Array(self[$0..<$0.advanced(by: endIndex)]))
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	mutating func remove(for indexSet :IndexSet) {
		// From https://stackoverflow.com/questions/26173565/removeobjectsatindexes-for-swift-arrays
		// Preflight
		guard var i = indexSet.first, i < count else { return }

		// Setup
		var	j = index(after: i)
		var	k = indexSet.integerGreaterThan(i) ?? endIndex

		// Scan through the elements
		while j != endIndex {
			// Check elements
			if k != j {
				// Swap these 2 elements
				swapAt(i, j)
				formIndex(after: &i)
			} else {
				// Get next index
				k = indexSet.integerGreaterThan(k) ?? endIndex
			}

			// Get next index
			formIndex(after: &j)
		}

		// Do the remove
		removeSubrange(i...)
	}

	//------------------------------------------------------------------------------------------------------------------
	mutating func sort<T : Comparable>(keyProc :(Self.Element) throws -> T,
			keyCompareProc: (T, T) -> Bool = { $0 < $1 }) rethrows {
		// Must have at least 2 elements
		guard self.count > 1 else { return }

#if os(Linux)
		func autoreleasepool<Result>(invoking body: () throws -> Result) rethrows -> Result { try body() }
#endif

		// Create map
		var	map :[MapItem<T, Element>] =
					try autoreleasepool()
							{ try self.map({ MapItem<T, Element>(key: try keyProc($0), element: $0) }) }

		// Sort keys
		autoreleasepool() { map.sort(by: { keyCompareProc($0.key, $1.key) }) }

		// Reconstruct sorted sequence
		self = Array(autoreleasepool() { map.map({ $0.element }) })
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - Array Extension
extension Array where Element : Hashable {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func uniqued() -> Self { Self(Set<Element>(self) ) }
}
