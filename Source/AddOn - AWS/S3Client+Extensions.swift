//
//  S3Client+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 8/28/24.
//

import AsyncAlgorithms
import ClientRuntime
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
			in regions :[AWSRegion] = AWSRegion.common, logger :Logger? = nil) async ->
			[AWSRegion : [S3ClientTypes.Bucket]] {
		// Setup
		var	bucketsByRegion = [AWSRegion : [S3ClientTypes.Bucket]]()

		// Iterate regions
		for region in regions {
			// Catch errors
			do {
				// Setup
				logger?.info("S3Client - Retrieving buckets for region \(region.tag)...")
				let	s3Client = try await S3Client(credentialIdentity: credentialIdentity, region: region)

				// Get Buckets
				let listBucketsOutput = try await s3Client.listBuckets(input: ListBucketsInput())
				if var buckets = listBucketsOutput.buckets, !buckets.isEmpty {
					// Success
					buckets.sort(by: { ($0.name ?? "Unknown") < ($1.name ?? "Unknown") })
					logger?.info("    S3Client - retrieved \(buckets.map({ $0.name! }))")
					bucketsByRegion[region] = buckets
				}
			} catch {
				// Error
				logger?.error("    S3Client  - encountered error: \(error)")
			}
		}

		return bucketsByRegion
	}

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	convenience init(credentialIdentity :AWSCredentialIdentity, region :AWSRegion) async throws {
		// Setup
		let	credentialIdentityResolver = try! StaticAWSCredentialIdentityResolver(credentialIdentity)
		let	s3ClientConfiguration =
					try await S3Client.S3ClientConfiguration(
							awsCredentialIdentityResolver: credentialIdentityResolver, region: region.tag)
		self.init(config: s3ClientConfiguration)
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func listObjects(bucket :S3ClientTypes.Bucket, logger :Logger? = nil,
			filterProc :@escaping (_ object :AWSS3Object) -> Bool = { _ in true }) ->
			AsyncThrowingStream<AWSS3Object, Error> {
		// Setup
		.init() { continuation in
			// Create task
			Task.detached() {
				// Setup
				let	listObjectsQueue =
							ListObjectQueue(s3Client: self, bucket: bucket, logger: logger, filterProc: filterProc,
									objectProc: { continuation.yield($0) })

				// List objects
				listObjectsQueue.add(item: "")

				// Catch errors
				do {
					// Wait
					try await listObjectsQueue.waitForAll()

					// Done!
					continuation.finish()
				} catch {
					// Error
					continuation.finish(throwing: error)
				}
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - ListObjectQueue
fileprivate class ListObjectQueue :AsyncQueue<String> {

	// MARK: Types
	typealias FilterProc = (_ object :AWSS3Object) -> Bool
	typealias ObjectProc = (_ object :AWSS3Object) -> Void

	// MARK: Properties
	private	let	s3Client :S3Client
	private	let	bucket :S3ClientTypes.Bucket
	private	let	logger :Logger?

	private	let	filterProc :FilterProc
	private	let	objectProc :ObjectProc

	private	let	requestIndex = LockingNumeric<Int>()
	private	let	prefixes = AsyncChannel<String>()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(s3Client :S3Client, bucket :S3ClientTypes.Bucket, logger :Logger? = nil, maxConcurrency :Int = 4,
			filterProc :@escaping FilterProc = {_ in true }, objectProc :@escaping ObjectProc) {
		// Store
		self.s3Client = s3Client
		self.bucket = bucket
		self.logger = logger

		self.filterProc = filterProc
		self.objectProc = objectProc

		// Do super
		super.init(maxConcurrency: maxConcurrency)
	}

	// MARK: AsyncQueue methods
	//------------------------------------------------------------------------------------------------------------------
	override func process(item: String) async throws {
		// Setup
		let	prefix = item

		// Loop "forever"
		var	continuationToken :String? = nil
		var	partIndex = 0
		var	errorCount = 0
		while true {
			// Setup
			let	requestIndex_ = self.requestIndex.add(1)
			let	bucketReference = "\(self.bucket.name!):\(prefix), part \(partIndex + 1) (\(requestIndex_))"

			// Catch errors
			do {
				// List objects at this level
				let	input =
							ListObjectsV2Input(bucket: self.bucket.name, continuationToken: continuationToken,
									delimiter: "/", encodingType: .url, prefix: prefix)

				self.logger?.info("S3Client listing objects for \(bucketReference)...")
				let output = try await self.s3Client.listObjectsV2(input: input)

				// Handle results
				logger?.info("    S3Client processing results of listing objects for \(bucketReference)...")
				if let contents = output.contents {
					// Call proc
					contents
						.map({ AWSS3Object($0) })
						.filter({ self.filterProc($0) })
						.forEach({ self.objectProc($0) })
				}

				if let commonPrefixes = output.commonPrefixes?.compactMap({ $0.prefix }) {
					// Add additionanl prefixes
					add(items: commonPrefixes)
				}

				if output.nextContinuationToken != nil {
					// More to go
					continuationToken = output.nextContinuationToken
				} else {
					// All done
					break
				}
				// Update
				partIndex += 1
				errorCount = 0
			} catch {
				// Error
				errorCount += 1
				if errorCount < 3 {
					// Will retry
					self.logger?.error(
							"    S3Client  - encountered error when listing objects for \(bucketReference): \(error), will retry")
				} else {
					// Report error
					self.logger?.error(
							"    S3Client  - encountered error when listing objects for \(bucketReference): \(error)")

					throw error
				}
			}
		}
	}
}
