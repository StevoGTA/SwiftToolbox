//
//  MongoDatabaseConnection.swift
//  Swift Toolbox
//
//  Created by Stevo on 2/1/24.
//  Copyright © 2024 Stevo Brock. All rights reserved.
//

import MongoSwift
import NIOPosix

//----------------------------------------------------------------------------------------------------------------------
// MARK: MongoDatabaseConnection
public class MongoDatabaseConnection {

	// MARK: Error
	enum Error : Swift.Error, CustomStringConvertible, LocalizedError {
		// MARK: Values
		case noDatabaseSpecified

		// MARK: Properties
		public	var	description :String { self.localizedDescription }
		public	var	errorDescription :String? {
							switch self {
								case .noDatabaseSpecified:
									return "MongoDatabaseConnection - No database specified"
							}
						}
	}

	// MARK: Properties
	static	private	let	activeCount = LockingNumeric<Int>()

			private	let	eventLoopGroup :MultiThreadedEventLoopGroup
			private	let	mongoClient :MongoClient
			private	let	mongoDatabase :MongoDatabase?

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(mongoClientConnectionInfo :MongoClient.ConnectionInfo, databaseName :String? = nil) throws {
		// One more active
		type(of: self).activeCount.add(1)

		// Setup
		self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 4)
		self.mongoClient = try MongoClient(mongoClientConnectionInfo, using: self.eventLoopGroup)
		self.mongoDatabase = (databaseName != nil) ? mongoClient.db(databaseName!) : nil
	}

	//------------------------------------------------------------------------------------------------------------------
	public init(connectionString :String, databaseName :String? = nil) throws {
		// One more active
		type(of: self).activeCount.add(1)

		// Setup
		self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 4)
		self.mongoClient = try MongoClient(connectionString, using: self.eventLoopGroup)
		self.mongoDatabase = (databaseName != nil) ? mongoClient.db(databaseName!) : nil
	}

	//------------------------------------------------------------------------------------------------------------------
	deinit {
		// Cleanup
		try? mongoClient.syncClose()
		try? eventLoopGroup.syncShutdownGracefully()

		// Check for last one
		if type(of: self).activeCount.subtract(1) == 0 {
			// Final cleanup
			cleanupMongoSwift()
		}
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func validateConnection() async throws {
		// We want to perform the lightest operation possible just to verify the connection is actually real
		_ = try await self.mongoClient.listDatabaseNames()
	}

	//------------------------------------------------------------------------------------------------------------------
	public func validateConnection() throws {
		// Preflight
		guard let mongoDatabase = self.mongoDatabase else { throw Self.Error.noDatabaseSpecified }

		// We want to perform the lightest operation possible just to verify the connection is actually real
		_ = try mongoDatabase.listCollectionNames().wait()
	}

	//------------------------------------------------------------------------------------------------------------------
	public func listCollectionNames() async throws -> [String] {
		// Preflight
		guard let mongoDatabase = self.mongoDatabase else { throw Self.Error.noDatabaseSpecified }

		// Return collection names
		return try await mongoDatabase.listCollectionNames()
	}

	//------------------------------------------------------------------------------------------------------------------
	public func documents(in name :String, filter :BSONDocument = [:]) async throws -> MongoCursor<BSONDocument> {
		// Preflight
		guard let mongoDatabase = self.mongoDatabase else { throw Self.Error.noDatabaseSpecified }

		// Return documents
		return try await mongoDatabase.collection(name).find(filter)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func document(in name :String, filter :BSONDocument) async throws -> BSONDocument? {
		// Preflight
		guard let mongoDatabase = self.mongoDatabase else { throw Self.Error.noDatabaseSpecified }

		// Return document
		return try await mongoDatabase.collection(name).findOne(filter)
	}

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func insert(document :BSONDocument, in name :String) async throws -> InsertOneResult {
		// Preflight
		guard let mongoDatabase = self.mongoDatabase else { throw Self.Error.noDatabaseSpecified }

		// Insert one
		return try await mongoDatabase.collection(name).insertOne(document)!
	}

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func update(filter :BSONDocument, with update :BSONDocument, in name :String) async throws ->
			UpdateResult {
		// Preflight
		guard let mongoDatabase = self.mongoDatabase else { throw Self.Error.noDatabaseSpecified }

		// Update
		return try await mongoDatabase.collection(name).updateOne(filter: filter, update: update)!
	}

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func update(document :BSONDocument, with update :BSONDocument, in name :String) async throws ->
			UpdateResult {
		// Update
		try await self.update(filter: ["_id": document["_id"]!], with: update, in: name)
	}

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func update(filter :BSONDocument, with update :BSONDocument, in name :String) throws ->
			UpdateResult {
		// Preflight
		guard let mongoDatabase = self.mongoDatabase else { throw Self.Error.noDatabaseSpecified }

		// Update
		return try mongoDatabase.collection(name).updateOne(filter: filter, update: update).wait()!
	}

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func update(document :BSONDocument, with update :BSONDocument, in name :String) throws ->
			UpdateResult {
		// Update
		try self.update(filter: ["_id": document["_id"]!], with: update, in: name)
	}
}
