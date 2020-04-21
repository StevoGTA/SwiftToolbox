//
//  File+POSIXExtensions.swift
//  Media Player - Apple
//
//  Created by Stevo on 4/20/20.
//  Copyright © 2020 Sunset Magicwerks, LLC. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: File extension
extension File {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func remove() throws { if unlink(self.url.path) == -1 { throw POSIXError.general(errno) } }
}
