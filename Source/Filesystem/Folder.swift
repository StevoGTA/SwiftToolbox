//
//  Folder.swift
//  Media Tools
//
//  Created by Stevo on 9/22/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: Folder
class Folder {

	// MARK: Types
	typealias SubPathProc = (_ folder :Folder, _ subPath :String) -> Void

	// MARK: Properties
	let	url :URL

	var	name :String { self.url.lastPathComponent }
	var	path :String { self.url.path }

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(_ url :URL) {
		// Store
		self.url = url
	}
}
