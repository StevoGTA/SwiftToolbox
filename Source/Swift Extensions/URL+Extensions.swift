//
//  URL+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 1/4/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: URL
extension URL {

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func from(_ string :String?) -> URL? { (string != nil) ? URL(string: string!) : nil }

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func subPath(relativeTo url :URL) -> String? {
		// Setup
		let	fullPath = self.path
		let	rootPath = url.path

		return fullPath.hasPrefix(rootPath) ? fullPath.substring(fromCharacterIndex: rootPath.count) : nil
	}
}
