//
//  KSBlockWriter.m
//  Sandvox
//
//  Created by Mike on 27/12/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.
//

#import "KSBlockWriter.h"

@implementation KSBlockWriter

- (id)initWithBlock:(void (^)(NSString *string))block;
{
    NSParameterAssert(block);
    
    if (self = [self init])
    {
        _block = [block copy];
    }
    return self;
}

- (void)writeString:(NSString *)string;
{
	return [self writeString:string range:NSMakeRange(0, string.length)];
}

- (void)writeString:(NSString *)string range:(NSRange)nsrange;
{
    _block([string substringWithRange:nsrange]);
}

- (void)appendString:(NSString *)aString; { [self writeString:aString]; }

- (void)close;
{
    [_block release]; _block = nil;
}

- (void)dealloc;
{
    [self close];
    [super dealloc];
}

@end
