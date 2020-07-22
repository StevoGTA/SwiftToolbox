//
//  DateComponents+Extension.swift
//  Swift Toolbox
//
//  Created by Stevo on 7/21/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: DateComponents extension
extension DateComponents {

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(days :Int) {
		// Init
		self.init()

		// Setup
		self.day = days
	}

	//------------------------------------------------------------------------------------------------------------------
	init(months :Int) {
		// Init
		self.init()

		// Setup
		self.month = months
	}

	//------------------------------------------------------------------------------------------------------------------
	init(weeks :Int) {
			// Init
		self.init()

		// Setup
		self.day = weeks * 7
	}
}
