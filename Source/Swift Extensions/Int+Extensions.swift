//
//  Int+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 11/28/18.
//  Copyright © 2018 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: Int extension
public extension Int {

	// MARK: Properties
	static	let	`nil` :Int? = nil

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init?(_ int32 :Int32?) {
		// Check if string is nil
		guard int32 != nil else { return nil }

		self.init(int32!)
	}

	//------------------------------------------------------------------------------------------------------------------
	init?(_ int64 :Int64?) {
		// Check if string is nil
		guard int64 != nil else { return nil }

		self.init(int64!)
	}

	//------------------------------------------------------------------------------------------------------------------
	init?(_ string :String?) {
		// Check if string is nil
		guard string != nil else { return nil }

		self.init(string!)
	}

	//------------------------------------------------------------------------------------------------------------------
	init?(_ uint32 :UInt32?) {
		// Check if string is nil
		guard uint32 != nil else { return nil }

		self.init(uint32!)
	}

	//------------------------------------------------------------------------------------------------------------------
	init?(_ uint64 :UInt64?) {
		// Check if string is nil
		guard uint64 != nil else { return nil }

		self.init(uint64!)
	}
}
