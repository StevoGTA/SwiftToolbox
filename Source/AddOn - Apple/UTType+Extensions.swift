//
//  UTType+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 9/23/26.
//  Copyright © 2026 Stevo Brock. All rights reserved.
//

import AVFoundation
import UniformTypeIdentifiers

//----------------------------------------------------------------------------------------------------------------------
// MARK: UTType extension
extension UTType {

	// MARK: Properties
	static	let	livePhotoBundle =
						UTType("com.apple.private.live-photo-bundle") ??
								UTType(importedAs: "com.apple.private.live-photo-bundle")
	static	let	m4v = UTType(AVFileType.m4v.rawValue)!
}
