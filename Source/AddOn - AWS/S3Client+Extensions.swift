//
//  S3Client+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 8/28/24.
//

import AWSS3

//----------------------------------------------------------------------------------------------------------------------
// MARK: S3Client extensions
public extension S3Client {

	// MARK: Properties

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func retrieveObjects(bucket :String, prefix :String? = nil,
			objectProc :@escaping (_ objects :[AWSS3Object]) -> Void) async throws {
		// Loop "forever"
		var	continuationToken :String? = nil
		repeat {
			// Make the call
			let	input =
						ListObjectsV2Input(bucket: bucket, continuationToken: continuationToken, encodingType: .url,
								prefix: prefix)
			let output = try await self.listObjectsV2(input: input)

			// Handle results
			if let contents = output.contents {
				// Call proc
				objectProc(contents.map({ AWSS3Object($0) }))
			}

			if output.nextContinuationToken != nil {
				// More to go
				continuationToken = output.nextContinuationToken
			} else {
				// All done
				break
			}
		} while true
	}
}
