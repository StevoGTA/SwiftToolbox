//
//  Int+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 11/28/18.
//  Copyright © 2018 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: Int extension
extension Int {

	// MARK: Properties
	static	let	`nil` :Int? = nil

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init?(_ string :String?) {
		// Check if string is nil
		guard string != nil else { return nil }

		self.init(string!)
	}
}
