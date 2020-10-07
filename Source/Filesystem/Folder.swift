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
	enum Action {
		case process
		case ignore
	}

	typealias SubPathProc = (_ folder :Folder, _ subPath :String) -> Void
	typealias SubPathDeepProc = (_ folder :Folder, _ subPath :String) -> Action

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
