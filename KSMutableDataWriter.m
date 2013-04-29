//
//  KSMutableDataWriter.m
//  Sandvox
//
//  Created by Mike on 12/03/2011.
//  Copyright 2011-2012 Karelia Software. All rights reserved.
//

#import "KSMutableDataWriter.h"


@implementation KSMutableDataWriter

- (id)initWithMutableData:(NSMutableData *)data encoding:(NSStringEncoding)encoding;
{
    if (self = [self init])
    {
        _data = [data retain];
        _encoding = encoding;
    }
    
    return self;
}

@synthesize encoding = _encoding;

- (void)writeString:(NSString *)string;
{
	return [self writeString:string range:NSMakeRange(0, string.length)];
}

- (void)writeString:(NSString *)string range:(NSRange)nsrange;
{
    CFRange range = CFRangeMake(nsrange.location, nsrange.length);
    CFStringEncoding encoding = CFStringConvertNSStringEncodingToEncoding([self encoding]);
    
    CFIndex usedBufLen;
    CFIndex chars = CFStringGetBytes((CFStringRef)string,
                                     range,
                                     encoding,
                                     0,
                                     false,
                                     NULL,
                                     0,
                                     &usedBufLen);
    NSAssert(chars == [string length], @"Unexpected number of characters converted");
    
    [_data increaseLengthBy:usedBufLen];
    UInt8 *buffer = [_data mutableBytes];
    
    chars = CFStringGetBytes((CFStringRef)string,
                             range,
                             encoding,
                             0,
                             false,
                             buffer + [_data length] - usedBufLen,
                             usedBufLen,
                             NULL);
    NSAssert(chars == [string length], @"Unexpected number of characters converted");
}

- (void)appendString:(NSString *)aString; { return [self writeString:aString]; }

- (void)close;
{
    [_data release];
}

@end
