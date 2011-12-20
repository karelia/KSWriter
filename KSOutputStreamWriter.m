//
//  KSOutputStreamWriter.m
//  Sandvox
//
//  Created by Mike on 10/03/2011.
//  Copyright 2011 Karelia Software. All rights reserved.
//

#import "KSOutputStreamWriter.h"


@implementation KSOutputStreamWriter

- (id)initWithOutputStream:(NSOutputStream *)outputStream
                  encoding:(NSStringEncoding)encoding
         precomposeStrings:(BOOL)precompose;
{
    [self init];
    
    _outputStream = [outputStream retain];
    _encoding = encoding;
    _precompose = precompose;
    
    return self;
}

- (id)initWithOutputStream:(NSOutputStream *)outputStream;  // uses UTF8 encoding
{
    return [self initWithOutputStream:outputStream encoding:NSUTF8StringEncoding precomposeStrings:NO];
}

- (void)dealloc;
{
    [self close];   // release stream
    [super dealloc];
}

@synthesize encoding = _encoding;

- (void)writePreprocessedString:(NSString *)string;
{
#define BUFFER_LENGTH 1024
    UInt8 buffer[BUFFER_LENGTH];
    
    CFRange range = CFRangeMake(0, CFStringGetLength((CFStringRef)string));
    
    while (range.length)
    {
        CFIndex length;
        CFIndex chars = CFStringGetBytes((CFStringRef)string,
                                         range,
                                         CFStringConvertNSStringEncodingToEncoding([self encoding]),
                                         0,
                                         YES,
                                         buffer,
                                         BUFFER_LENGTH,
                                         &length);
        
        
        NSInteger written = [_outputStream write:buffer maxLength:length];
        
        while (written < length)
        {
            if (written > 0)
            {
                length -= written;
                written = [_outputStream write:&buffer[written] maxLength:length];
            }
        }
        
        range = CFRangeMake(range.location + chars, range.length - chars);
    }
}

- (void)writeString:(NSString *)string;
{
    // Precompose if requested
    if (_precompose)
    {
        NSMutableString *precomposed = [string mutableCopy];
        CFStringNormalize((CFMutableStringRef)precomposed, kCFStringNormalizationFormC);
        [self writePreprocessedString:precomposed];
        [precomposed release];
    }
    else
    {
        [self writePreprocessedString:string];
    }
}

- (void)close;
{
    [_outputStream release]; _outputStream = nil;
}

@end
