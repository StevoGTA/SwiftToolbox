//
//  AWSS3Object.swift
//  Swift Toolbox
//
//  Created by Stevo on 8/28/24.
//

import AWSS3

//----------------------------------------------------------------------------------------------------------------------
// MARK: AWSS3Object
public struct AWSS3Object : TreeItem {

	// MARK: Properties
	public	let	key	:String
	public	let	lastModified :Date
	public	let	size :Int

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(_ info :S3ClientTypes.Object) {
		// Store
		self.key = info.key!.replacingOccurrences(of: "+", with: " ").removingPercentEncoding!
		self.lastModified = info.lastModified!
		self.size = info.size!
	}
}
