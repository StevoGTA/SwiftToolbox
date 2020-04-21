//
//  String+CoreGraphics.swift
//  Swift Toolbox
//
//  Created by Stevo on 3/9/20.
//  Copyright © 2018 Stevo Brock. All rights reserved.
//

import CoreGraphics

//----------------------------------------------------------------------------------------------------------------------
// MARK: CGSize extension
extension CGSize {

	// MARK: Lifecycle methoeds
	//------------------------------------------------------------------------------------------------------------------
	init?(_ string :String?) {
		// Preflight
		guard string != nil else { return nil }

		// Get info
		let	components = string!.components(separatedBy: CharacterSet(charactersIn: "{},"))
		guard components.count == 4 else { return nil }
		guard let width = components[1].toDouble() else { return nil }
		guard let height = components[2].toDouble() else { return nil }

		self.init(width: width, height: height)
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: String CoreGraphics Extension
extension String {

	// MARK: Lifecycle methoeds
	//------------------------------------------------------------------------------------------------------------------
	public init(_ size :CGSize) { self.init("{\(size.width),\(size.height)}") }
}
