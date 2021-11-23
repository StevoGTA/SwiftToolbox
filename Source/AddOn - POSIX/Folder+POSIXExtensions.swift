//
//  Folder+POSIXExtensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 11/11/21.
//  Copyright © 2021 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: Folder extension
extension Folder {

	// MARK: Properties
	public	var	filesystemURLByResolvingSymlinks :URL {
						// Check path
						switch self.url.path {
#if os(macOS)
							case "/etc":	return URL(fileURLWithPath: "/private/etc")
							case "/tmp":	return URL(fileURLWithPath: "/private/tmp")
							case "/var":	return URL(fileURLWithPath: "/private/var")
#endif
							default:		return self.url.resolvingSymlinksInPath()
						}
					}
}
