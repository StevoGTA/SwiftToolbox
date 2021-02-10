//
//  IAPRegistry.swift
//  Swift Toolbox
//
//  Created by Stevo on 3/19/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import StoreKit

//----------------------------------------------------------------------------------------------------------------------
// MARK: Notifications
extension Notification.Name {
	/*
		Sent when the set of active products has been udpated.
			object is IAPRegistry
	*/
	static	public	let	iapRegistryProductsUpdated = Notification.Name("iapRegistryProductsUpdated")
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: IAPRegistryError
enum IAPRegistryError : Error {
	case productNotAvailableForPurchase(productID :String)
}

extension IAPRegistryError : LocalizedError {

	// MARK: Properties
	public	var	errorDescription :String? {
						// What are we
						switch self {
							case .productNotAvailableForPurchase(let productID):
									return "IProduct ID \(productID) is not available for purchase"
						}
					}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - IAPProduct
class IAPProduct {

	// MARK: Types
	enum Kind {
		// Values
		case consumable
		case nonConsumable
		case autoRenewableSubscription(_ period :DateComponents?)
		case nonRenewableSubscription(_ period :DateComponents?)
		case freeSubscription(_ period :DateComponents?)

		// Properties
		var	period :DateComponents? {
					// Extract period
					switch self {
						case .consumable, .nonConsumable:
							// No period
							return nil

						case .autoRenewableSubscription(let period), .nonRenewableSubscription(let period),
								.freeSubscription(let period):
							// Have period
							return period
					}
				}
		var	isRestorable :Bool { if case Kind.consumable = self { return false } else { return true } }
	}

	enum PeriodLength {
		case none
		case oneYear
	}

	typealias PurchaseAvailabilityChangedProc = (_ product :IAPProduct, _ availableForPurchase :Bool) -> Void

	// MARK: Properties
				let	id :String
				let	kind :Kind

				let	purchaseAvailabilityChangedProc :PurchaseAvailabilityChangedProc

				var	isAvailableForPurchase :Bool { self.product != nil }

