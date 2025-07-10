//
//  AWSProfile.swift
//  Swift Toolbox
//
//  Created by Stevo on 2/5/25.
//

import AwsCSdkUtils

//----------------------------------------------------------------------------------------------------------------------
// MARK: AWSProfileRepository
public class AWSProfileRepository {

	// MARK: Properties
	static	public	let	`default` = try? AWSProfileRepository()

			public	var	profiles :[AWSProfile] { Array(self.profileByName.values) }

			private	var	profileByName = [String : AWSProfile]()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(configFile :File, credentialsFile :File) throws {
		// Load
		let	strings =
					((try FileReader.contentsAsString(of: configFile)?.components(separatedBy: .newlines) ?? []) +
							(try FileReader.contentsAsString(of: credentialsFile)?.components(separatedBy: .newlines) ??
									[]))

		// Iterate
		var	currentAWSProfile :AWSProfile?
		strings.forEach() {
			// Check string
			if $0.hasPrefix("[") && $0.hasSuffix("]") {
				// Profile name
				let	profileName = $0.substring(fromCharacterIndex: 1, toCharacterIndex: $0.count - 1)
				currentAWSProfile = self.profileByName[profileName]
				if currentAWSProfile == nil {
					// First time seeing this prpfile
					currentAWSProfile = AWSProfile(name: profileName)
					self.profileByName[profileName] = currentAWSProfile
				}
			} else {
				// Possibly info
				let	components = $0.components(separatedBy: "=")
				if components.count == 2 {
					// Property
					currentAWSProfile?.set(value: components[1].trimmingCharacters(in: .whitespaces),
							for: components[0].trimmingCharacters(in: .whitespaces))
				}
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	convenience init() throws {
		// Setup
		let	homeDirectory = FileManager.default.homeDirectoryForCurrentUser
		try self.init(configFile: File(homeDirectory.appendingPathComponent(".aws/config")),
				credentialsFile: File(homeDirectory.appendingPathComponent(".aws/credentials")))
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - AWSProfile
public class AWSProfile {

	// MARK: CredentialProcess
	public struct CredentialProcess {

		// MARK: Properties
		public	let	accountID :String?
		public	let	role :String?

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init?(_ string :String?) {
			// Preflight
			guard string != nil else { return nil }

			// Process string
			var	accountID :String?
			var	role :String?
			let	components = string!.components(separatedBy: " ")
			components.enumerated().forEach() {
				// Check pieces parts
				if ($0.element == "-a") && (components.count > ($0.offset + 1)) {
					// Account ID
					accountID = components[$0.offset + 1]
				} else if ($0.element == "-r") && (components.count > ($0.offset + 1)) {
					// Role
					role = components[$0.offset + 1]
				}
			}
			self.accountID = accountID
			self.role = role
		}
	}

	// MARK: Properties
	public	let	name :String

	public	var	credentialProcess :CredentialProcess? { CredentialProcess(self.properties["credential_process"]) }

	private	var	properties = [String : String]()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(name :String) {
		// Store
		self.name = name
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func value(for name :String) -> String? { self.properties[name] }

	//------------------------------------------------------------------------------------------------------------------
	func set(value :String, for name :String) { self.properties[name] = value }
}
