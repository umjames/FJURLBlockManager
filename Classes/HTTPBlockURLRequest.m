//
//  HTTPBlockURLRequest.m
//  FJBlockURLManager
//
//  Created by umjames on 8/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "HTTPBlockURLRequest.h"
#import "NSString+extensions.h"

NSString* const HTTPBlockURLErrorDomain = @"HTTPBlockURLErrorDomain";
NSString* const HTTPBlockURLResponseDataKey = @"HTTPBlockURLResponseDataKey";
NSString* const HTTPBlockURLResponseAsStringKey = @"HTTPBlockURLResponseAsStringKey";

@interface HTTPBlockURLRequest ()

@property (nonatomic, readwrite, retain) NSHTTPURLResponse*	HTTPResponse;

- (NSString*)_convertData: (NSData*)data toStringUsingEncoding: (NSStringEncoding)encoding;
- (NSURL*)_URLWithoutQueryString: (NSURL*)url;
- (NSString*)_queryStringFromParameters;

@end

@implementation HTTPBlockURLRequest

@synthesize HTTPResponse;

- (NSString*)_convertData: (NSData*)data toStringUsingEncoding: (NSStringEncoding)encoding
{
	return [[[NSString alloc] initWithData: data encoding: encoding] autorelease];
}

- (NSURL*)_URLWithoutQueryString: (NSURL*)url
{
	if (nil == url)
	{
		return nil;
	}
	
	NSString*			query = [url query];
	
	if (nil == query)
	{
		return url;
	}
	
	NSMutableString*	result = [NSMutableString stringWithString: [url absoluteString]];
	NSRange				queryRange = [result rangeOfString: query];
	
	// include question mark in range of query string
	[result deleteCharactersInRange: NSMakeRange(queryRange.location - 1, queryRange.length + 1)];
	
	return [NSURL URLWithString: [NSString stringWithString: result]];
}

- (NSString*)_queryStringFromParameters
{
	NSMutableArray*	queryPairs = [NSMutableArray arrayWithCapacity: 3];
	
	[_parameters enumerateKeysAndObjectsUsingBlock: ^(id paramName, id paramValue, BOOL* stop) {
		if ([paramValue isKindOfClass: [NSArray class]])
		{
			[(NSArray*)paramValue enumerateObjectsUsingBlock: ^(id value, NSUInteger index, BOOL* stop2) {
				[queryPairs addObject: [NSString stringWithFormat: @"%@=%@", [(NSString*)paramName URLEncodedString], [(NSString*)value URLEncodedString]]];
			}];
		}
		else
		{
			[queryPairs addObject: [NSString stringWithFormat: @"%@=%@", [(NSString*)paramName URLEncodedString], [(NSString*)paramValue URLEncodedString]]];
		}
	}];
	
	return [queryPairs componentsJoinedByString: @"&"];
}

- (id)initWithURL: (NSURL*)theURL cachePolicy: (NSURLRequestCachePolicy)cachePolicy timeoutInterval: (NSTimeInterval)timeoutInterval
{
	self = [super initWithURL: theURL cachePolicy: cachePolicy timeoutInterval: timeoutInterval];
	
	if (self)
	{
		_parameters = [[NSMutableDictionary alloc] initWithCapacity: 5];
	}
	
	return self;
}

- (void)dealloc
{
	[HTTPResponse release];
	HTTPResponse = nil;
	
	[_parameters release];
	
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
											 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: responseData, HTTPBlockURLResponseDataKey, [self _convertData: responseData toStringUsingEncoding: NSUTF8StringEncoding], HTTPBlockURLResponseAsStringKey, nil]];
		
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

- (NSString*)responseBodyAsString: (NSData*)data
{
	if (!data)
	{
		return nil;
	}
	
	return [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
}

- (NSDictionary*)parameters
{
	return [NSDictionary dictionaryWithDictionary: _parameters];
}

- (void)clearParameters
{
	[_parameters removeAllObjects];
}

- (void)setValue: (NSString*)value forParameterName: (NSString*)name
{
	[_parameters setObject: value forKey: name];
}

- (void)addValue: (NSString*)value forParameterName: (NSString*)name
{
	id previousValue = [_parameters objectForKey: name];
	
	if (nil == previousValue)
	{
		[_parameters setObject: value forKey: name];
	}
	else if ([previousValue isKindOfClass: [NSMutableArray class]])
	{
		[(NSMutableArray*)previousValue addObject: value];
	}
	else
	{
		[_parameters setObject: [NSMutableArray arrayWithObjects: previousValue, value, nil] forKey: name];
	}
}

- (void)prepare
{
	NSString*	existingParameters = [[self URL] query];
	NSURL*		normalizedURL = nil;
	
	// Add existing parameters in the query string
	if (nil != existingParameters)
	{
		NSArray*	queryPairs = [existingParameters componentsSeparatedByString: @"&"];
		
		for (NSString* queryPair in queryPairs)
		{
			NSArray*	pairElements = [queryPair componentsSeparatedByString: @"="];
			
			[self addValue: [(NSString*)[pairElements objectAtIndex: 1] URLDecodedString] forParameterName: [(NSString*)[pairElements objectAtIndex: 0] URLDecodedString]];
		}
	}
	
	// check the HTTP method and put the parameters in the right place and the correct headers
	if ([@"GET" isEqual: [self HTTPMethod]] || [@"DELETE" isEqual: [self HTTPMethod]])
	{
		if (nil != existingParameters)
		{
			normalizedURL = [self _URLWithoutQueryString: [self URL]];
		}
		else
		{
			normalizedURL = [self URL];
		}
		
		if ([_parameters count] > 0)
		{
			[self setURL: [NSURL URLWithString: [NSString stringWithFormat: @"%@?%@", [normalizedURL absoluteString], [self _queryStringFromParameters]]]];
		}
	}
	else
	{
		if (nil != existingParameters)
		{
			normalizedURL = [self _URLWithoutQueryString: [self URL]];
			[self setURL: normalizedURL];
		}
		
		NSData*	httpBody = [[self _queryStringFromParameters] dataUsingEncoding: NSUTF8StringEncoding];
		
		
		[self setHTTPBody: httpBody];
		[self setValue: [NSString stringWithFormat: @"%u", [httpBody length]] forHTTPHeaderField: @"Content-Length"];
		
		// set the content-type header only if no other content-type header is specified
		if (nil == [self valueForHTTPHeaderField: @"Content-Type"])
		{
			[self setValue: @"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];
		}
	}
}

- (void)scheduleWithNetworkManager: (FJBlockURLManager*)networkManager
{
    [self prepare];
    
    [super scheduleWithNetworkManager: networkManager];
}

- (BOOL)isMultipart
{
	return [[self valueForHTTPHeaderField:@"Content-Type"] hasPrefix:@"multipart/form-data"];
}

@end

@implementation HTTPBlockURLRequest (Debug)

- (NSString*)debugDescription
{
	NSString*	httpBodyAsString = [[[NSString alloc] initWithData: [self HTTPBody] encoding: NSUTF8StringEncoding] autorelease];
	
	return [NSString stringWithFormat: @"HTTP method: %@\nURL: %@\nHeaders:\n%@\nBody:\n%@\n", [self HTTPMethod], [[self URL] absoluteString], [self allHTTPHeaderFields], httpBodyAsString];
}

@end
