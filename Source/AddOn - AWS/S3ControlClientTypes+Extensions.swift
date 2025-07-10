//
//  S3ControlClientTypes+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 1/30/25.
//

import AWSS3Control

//----------------------------------------------------------------------------------------------------------------------
// MARK: S3ControlClientTypes.JobStatus extension
public extension S3ControlClientTypes.JobStatus {

	// MARK: Properties
	var	displayName :String {
				// Check value
				switch self {
					case .active:					return "Active"
					case .cancelled:				return "Cancelled"
					case .cancelling:				return "Cancelling..."
					case .complete:					return "Complete"
					case .completing:				return "Completing..."
					case .failed:					return "Failed"
					case .failing:					return "Failing..."
					case .new:						return "New"
					case .paused:					return "Paused"
					case .pausing:					return "Pausing..."
					case .preparing:				return "Preparing..."
					case .ready:					return "Ready"
					case .suspended:				return "Suspended"
					case .sdkUnknown(let message):	return "Unknown SDK: \(message)"
				}
			}
}
