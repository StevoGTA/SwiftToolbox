//
//  File+POSIXExtensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 4/20/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: File extension
extension File {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func remove() throws { if unlink(self.path) == -1 { throw POSIXError.general(errno) } }
}
