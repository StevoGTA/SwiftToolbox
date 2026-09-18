//
//  Double+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo Brock on 9/15/26.
//  Copyright © 2026 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: Double extension
public extension Double {

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init?(_ value :Double?) {
		// Check if value is nil
		guard value != nil else { return nil }

		self.init(value!)
	}
}
