//
//  TimeInterval+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 12/13/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: TimeInterval extension
extension TimeInterval {

	// MARK: Properties
	static	public	let	`nil` :TimeInterval? = nil

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init?(_ string :String?) {
		// Check if string is nil
		guard string != nil else { return nil }

		self.init(string!)
	}
}
