//
//  Int64+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 6/6/23.
//  Copyright © 2023 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: Int64 extension
extension Int64 {

	// MARK: Properties
	static	let	`nil` :Int64? = nil

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init?(_ int :Int?) {
		// Check if string is nil
		guard int != nil else { return nil }

		self.init(int!)
	}

	//------------------------------------------------------------------------------------------------------------------
	public init?(_ string :String?) {
		// Check if string is nil
		guard string != nil else { return nil }

		self.init(string!)
	}
}
