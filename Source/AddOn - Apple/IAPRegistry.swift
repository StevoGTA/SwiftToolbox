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

	enum TransactionResult {
		case purchased
		case restored
		case cancelled
		case error
	}

	typealias PurchaseAvailabilityChangedProc = (_ product :IAPProduct, _ availableForPurchase :Bool) -> Void
	typealias TransactionResultChangedProc =
				(_ product :IAPProduct, _ transactionResult :TransactionResult, _ error :Error?) -> Void

	// MARK: Properties
				let	id :String
				let	kind :Kind

				let	purchaseAvailabilityChangedProc :PurchaseAvailabilityChangedProc
				let	transactionResultChangedProc :TransactionResultChangedProc

				var	isAvailableForPurchase :Bool { self.product != nil }
				var	isPurchasedOrActive :Bool {
							// What kind are we
							switch self.kind {
								case .consumable:
									// Consumable
									return false

								case .nonConsumable:
									// Non-consumable
									return self.purchaseDate != nil

								case .autoRenewableSubscription(_), .nonRenewableSubscription(_), .freeSubscription(_):
									// Subscriptions
									return (self.purchaseDate != nil) && (self.expirationDate! < Date())
							}
						}
				var	purchaseDate :Date?
				var	purchaseTransactionIdentifier :String?
				var	expirationDate :Date? {
							// Setup
							guard let purchaseDate = self.purchaseDate else { return nil }
							guard let period = self.kind.period else { return nil }

							return Calendar.current.date(byAdding: period, to: purchaseDate)
						}

	fileprivate	var	product :SKProduct?

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(id :String, kind :Kind,
			purchaseAvailabilityChangedProc :@escaping PurchaseAvailabilityChangedProc = { _,_ in },
			transactionResultChangedProc :@escaping TransactionResultChangedProc = { _,_,_ in }) {
		// Store
		self.id = id
		self.kind = kind

		self.purchaseAvailabilityChangedProc = purchaseAvailabilityChangedProc
		self.transactionResultChangedProc = transactionResultChangedProc

		// Check if can be restored
		if self.kind.isRestorable {
			// Restore
			let	storageKey = "IAPProduct:\(self.id)"
			if let storedInfo = UserDefaults.standard.dictionary(forKey: storageKey) {
				// Store info
				self.purchaseDate =
						Date.withTimeIntervalSince1970(storedInfo["purchaseTimeIntervalSince1970"] as? TimeInterval)
				self.purchaseTransactionIdentifier = storedInfo["purchaseTransactionIdentifier"] as? String
			}
		}
	}

	// MARK: Fileprivate methods
	//------------------------------------------------------------------------------------------------------------------
	fileprivate func process(paymentTransaction :SKPaymentTransaction) {
		// Check transaction state
		switch paymentTransaction.transactionState {
			case .purchasing, .deferred:
				// Purchasing
				break

			case .purchased, .restored:
				// Successfully purchased or restored
				self.purchaseDate =
						(paymentTransaction.original != nil) ?
								paymentTransaction.original?.transactionDate : paymentTransaction.transactionDate
				self.purchaseTransactionIdentifier = paymentTransaction.transactionIdentifier

				// Store for later
				let	storageKey = "IAPProduct:\(self.id)"
				UserDefaults.standard.set([
											"purchaseTimeIntervalSince1970": self.purchaseDate!.timeIntervalSince1970,
											"purchaseTransactionIdentifier": self.purchaseTransactionIdentifier!,
										  ],
										  forKey: storageKey)

				// Call handler
				self.transactionResultChangedProc(self,
						(paymentTransaction.transactionState == .purchased) ? .purchased : .restored, nil)

			case .failed:
				// Failed
				if (paymentTransaction.error! as NSError).code == SKError.Code.paymentCancelled.rawValue {
					// Cancelled
					// Call handler
					self.transactionResultChangedProc(self, .cancelled, nil)
				} else {
					// Some other error
					// Call handler
					self.transactionResultChangedProc(self, .error, paymentTransaction.error)
				}

			@unknown default:
				// How to know about these?
				break
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - IAPRegistry
class IAPRegistry : NSObject, SKPaymentTransactionObserver, SKProductsRequestDelegate {

	// MARK: Types
	typealias RetryUnavailableProductsCompletionProc = () -> Void
	typealias RestoreCompletedTransactionsCompletionProc = (_ error :Error?) -> Void

	// MARK: Properties
	static			let	shared = IAPRegistry()

	static			var	canMakePurchases :Bool { SKPaymentQueue.canMakePayments() }

			private	var	productsMap = [/* id */ String : IAPProduct]()

			private	var	activeProductsRequest :SKProductsRequest?
			private	var	activeProductsRequestCompletionProc :RetryUnavailableProductsCompletionProc?

			private	var	restoreCompletedTransactionsCompletionProc :RestoreCompletedTransactionsCompletionProc?

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	override init() {
		// Do super
		super.init()

		// Setup
		SKPaymentQueue.default().add(self)
	}

	// MARK: SKPaymentTransactionObserver methods
	//------------------------------------------------------------------------------------------------------------------
	func paymentQueue(_ queue :SKPaymentQueue, updatedTransactions transactions :[SKPaymentTransaction]) {
		// Iterate all transactions
		transactions.forEach() {
			// Get product
			let	product = self.productsMap[$0.payment.productIdentifier]!

			// Process
			product.process(paymentTransaction: $0)

			// Check state
			if $0.transactionState != .purchasing {
				// Finish transaction
				queue.finishTransaction($0)
			}
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
//	#if defined(_DEBUG)
//if response.invalidProductIdentifiers.count > 0
//			NSLog(@"IAPRegistry: received these invalid Product Identifiers: %@",
//					response.invalidProductIdentifiers);
//	#endif
		response.invalidProductIdentifiers.forEach() {
			// Call proc
			self.productsMap[$0]!.purchaseAvailabilityChangedProc(self.productsMap[$0]!, false)
		}

		// Handle valid products
		response.products.forEach() {
//	#if defined(_DEBUG)
//			NSLog(@"IAPRegistry: have active product with identifier: %@", product.productIdentifier);
//	#endif

			// Get product
			let	product = self.productsMap[$0.productIdentifier]!

			// Update product
			product.product = $0

			// Call proc
			product.purchaseAvailabilityChangedProc(product, true)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func requestDidFinish(_ request :SKRequest) {
//	#if defined(_DEBUG)
//		NSUInteger	activeProductsCount = 0;
//		for (IAPProduct* product in mProductsArray) {
//			if (product.product != nil)
//				activeProductsCount++;
//		}
//		NSLog(@"IAPRegistry: have total of %lu active products", (unsigned long) activeProductsCount);
//	#endif

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
//	#if defined(_DEBUG)
//		NSLog(@"IAPRegistry: request active products error: %@", error);
//	#endif

		// Iterate all products
		self.productsMap.values.forEach() { product in
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
		self.productsMap[product.id] = product
	}

	//------------------------------------------------------------------------------------------------------------------
	func add(_ products :[IAPProduct]) {
		// Iterate products
		products.forEach() { self.productsMap[$0.id] = $0 }
	}

	//------------------------------------------------------------------------------------------------------------------
	func retryUnavailableProducts(completionProc :@escaping RetryUnavailableProductsCompletionProc = {}) {
		// Store
		self.activeProductsRequestCompletionProc = completionProc

		// Setup
		let	productIDs = self.productsMap.values.filter({ !$0.isAvailableForPurchase }).map({ $0.id })

		// Do we have any un-resolved products
		if !productIDs.isEmpty {
			// Initiate request
			self.activeProductsRequest = SKProductsRequest(productIdentifiers: Set<String>(productIDs))
			self.activeProductsRequest!.delegate = self
			self.activeProductsRequest!.start()
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func product(for id :String) -> IAPProduct? { self.productsMap[id] }

	//------------------------------------------------------------------------------------------------------------------
	func purchase(product :IAPProduct, quantity :Int = 1) {
		// Setup
		let	payment = SKMutablePayment(product: product.product!)
		payment.quantity = quantity

		// Add to queue
		SKPaymentQueue.default().add(payment)
	}

	//------------------------------------------------------------------------------------------------------------------
	func purchase(id :String, quantity :Int = 1, productProc :(_ id :String) -> IAPProduct) {
		// Setup
		var	product = self.productsMap[id]
		if product == nil {
			// Create product
			product = productProc(id)
			self.productsMap[id] = product
		}

		// Check if available for purchase
		if product!.isAvailableForPurchase {
			// Purchase
			purchase(product: product!, quantity: quantity)
		} else {
			// Reload
			retryUnavailableProducts() { [weak self] in
				// Check if available for purchase
				if product!.isAvailableForPurchase {
					// Available
					self?.purchase(product: product!, quantity: quantity)
				} else {
					// Unavailable
					product!.transactionResultChangedProc(product!, .error,
							IAPRegistryError.productNotAvailableForPurchase(productID: id))
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
