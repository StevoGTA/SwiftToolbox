//
//  KeychainStorage.swift
//  Swift Toolbox
//
//  Created by Stevo on 8/26/26.
//  Copyright © 2026 Stevo Brock. All rights reserved.
//

import Foundation
import Security

//----------------------------------------------------------------------------------------------------------------------
// MARK: KeychainStorageError
public struct KeychainStorageError : CustomStringConvertible, Error, LocalizedError {

	// MARK: CustomStringConvertible implementation
	public	var	description :String { self.localizedDescription }

	// MARK: LocalizedError implementation
	public	var	errorDescription :String? {
						// Try to compose message from status
						if let message = SecCopyErrorMessageString(self.status, nil) as String? {
							// Have message
							return "\(message) (\(self.status))"
						} else {
							// No message
							return "Keychain error \(self.status)"
						}
					}

	// MARK: Properties
	public	let	status :OSStatus
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - KeychainStorage
/*
	Simple key/value storage in the Keychain — one generic-password item per (service, key).

	Items are stored with accessibility "after first unlock" so they can be read by background
	work once the device has been unlocked at least once since restart.
*/
public class KeychainStorage {

	// MARK: Properties
	private	let	service :String

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(service :String) {
		// Store
		self.service = service
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func data(for key :String) -> Data? {
		// Setup
		let	query :[CFString : Any] =
					[
						kSecClass: kSecClassGenericPassword,
						kSecAttrService: self.service,
						kSecAttrAccount: key,
						kSecReturnData: true,
						kSecMatchLimit: kSecMatchLimitOne,
					]

		// Retrieve
		var	result :CFTypeRef?
		let	status = SecItemCopyMatching(query as CFDictionary, &result)

		return (status == errSecSuccess) ? (result as? Data) : nil
	}

	//------------------------------------------------------------------------------------------------------------------
	public func string(for key :String) -> String? {
		// Retrieve data
		guard let data = data(for: key) else { return nil }

		return String(data: data, encoding: .utf8)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func set(_ data :Data?, for key :String) throws {
		// Check for data
		if let data {
			// Remove any existing item, then add
			try? remove(for: key)

			let	attributes :[CFString : Any] =
						[
							kSecClass: kSecClassGenericPassword,
							kSecAttrService: self.service,
							kSecAttrAccount: key,
							kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
							kSecValueData: data,
						]
			let	status = SecItemAdd(attributes as CFDictionary, nil)
			guard status == errSecSuccess else { throw KeychainStorageError(status: status) }
		} else {
			// No data means remove
			try remove(for: key)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public func set(_ string :String?, for key :String) throws { try set(string?.data(using: .utf8), for: key) }

	//------------------------------------------------------------------------------------------------------------------
	public func remove(for key :String) throws {
		// Setup
		let	query :[CFString : Any] =
					[
						kSecClass: kSecClassGenericPassword,
						kSecAttrService: self.service,
						kSecAttrAccount: key,
					]

		// Remove
		let	status = SecItemDelete(query as CFDictionary)
		guard (status == errSecSuccess) || (status == errSecItemNotFound) else {
			// Error
			throw KeychainStorageError(status: status)
		}
	}
}
