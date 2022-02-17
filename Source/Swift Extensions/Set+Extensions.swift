//
//  Set+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 8/5/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: Set extension
extension Set {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	mutating func insert(_ newMembers :[Set.Element]) -> [(inserted :Bool, memberAfterInsert :Set.Element)] {
		// Setup
		var	info = [(inserted :Bool, memberAfterInsert :Set.Element)]()

		// Iterate all
		newMembers.forEach() { info.append(insert($0)) }

		return info
	}

	//------------------------------------------------------------------------------------------------------------------
	public func chunk(by chunkSize :Int) -> [Set<Element>] {
		// Check count
		if self.count == 0 {
			// Empty
			return []
		} else if self.count <= chunkSize {
			// All in one chunk
			return [self]
		} else {
			// Stride and map the strides to new arrays
			let	array = Array(self)

			return stride(from: 0, to: self.count, by: chunkSize).map() {
				// Calculate end index
				let	endIndex = ($0.advanced(by: chunkSize) > self.count) ? self.count - $0 : chunkSize

				return Set<Element>(array[$0..<$0.advanced(by: endIndex)])
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public func forEachChunk(chunkSize :Int, proc :(_ elements :Set<Element>) throws -> Void) rethrows {
		// Check count
		if self.count == 0 {
			// Nothing to do
			return
		} else if self.count <= chunkSize {
			// All in one chunk
			try proc(self)
		} else {
			// Stride and call the proc on the new arrays
			let	array = Array(self)

			try stride(from: 0, to: self.count, by: chunkSize).forEach() {
				// Calculate end index
				let	endIndex = ($0.advanced(by: chunkSize) > self.count) ? self.count - $0 : chunkSize

				// Call proc
				try proc(Set<Element>(array[$0..<$0.advanced(by: endIndex)]))
			}
		}
	}
}
