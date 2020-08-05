//
//  Set+Extensions.swift
//  Virtual Sheet Music
//
//  Created by Stevo on 8/5/20.
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
}
