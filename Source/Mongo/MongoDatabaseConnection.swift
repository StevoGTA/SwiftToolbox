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

	// MARK: Properties
	static	private	let	activeCount = LockingNumeric<Int>()

			private	let	eventLoopGroup :MultiThreadedEventLoopGroup
			private	let	mongoClient :MongoClient
			private	let	mongoDatabase :MongoDatabase

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(mongoClientConnectionInfo :MongoClient.ConnectionInfo, database :String) {
		// One more active
		type(of: self).activeCount.add(1)

		// Setup
		self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 4)
		self.mongoClient = MongoClient(mongoClientConnectionInfo, using: self.eventLoopGroup)
		self.mongoDatabase = mongoClient.db(database)
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
	public func listCollectionNames() async throws -> [String] {
		// Return collection names
		return try await self.mongoDatabase.listCollectionNames()
	}

	//------------------------------------------------------------------------------------------------------------------
	public func documents(in name :String) async throws -> MongoCursor<BSONDocument> {
		// Return documents
		return try await self.mongoDatabase.collection(name).find()
	}

	//------------------------------------------------------------------------------------------------------------------
	public func document(in name :String, matching :BSONDocument) async throws -> BSONDocument? {
		// Return document
		return try await self.mongoDatabase.collection(name).findOne(matching)
	}

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func insert(document :BSONDocument, in name :String) async throws -> InsertOneResult {
		// Insert one
		return try await self.mongoDatabase.collection(name).insertOne(document)!
	}

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func update(document :BSONDocument, with update :BSONDocument, in name :String) async throws ->
			UpdateResult {
		// Update
		try await self.mongoDatabase.collection(name).updateOne(filter: document, update: update)!
	}

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func update(document :BSONDocument, with update :BSONDocument, in name :String) throws ->
			UpdateResult {
		// Update
		try self.mongoDatabase.collection(name).updateOne(filter: document, update: update).wait()!
	}
}