	fileprivate	var	product :SKProduct?

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(id :String, kind :Kind,
			purchaseAvailabilityChangedProc :@escaping PurchaseAvailabilityChangedProc = { _,_ in }) {
		// Store
		self.id = id
		self.kind = kind

		self.purchaseAvailabilityChangedProc = purchaseAvailabilityChangedProc
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func expirationDate(with purchaseDate :Date) -> Date? {
		// Setup
		guard let period = self.kind.period else { return nil }

		return Calendar.current.date(byAdding: period, to: purchaseDate)
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - IAPRegistry
class IAPRegistry : NSObject, SKPaymentTransactionObserver, SKProductsRequestDelegate {

	// MARK: Types
	typealias RetryUnavailableProductsCompletionProc = () -> Void
	typealias RestoreCompletedTransactionsCompletionProc = (_ error :Error?) -> Void

	typealias PurchaseStateInfo =
			(productIdentifier :String, paymentTransactionState :SKPaymentTransactionState,
					purchaseTransactionIdentifier :String?, purchaseDate :Date?, error :Error?)
	typealias PurchaseStateChangeProc =
			(_ purchaseStateInfo :PurchaseStateInfo, _ info :[String : Any]?) -> Void

	// MARK: Properties
	static			let	shared = IAPRegistry()

	static			var	canMakePurchases :Bool { SKPaymentQueue.canMakePayments() }

			private	let	sqliteDatabase :SQLiteDatabase
			private	let	infoTable :SQLiteTable
			private	let	purchasesTable :SQLiteTable

			private	let	purchaseStateChangeProcProcs = LockingDictionary<String, PurchaseStateChangeProc>()

			private	var	productsCache = [/* id */ String : IAPProduct]()

			private	var	activeProductsRequest :SKProductsRequest?
			private	var	activeProductsRequestCompletionProc :RetryUnavailableProductsCompletionProc?

			private	var	restoreCompletedTransactionsCompletionProc :RestoreCompletedTransactionsCompletionProc?

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	override init() {
		// Catch errors
		do {
			// Setup
			self.sqliteDatabase =
					try SQLiteDatabase(in: FileManager.default.folder(for: .libraryDirectory), with: "IAPRegistry")
			self.infoTable =
					self.sqliteDatabase.table(name: "Info", options: [.withoutRowID],
							tableColumns: [
											SQLiteTableColumn("key", .text, [.primaryKey, .unique, .notNull]),
											SQLiteTableColumn("value", .text, [.notNull]),
										  ])
			self.purchasesTable =
					self.sqliteDatabase.table(name: "Purchases",
							tableColumns: [
											SQLiteTableColumn("id", .text, [.notNull, .primaryKey]),
											SQLiteTableColumn("productIdentifier", .text, [.notNull]),
											SQLiteTableColumn("quantity", .integer, [.notNull]),
											SQLiteTableColumn("info", .blob),
											SQLiteTableColumn("time", .real, [.notNull]),
											SQLiteTableColumn("transactionState", .integer),
											SQLiteTableColumn("purchaseTransactionIdentifier", .text),
											SQLiteTableColumn("purchaseTime", .real),
											SQLiteTableColumn("purchaseError", .text),
										  ])
		} catch {
			// Error
			fatalError("IAPRegistry unable to initialize database.")
		}

		// Do super
		super.init()

		// Finish setup
		self.infoTable.create()

		var	version :Int?
		try! self.infoTable.select(tableColumns: [self.infoTable.valueTableColumn],
				where: SQLiteWhere(tableColumn: self.infoTable.keyTableColumn, value: "version")) {
			// Process values
			version = Int($0.text(for: self.infoTable.valueTableColumn)!)!
		}

		self.purchasesTable.create()

		if version == nil {
			// Initialize version
			version = 1
			_ = self.infoTable.insertRow([
											(self.infoTable.keyTableColumn, "version"),
											(self.infoTable.valueTableColumn, version!),
										 ])
		}

		SKPaymentQueue.default().add(self)
	}

	// MARK: SKPaymentTransactionObserver methods
	//------------------------------------------------------------------------------------------------------------------
	func paymentQueue(_ queue :SKPaymentQueue, updatedTransactions transactions :[SKPaymentTransaction]) {
		// Iterate all transactions
		transactions.forEach() { paymentTransaction in
			// Get purchases that match the product identifier
			typealias PurchaseInfo =
					(id :String, info :[String : Any]?, transactionState :SKPaymentTransactionState?,
							purchaseTransactionIdentifier :String?)

			let	productIdentifier = paymentTransaction.payment.productIdentifier
			var	purchaseInfos = [PurchaseInfo]()
			try! self.purchasesTable.select(
					tableColumns: [
									self.purchasesTable.idTableColumn,
									self.purchasesTable.infoTableColumn,
									self.purchasesTable.transactionStateTableColumn,
									self.purchasesTable.purchaseTransactionIdentifierTableColumn,
								  ],
					where:
							SQLiteWhere(tableColumn: self.purchasesTable.productIdentifierTableColumn,
									value: productIdentifier)) {
						// Process values
						let	id = $0.text(for: self.purchasesTable.idTableColumn)!
						let	info :[String : Any]? = Dictionary.from($0.blob(for: self.purchasesTable.infoTableColumn))
						let	transactionState :Int? = $0.integer(for: self.purchasesTable.transactionStateTableColumn)
						let	purchaseTransactionIdentifier =
									$0.text(for: self.purchasesTable.purchaseTransactionIdentifierTableColumn)

						// Add
						purchaseInfos.append(
								(id, info,
										(transactionState != nil) ?
												SKPaymentTransactionState(rawValue: transactionState!) : nil,
										purchaseTransactionIdentifier))
					}
			guard !purchaseInfos.isEmpty else {
				// Not found
				NSLog("IAPRegistery - did not find any entries matching \(productIdentifier)")

				// Go ahead and finish
				queue.finishTransaction(paymentTransaction)

				return
			}

			// Check transaction state
			let	purchaseInfo :PurchaseInfo!
			var	purchaseDate :Date? = nil
			var	error :Error? = nil
			switch paymentTransaction.transactionState {
				case .purchasing:
					// In-progress
					purchaseInfo =
							purchaseInfos.first()
								{ ($0.purchaseTransactionIdentifier == nil) && ($0.transactionState == nil) }
					guard purchaseInfo != nil else {
						NSLog("IAPRegistry - did not find any entries not already in-progress for \(productIdentifier):")
						NSLog("\(purchaseInfos)")

						return
					}

					// Update
					self.purchasesTable.update(
							[
								(self.purchasesTable.transactionStateTableColumn,
										paymentTransaction.transactionState.rawValue),
							],
							where: SQLiteWhere(tableColumn: self.purchasesTable.idTableColumn, value: purchaseInfo!.id))

					return

				case .purchased:
					// Successfully purchased
					purchaseInfo =
							purchaseInfos.first()
								{ ($0.purchaseTransactionIdentifier == nil) && ($0.transactionState == .purchasing) }
					guard purchaseInfo != nil else {
						NSLog("IAPRegistry - did not find any entries in-progress for \(productIdentifier):")
						NSLog("\(purchaseInfos)")

						return
					}

					purchaseDate = paymentTransaction.original?.transactionDate ?? paymentTransaction.transactionDate
					self.purchasesTable.update(
							[
								(self.purchasesTable.transactionStateTableColumn,
										paymentTransaction.transactionState.rawValue),
								(self.purchasesTable.purchaseTransactionIdentifierTableColumn,
										paymentTransaction.transactionIdentifier!),
								(self.purchasesTable.purchaseTimeTableColumn, purchaseDate!.timeIntervalSince1970),
							],
							where: SQLiteWhere(tableColumn: self.purchasesTable.idTableColumn, value: purchaseInfo!.id))

					// We have handled the transaction
					queue.finishTransaction(paymentTransaction)

				case .failed:
					// Failed
					purchaseInfo =
							purchaseInfos.first()
								{ ($0.purchaseTransactionIdentifier == nil) && ($0.transactionState == .purchasing) }
					guard purchaseInfo != nil else {
						NSLog("IAPRegistry - did not find any entries not already in-progress for \(productIdentifier):")
						NSLog("\(purchaseInfos)")

						return
					}

					error = paymentTransaction.error
					if (error! as NSError).code == SKError.Code.paymentCancelled.rawValue {
						// Cancelled
						self.purchasesTable.update(
								[
									(self.purchasesTable.transactionStateTableColumn,
											paymentTransaction.transactionState.rawValue),
								],
								where:
										SQLiteWhere(tableColumn: self.purchasesTable.idTableColumn,
												value: purchaseInfo!.id))
					} else {
						// Some other error
						self.purchasesTable.update(
								[
									(self.purchasesTable.transactionStateTableColumn,
											paymentTransaction.transactionState.rawValue),
									(self.purchasesTable.purchaseTransactionIdentifierTableColumn,
											paymentTransaction.transactionIdentifier as Any),
									(self.purchasesTable.purchaseErrorTableColumn,
											error!.localizedDescription),
								],
								where:
										SQLiteWhere(tableColumn: self.purchasesTable.idTableColumn,
												value: purchaseInfo!.id))
					}

					// We have handled the transaction
					queue.finishTransaction(paymentTransaction)

				case .deferred, .restored:
					// Unimplemented since we don't know the flow
					fatalError("Unimplemented")

				@unknown default:
					// How to know about these?
					fatalError("IAPRegistry unknown transaction state")
			}

			let	purchaseStateInfo =
						(productIdentifier, paymentTransaction.transactionState,
								paymentTransaction.transactionIdentifier, purchaseDate, error)
			self.purchaseStateChangeProcProcs.value(for: purchaseInfo.id)?(purchaseStateInfo, purchaseInfo.info)
			self.purchaseStateChangeProcProcs.remove(purchaseInfo.id)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func paymentQueue(_ queue :SKPaymentQueue, removedTransactions transactions :[SKPaymentTransaction]) {}

	//------------------------------------------------------------------------------------------------------------------
	func paymentQueue(_ queue :SKPaymentQueue, restoreCompletedTransactionsFailedWithError error :Error) {
		// Call proc
		self.restoreCompletedTransactionsCompletionProc!(error)

		// Cleanup
		self.restoreCompletedTransactionsCompletionProc = nil
	}

	//------------------------------------------------------------------------------------------------------------------
	func paymentQueueRestoreCompletedTransactionsFinished(_ queue :SKPaymentQueue) {
		// Call proc
		self.restoreCompletedTransactionsCompletionProc!(nil)

		// Cleanup
		self.restoreCompletedTransactionsCompletionProc = nil
	}

	// MARK: SKProductsRequestDelegate methods
	//------------------------------------------------------------------------------------------------------------------
	func productsRequest(_ request :SKProductsRequest, didReceive response :SKProductsResponse) {
		// Handle invalid product identifiers
		response.invalidProductIdentifiers.forEach() {
			// Call proc
			self.productsCache[$0]!.purchaseAvailabilityChangedProc(self.productsCache[$0]!, false)
		}

		// Handle valid products
		response.products.forEach() {
			// Get product
			let	product = self.productsCache[$0.productIdentifier]!

			// Update product
			product.product = $0

			// Call proc
			product.purchaseAvailabilityChangedProc(product, true)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func requestDidFinish(_ request :SKRequest) {
		// Call proc
		self.activeProductsRequestCompletionProc!()

		// Cleanup
		self.activeProductsRequest = nil
		self.activeProductsRequestCompletionProc = nil

		// Post Notification
		NotificationCenter.default.post(name: .iapRegistryProductsUpdated, object: self)
	}

	//------------------------------------------------------------------------------------------------------------------
	func request(_ request :SKRequest, didFailWithError error :Error) {
		// Iterate all products
		self.productsCache.values.forEach() { product in
			// Check if have a product yet
			guard product.product != nil else { return }

			// Call procs
			product.purchaseAvailabilityChangedProc(product, false)
		}

		// Call proc
		self.activeProductsRequestCompletionProc!()

		// Cleanup
		self.activeProductsRequest = nil
		self.activeProductsRequestCompletionProc = nil
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func add(_ product :IAPProduct) {
		// Store info
		self.productsCache[product.id] = product
	}

	//------------------------------------------------------------------------------------------------------------------
	func add(_ products :[IAPProduct]) {
		// Iterate products
		products.forEach() { self.productsCache[$0.id] = $0 }
	}

	//------------------------------------------------------------------------------------------------------------------
	func retryUnavailableProducts(completionProc :@escaping RetryUnavailableProductsCompletionProc = {}) {
		// Store
		self.activeProductsRequestCompletionProc = completionProc

		// Setup
		let	productIDs = self.productsCache.values.filter({ !$0.isAvailableForPurchase }).map({ $0.id })

		// Do we have any un-resolved products
		if !productIDs.isEmpty {
			// Initiate request
			self.activeProductsRequest = SKProductsRequest(productIdentifiers: Set<String>(productIDs))
			self.activeProductsRequest!.delegate = self
			self.activeProductsRequest!.start()
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func product(for id :String) -> IAPProduct? { self.productsCache[id] }

	//------------------------------------------------------------------------------------------------------------------
	func purchase(product :IAPProduct, quantity :Int = 1, info :[String : Any]? = nil,
			purchaseStateChangeProc :@escaping PurchaseStateChangeProc = { _,_ in }) {
		// Setup
		let	payment = SKMutablePayment(product: product.product!)
		payment.quantity = quantity

		// Store
		let	id = UUID().base64EncodedString
		if info != nil {
			// Have data
			_ = self.purchasesTable.insertRow([
												(self.purchasesTable.idTableColumn, id),
												(self.purchasesTable.productIdentifierTableColumn,
														product.product!.productIdentifier),
												(self.purchasesTable.quantityTableColumn, quantity),
												(self.purchasesTable.infoTableColumn,
														try! JSONSerialization.data(withJSONObject: info!,
																options: [])),
												(self.purchasesTable.timeTableColumn, Date().timeIntervalSince1970),
											  ])
		} else {
			// Don't have data
			_ = self.purchasesTable.insertRow([
												(self.purchasesTable.idTableColumn, id),
												(self.purchasesTable.productIdentifierTableColumn,
														product.product!.productIdentifier),
												(self.purchasesTable.quantityTableColumn, quantity),
												(self.purchasesTable.timeTableColumn, Date().timeIntervalSince1970),
											  ])
		}

		// Store proc
		self.purchaseStateChangeProcProcs.set(purchaseStateChangeProc, for: id)

		// Add to queue
		SKPaymentQueue.default().add(payment)
	}

	//------------------------------------------------------------------------------------------------------------------
	func purchase(id :String, quantity :Int = 1, info :[String : Any]? = nil, productProc :(_ id :String) -> IAPProduct,
			purchaseStateChangeProc :@escaping PurchaseStateChangeProc = { _,_ in }) {
		// Setup
		var	product = self.productsCache[id]
		if product == nil {
			// Create product
			product = productProc(id)
			self.productsCache[id] = product
		}

		// Check if available for purchase
		if product!.isAvailableForPurchase {
			// Purchase
			purchase(product: product!, quantity: quantity, info: info,
					purchaseStateChangeProc: purchaseStateChangeProc)
		} else {
			// Reload
			retryUnavailableProducts() { [weak self] in
				// Check if available for purchase
				if product!.isAvailableForPurchase {
					// Available
					self?.purchase(product: product!, quantity: quantity, info: info,
							purchaseStateChangeProc: purchaseStateChangeProc)
				} else {
					// Unavailable
					purchaseStateChangeProc(
							(id, .failed, nil, nil, IAPRegistryError.productNotAvailableForPurchase(productID: id)),
									info)
				}
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func restoreCompletedTransactions(completionProc :@escaping RestoreCompletedTransactionsCompletionProc = { _ in }) {
		// Store
		self.restoreCompletedTransactionsCompletionProc = completionProc

		// Restore completed transactions
		SKPaymentQueue.default().restoreCompletedTransactions()
	}
}
