//
//  Int64+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 6/6/23.
//  Copyright © 2023 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: Int64 extension
public extension Int64 {

	// MARK: Properties
	static	let	`nil` :Int64? = nil

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init?(_ value :Double?) {
		// Check if value is nil
		guard value != nil else { return nil }

		self.init(value!)
	}

	//------------------------------------------------------------------------------------------------------------------
	init?(_ value :Int?) {
		// Check if value is nil
		guard value != nil else { return nil }

		self.init(value!)
	}

	//------------------------------------------------------------------------------------------------------------------
	init?(_ string :String?) {
		// Check if string is nil
		guard string != nil else { return nil }

		self.init(string!)
	}
}
