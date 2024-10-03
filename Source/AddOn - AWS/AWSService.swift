//
//  AWSService.swift
//  Apple TV+ Framework
//
//  Created by Stevo on 8/22/24.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: AWSService
public enum AWSService {
	// MARK: Values
	case s3

	// MARK: Properties
	public	var	availableRegions :[AWSRegion] {
						// Check self
						switch self {
							case .s3:	return AWSRegion.all
						}
					}
}
