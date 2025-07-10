//
//  S3ControlClient+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 1/29/25.
//

import AWSS3
import AWSS3Control
import SmithyIdentity

//----------------------------------------------------------------------------------------------------------------------
// MARK: S3ControlClient extensions
public extension S3ControlClient {

	// MARK: JobStatus
	struct JobStatus {

		// MARK: Properties
		public	var	status :S3ControlClientTypes.JobStatus { self.jobDescriptor.status! }

		public	var	totalTaskCount :Int { self.jobDescriptor.progressSummary!.totalNumberOfTasks! }
		public	var	succeededTaskCount :Int { self.jobDescriptor.progressSummary!.numberOfTasksSucceeded! }
		public	var	failedTaskCount :Int { self.jobDescriptor.progressSummary!.numberOfTasksFailed! }

		private	let	jobDescriptor :S3ControlClientTypes.JobDescriptor

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		fileprivate init(_ jobDescriptor :S3ControlClientTypes.JobDescriptor) {
			// Store
			self.jobDescriptor = jobDescriptor
		}
	}

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	convenience init(credentialIdentity :AWSCredentialIdentity, region :AWSRegion) async throws {
		// Setup
		let	credentialIdentityResolver = try! StaticAWSCredentialIdentityResolver(credentialIdentity)
		let	s3ClientConfiguration =
					try await S3ControlClient.S3ControlClientConfiguration(
							awsCredentialIdentityResolver: credentialIdentityResolver, region: region.tag)
		self.init(config: s3ClientConfiguration)
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func createJob(accountID :String, description :String, priority :Int,
			sourceBucket :S3ClientTypes.Bucket, sourcePrefixes :[String],
			destinationBucket :S3ClientTypes.Bucket, destinationPrefix :String,
			manifestBucket :S3ClientTypes.Bucket, manifestPrefix :String,
			jobReportBucket :S3ClientTypes.Bucket, jobReportPrefix :String,
			roleARN :String, logger :Logger? = nil) async throws -> String {
		// Setup
		let	manifestGenerator =
					S3ControlClientTypes.JobManifestGenerator.s3jobmanifestgenerator(
							S3ControlClientTypes.S3JobManifestGenerator(enableManifestOutput: true,
									filter:
											S3ControlClientTypes.JobManifestGeneratorFilter(
													keyNameConstraint:
															S3ControlClientTypes.KeyNameConstraint(
																	matchAnyPrefix: sourcePrefixes)
											),
									manifestOutputLocation:
											S3ControlClientTypes.S3ManifestOutputLocation(bucket: manifestBucket.arn,
													manifestFormat:
															S3ControlClientTypes.GeneratedManifestFormat
																	.s3inventoryreportCsv20211130,
													manifestPrefix: manifestPrefix),
									sourceBucket: sourceBucket.arn))
		let	operation =
					S3ControlClientTypes.JobOperation(
							s3PutObjectCopy:
									S3ControlClientTypes.S3CopyObjectOperation(checksumAlgorithm: .sha256,
											metadataDirective: .copy, targetKeyPrefix: destinationPrefix,
											targetResource: destinationBucket.arn))
		let	report =
					S3ControlClientTypes.JobReport(bucket: jobReportBucket.arn, enabled: true,
							format: S3ControlClientTypes.JobReportFormat.reportCsv20180820, prefix: jobReportPrefix,
							reportScope: S3ControlClientTypes.JobReportScope.alltasks)
		let input =
					CreateJobInput(accountId: accountID, clientRequestToken: UUID().uuidString,
							description: description, manifestGenerator: manifestGenerator, operation: operation,
							priority: priority, report: report, roleArn: roleARN)

		// Catch errors
		do {
			// Create job
			logger?.info("S3ControlClient creating job...")
			let output = try await createJob(input: input)

			return output.jobId!
		} catch {
			// Error
			logger?.error("    S3ControlClient  - encountered error: \(error)")

			throw error
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func describeJob(accountID :String, jobID :String, logger :Logger? = nil) async throws -> JobStatus {
		// Catch errors
		do {
			// Describe Job
			logger?.info("S3ControlClient - describing job \(jobID) in account \(accountID)...")
			let	output = try await describeJob(input: DescribeJobInput(accountId: accountID, jobId: jobID))

			return JobStatus(output.job!)
		} catch {
			// Error
			logger?.error("    S3ControlClient  - encountered error: \(error)")

			throw error
		}
	}
}
