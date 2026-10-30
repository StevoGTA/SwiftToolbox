//----------------------------------------------------------------------------------------------------------------------
//	CURLSessionHTTPTransport.mm			©2026 Stevo Brock	All rights reserved.
//----------------------------------------------------------------------------------------------------------------------

#import "CURLSessionHTTPTransport.h"

#import "CCoreFoundation.h"
#import "SError-Apple.h"
#import "Swift.h"

//----------------------------------------------------------------------------------------------------------------------
// MARK: CURLSessionHTTPTransport::Internals

class CURLSessionHTTPTransport::Internals {
	// Task
	public:
		class Task : public CHTTPTransport::Task {
			public:
						Task(id<HTTPTransportTask> transportTask) : mTransportTask(transportTask) {}

				void	cancel()
							{ [mTransportTask cancel]; }

				id<HTTPTransportTask>	mTransportTask;
		};

	public:
		Internals() :
			mURLSessionHTTPTransport(
					[[URLSessionHTTPTransport alloc]
							initWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration])
			{}

		URLSessionHTTPTransport*	mURLSessionHTTPTransport;
};

//----------------------------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------------------------
// MARK: - CURLSessionHTTPTransport

// MARK: Lifecycle methods

//----------------------------------------------------------------------------------------------------------------------
CURLSessionHTTPTransport::CURLSessionHTTPTransport()
//----------------------------------------------------------------------------------------------------------------------
{
	mInternals = new Internals();
}

//----------------------------------------------------------------------------------------------------------------------
CURLSessionHTTPTransport::~CURLSessionHTTPTransport()
//----------------------------------------------------------------------------------------------------------------------
{
	Delete(mInternals);
}

// MARK: CHTTPTransport methods

//----------------------------------------------------------------------------------------------------------------------
UInt32 CURLSessionHTTPTransport::getMaximumConcurrentRequests() const
//----------------------------------------------------------------------------------------------------------------------
{
	return (UInt32) mInternals->mURLSessionHTTPTransport.maximumConcurrentRequests;
}

//----------------------------------------------------------------------------------------------------------------------
I<CHTTPTransport::Task> CURLSessionHTTPTransport::perform(const Request& request, CompletionProc completionProc,
		void* userData)
//----------------------------------------------------------------------------------------------------------------------
{
	// Setup
	NSMutableURLRequest*	urlRequest =
									[NSMutableURLRequest
											requestWithURL:
													[NSURL URLWithString:
															(__bridge NSString*) request.getURLString().getOSString()]];
	switch (request.getMethod()) {
		case kMethodDelete:	urlRequest.HTTPMethod = @"DELETE";	break;
		case kMethodGet:	urlRequest.HTTPMethod = @"GET";		break;
		case kMethodHead:	urlRequest.HTTPMethod = @"HEAD";	break;
		case kMethodPatch:	urlRequest.HTTPMethod = @"PATCH";	break;
		case kMethodPost:	urlRequest.HTTPMethod = @"POST";	break;
		case kMethodPut:	urlRequest.HTTPMethod = @"PUT";		break;
	}
	urlRequest.allHTTPHeaderFields =
			(__bridge NSDictionary*) *CCoreFoundation::dictionaryRefFrom(request.getHeaders());
	urlRequest.HTTPBody =
			request.getBody().hasValue() ?
					(__bridge NSData*) *CCoreFoundation::dataRefFrom(*request.getBody()) : nil;
	urlRequest.timeoutInterval = request.getTimeoutInterval();

	// Perform
	id<HTTPTransportTask>	transportTask =
									[mInternals->mURLSessionHTTPTransport perform:urlRequest redirectBody:nil
											completionProc:^(NSHTTPURLResponse* response, NSData* data,
													NSError* error) {
												// Call proc
												completionProc(
														(error != nil) ?
																TVResult<SHTTPEndpointResponse>(
																		SErrorFromNSError(error)) :
																TVResult<SHTTPEndpointResponse>(
																		SHTTPEndpointResponse(
																				SHTTPEndpointStatus(
																						(UInt32) response.statusCode),
																				CCoreFoundation::dictionaryFrom(
																						(__bridge CFDictionaryRef)
																								response.allHeaderFields),
																				(data != nil) ?
																						OV<CData>(
																								CCoreFoundation::dataFrom(
																										(__bridge CFDataRef)
																												data)) :
																						OV<CData>())),
														userData);
											}];

	return I<CHTTPTransport::Task>(new Internals::Task(transportTask));
}
