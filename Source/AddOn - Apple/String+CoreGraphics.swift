//
//  String+CoreGraphics.swift
//  Swift Toolbox
//
//  Created by Stevo on 3/9/20.
//  Copyright © 2018 Stevo Brock. All rights reserved.
//

import CoreGraphics
import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: String CoreGraphics Extension
extension String {

	// MARK: Properties
	public	var	cgPoint :CGPoint? {
						// Get info
						let	components = self.components(separatedBy: CharacterSet(charactersIn: "{},"))
						guard components.count == 4 else { return nil }
						guard let x = components[1].toDouble() else { return nil }
						guard let y = components[2].toDouble() else { return nil }

						return CGPoint(x: x, y: y)
					}
	public	var	cgSize :CGSize? {
						// Get info
						let	components = self.components(separatedBy: CharacterSet(charactersIn: "{},"))
						guard components.count == 4 else { return nil }
						guard let width = components[1].toDouble() else { return nil }
						guard let height = components[2].toDouble() else { return nil }

						return CGSize(width: width, height: height)
					}
	public	var	cgRect :CGRect? {
						// Get info
						let	components = self.components(separatedBy: CharacterSet(charactersIn: "{},"))
						guard components.count == 10 else { return nil }
						guard let x = components[2].toDouble() else { return nil }
						guard let y = components[3].toDouble() else { return nil }
						guard let width = components[6].toDouble() else { return nil }
						guard let height = components[7].toDouble() else { return nil }

						return CGRect(x: x, y: y, width: width, height: height)
					}

	// MARK: Lifecycle methoeds
	//------------------------------------------------------------------------------------------------------------------
	public init(_ point :CGPoint) { self.init("{\(point.x),\(point.y)}") }

	//------------------------------------------------------------------------------------------------------------------
	public init(_ size :CGSize) { self.init("{\(size.width),\(size.height)}") }

	//------------------------------------------------------------------------------------------------------------------
	public init(_ rect :CGRect) {
		self.init("{{\(rect.origin.x),\(rect.origin.y)},{\(rect.size.width),\(rect.size.height)}}")
	}
}
