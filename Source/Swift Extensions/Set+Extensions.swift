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
}
