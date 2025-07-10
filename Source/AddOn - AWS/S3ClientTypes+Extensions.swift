//
//  S3ClientTypes+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 1/30/25.
//

import AWSS3

//----------------------------------------------------------------------------------------------------------------------
// MARK: S3ClientTypes.Bucket extensions
public extension S3ClientTypes.Bucket {

	// MARK: Properties
	var	arn :String { "arn:aws:s3:::\(self.name!)" }
}
