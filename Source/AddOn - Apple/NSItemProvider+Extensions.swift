//
//  NSItemProvider+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 7/16/26.
//  Copyright © 2026 Stevo Brock. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers

//----------------------------------------------------------------------------------------------------------------------
// MARK: NSItemProvider extension
extension NSItemProvider {

	// MARK: Properties
	var	bestConcreteImageContentType :UTType?
			{ NSItemProvider.bestConcreteImageContentType(from: self.registeredContentTypes) }

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func bestConcreteImageContentType(from contentTypes :[UTType]) -> UTType? {
		// Choose the most specific concrete image UTType from a set of registered content types, preferring HEIC/HEIF
		//	over the others.
		let	concreteImageTypes = contentTypes.filter({ $0.conforms(to: .image) && ($0 != .image) })

		return concreteImageTypes.first(where: { $0.conforms(to: .heic) || $0.conforms(to: .heif) }) ??
				concreteImageTypes.first
	}
}
