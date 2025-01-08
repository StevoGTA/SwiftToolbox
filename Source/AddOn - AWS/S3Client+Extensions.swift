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

	// MARK: Properties
	static	var	availableRegions :[AWSRegion] { AWSRegion.all }

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
	func listObjects(bucket :S3ClientTypes.Bucket,
			filterProc :@escaping (_ object :AWSS3Object) -> Bool = { _ in true }) ->
			AsyncThrowingStream<AWSS3Object, Error> {
		// Setup
		.init() { continuation in
			// Setup
			var	proc :(_ prefix :String?) async throws -> Void = { _ in }
			proc = { prefix in
				// Loop "forever"
				var	continuationToken :String? = nil
				while true {
					// List objects at this level
					let	input =
								ListObjectsV2Input(bucket: bucket.name, continuationToken: continuationToken,
										delimiter: "/", encodingType: .url, prefix: prefix)
					let output = try await self.listObjectsV2(input: input)

					// Handle results
					if let contents = output.contents {
						// Call proc
						contents
								.map({ AWSS3Object($0) })
								.filter({ filterProc($0) })
								.forEach({ continuation.yield($0) })
					}

					if let commonPrefixes = output.commonPrefixes?.compactMap({ $0.prefix }) {
						// Initiate listing at next level
						try await withThrowingTaskGroup(of: Void.self) { group in
							// Iterate folders
							commonPrefixes.forEach() { commonPrefix in
								// Add task for this folder
								group.addTask() { try await proc(commonPrefix) }
							}
							try await group.waitForAll()
						}
					}

					if output.nextContinuationToken != nil {
						// More to go
						continuationToken = output.nextContinuationToken
					} else {
						// All done
						break
					}
				}
			}

			// Create task
			Task.detached() {
				// Catch errors
				do {
					// Start at the root
					try await proc(nil)

					// All done
					continuation.finish()
				} catch {
					// Error
					continuation.finish(throwing: error)
				}
			}
		}
	}
}
