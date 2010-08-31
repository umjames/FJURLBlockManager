//
//  HTTPBlockURLRequest.m
//  FJBlockURLManager
//
//  Created by umjames on 8/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "HTTPBlockURLRequest.h"

NSString* const HTTPBlockURLErrorDomain = @"HTTPBlockURLErrorDomain";
NSString* const HTTPBlockURLResponseDataKey = @"HTTPBlockURLResponseDataKey";

@interface HTTPBlockURLRequest ()

@property (nonatomic, readwrite, retain) NSHTTPURLResponse*	HTTPResponse;

@end

@implementation HTTPBlockURLRequest

@synthesize HTTPResponse;

- (void)dealloc
{
	[HTTPResponse release];
	HTTPResponse = nil;
	
	[super dealloc];
}

- (void)connection: (NSURLConnection*)connection didReceiveResponse: (NSURLResponse*)response
{    
    [super connection: connection didReceiveResponse: response];
    
	if ([response isKindOfClass: [NSHTTPURLResponse class]])
	{
		self.HTTPResponse = (NSHTTPURLResponse*)response;
	}
}

- (void)connectionDidFinishLoading: (NSURLConnection*)connection
{    
    if ([self responseWasSuccessful])
	{
		[super connectionDidFinishLoading: connection];
	}
	else
	{
		NSData*		responseData = (self.responseData) ? self.responseData : [NSData data];
		NSError*	HTTPError = [NSError errorWithDomain: HTTPBlockURLErrorDomain 
												 code: [self.HTTPResponse statusCode] 
											 userInfo: [NSDictionary dictionaryWithObject: responseData forKey: HTTPBlockURLResponseDataKey]];
		
		[self connection: connection didFailWithError: HTTPError];
	}
}

- (BOOL)responseWasSuccessful
{
	if (nil == self.HTTPResponse)
	{
		return NO;
	}
	
	return ([self.HTTPResponse statusCode] < 400);
}

@end
