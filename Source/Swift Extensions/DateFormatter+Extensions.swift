//
//  DateFormatter+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 4/13/22.
//  Copyright © 2022 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: DateFormatter extensions
extension DateFormatter {

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	convenience init(dateFormat :String) {
		// Do super
		self.init()

		// Setup
		self.dateFormat = dateFormat
	}
}
