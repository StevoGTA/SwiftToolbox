//
//  Toggleable.swift
//  Swift Toolbox
//
//  Created by Stevo Brock on 3/15/25.
//  Copyright © 2025 Stevo Brock. All rights reserved.
//

import SwiftUI

//----------------------------------------------------------------------------------------------------------------------
// MARK: Toggleable
class Toggleable {

	// MARK: Properties
	let	title :String

	var	isActive :Bool

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(title :String, isActive :Bool = true) {
		// Store
		self.title = title
		self.isActive = isActive
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - ToggleableWrapper
class ToggleableWrapper : Identifiable, ObservableObject {

	// MARK: Properties
			let	id = UUID().base64EncodedString

			var	title :String { self.toggleable.title }

			@Published
			var	isActive :Bool

	private	let	toggleable :Toggleable

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(_ toggleable :Toggleable) {
		// Store
		self.toggleable = toggleable

		self.isActive = toggleable.isActive
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func commit() { self.toggleable.isActive = self.isActive }
}
