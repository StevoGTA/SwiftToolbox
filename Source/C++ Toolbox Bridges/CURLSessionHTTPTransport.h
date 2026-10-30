//----------------------------------------------------------------------------------------------------------------------
//	CURLSessionHTTPTransport.h			©2026 Stevo Brock	All rights reserved.
//----------------------------------------------------------------------------------------------------------------------

#pragma once

#include "CHTTPTransport.h"

//----------------------------------------------------------------------------------------------------------------------
// MARK: CURLSessionHTTPTransport

class CURLSessionHTTPTransport : public CHTTPTransport {
	// Classes
	private:
		class Internals;

	// Methods
	public:
				// Lifecycle methods
				CURLSessionHTTPTransport();
				~CURLSessionHTTPTransport();

				// CHTTPTransport methods
		UInt32	getMaximumConcurrentRequests() const;
		I<Task>	perform(const Request& request, CompletionProc completionProc, void* userData);

	// Properties
	private:
		Internals*	mInternals;
};
