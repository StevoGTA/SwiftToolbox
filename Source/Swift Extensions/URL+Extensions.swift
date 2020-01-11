//
//  URL+Extensions.swift
//  Media Tools
//
//  Created by Stevo on 1/4/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: URL
extension URL {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func subPath(relativeTo url :URL) -> String? {
		// Setup
		let	fullPath = self.path
		let	rootPath = url.path

		return fullPath.hasPrefix(rootPath) ? fullPath.substring(fromCharacterIndex: rootPath.count) : nil
	}
}
