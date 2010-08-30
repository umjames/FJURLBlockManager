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

@interface HTTPBlockURLRequest : FJBlockURLRequest
{
}

@property (nonatomic, readonly, retain) NSHTTPURLResponse*	HTTPResponse;

- (BOOL)responseWasSuccessful;

@end
