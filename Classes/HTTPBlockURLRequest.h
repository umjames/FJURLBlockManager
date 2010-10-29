//
//  HTTPBlockURLRequest.h
//  FJBlockURLManager
//
//  Created by umjames on 8/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FJBlockURLRequest.h"

extern NSString* const HTTPBlockURLErrorDomain;

extern NSString* const HTTPBlockURLResponseDataKey;
extern NSString* const HTTPBlockURLResponseAsStringKey;

@interface HTTPBlockURLRequest : FJBlockURLRequest
{
	NSMutableDictionary*	_parameters;
}

@property (nonatomic, readonly, retain) NSHTTPURLResponse*	HTTPResponse;

- (BOOL)responseWasSuccessful;
- (NSString*)responseBodyAsString: (NSData*)data;

- (NSDictionary*)parameters;
- (void)clearParameters;

- (void)setValue: (NSString*)value forParameterName: (NSString*)name;
- (void)addValue: (NSString*)value forParameterName: (NSString*)name;

- (void)prepare;

- (BOOL)isMultipart;

@end

@interface HTTPBlockURLRequest (Debug)

- (NSString*)debugDescription;

@end
