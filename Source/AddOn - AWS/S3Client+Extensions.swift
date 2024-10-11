//
//  S3Client+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 8/28/24.
//

import AWSS3
import SmithyIdentity

//----------------------------------------------------------------------------------------------------------------------
// MARK: S3Client extensions
public extension S3Client {

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func bucketsByRegion(for credentialIdentity :AWSCredentialIdentity,
			in regions :[AWSRegion] = AWSRegion.common) async -> [AWSRegion : [S3ClientTypes.Bucket]] {
		// Setup
		var	bucketsByRegion = [AWSRegion : [S3ClientTypes.Bucket]]()

		// Iterate regions
		for region in regions {
			// Catch errors
			do {
				// Setup
				let	s3Client = try await S3Client(credentialIdentity: credentialIdentity, region: region)

				// Get Buckets
				let listBucketsOutput = try await s3Client.listBuckets(input: ListBucketsInput())
				if var buckets = listBucketsOutput.buckets, !buckets.isEmpty {
					// Success
					buckets.sort(by: { ($0.name ?? "Unknown") < ($1.name ?? "Unknown") })
					bucketsByRegion[region] = buckets
				}
			} catch {}
		}

		return bucketsByRegion
	}

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	convenience init(credentialIdentity :AWSCredentialIdentity, region : AWSRegion) async throws {
		// Setup
		let	credentialIdentityResolver = try! StaticAWSCredentialIdentityResolver(credentialIdentity)
		let	s3ClientConfiguration =
					try await S3Client.S3ClientConfiguration(
							awsCredentialIdentityResolver: credentialIdentityResolver, region: region.tag)
		self.init(config: s3ClientConfiguration)
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func retrieveObjects(bucket :S3ClientTypes.Bucket, prefix :String? = nil,
			objectProc :@escaping (_ objects :[AWSS3Object]) -> Void) async throws {
		// Loop "forever"
		var	continuationToken :String? = nil
		repeat {
			// Make the call
			let	input =
						ListObjectsV2Input(bucket: bucket.name, continuationToken: continuationToken,
								encodingType: .url, prefix: prefix)
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
