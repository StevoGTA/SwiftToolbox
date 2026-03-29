//
//  Toggleable.swift
//  Swift Toolbox
//
//  Created by Stevo Brock on 3/15/25.
//  Copyright © 2025 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: Toggleable
class Toggleable : Identifiable, ObservableObject {

	// MARK: Properties
	let	id = UUID().base64EncodedString
	let	title :String

	@Published
	var	isActive :Bool

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(title :String, isActive :Bool = true) {
		// Store
		self.title = title
		self.isActive = isActive
	}
}
