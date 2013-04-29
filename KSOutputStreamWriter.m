//
//  KSOutputStreamWriter.m
//  Sandvox
//
//  Created by Mike on 10/03/2011.
//  Copyright 2011-2012 Karelia Software. All rights reserved.
//

#import "KSOutputStreamWriter.h"


@implementation KSOutputStreamWriter

- (id)initWithOutputStream:(NSOutputStream *)outputStream
                  encoding:(NSStringEncoding)encoding
         precomposeStrings:(BOOL)precompose;
{
    if (self = [self init])
    {
        _outputStream = [outputStream retain];
        _encoding = encoding;
        _precompose = precompose;
    }
    
    return self;
}

- (void)dealloc;
{
    [self close];   // release stream
    [super dealloc];
}

@synthesize encoding = _encoding;

- (void)writePreprocessedString:(NSString *)string;
{
    CFStringEncoding encoding = CFStringConvertNSStringEncodingToEncoding([self encoding]);
    
#define BUFFER_LENGTH 1024
    UInt8 buffer[BUFFER_LENGTH];
    
    CFRange range = CFRangeMake(0, CFStringGetLength((CFStringRef)string));
    
    while (range.length)
    {
        CFIndex length;
        CFIndex chars = CFStringGetBytes((CFStringRef)string,
                                         range,
                                         encoding,
                                         0,
                                         !_started, // only want a BOM or similar for the very first write
                                         buffer,
                                         BUFFER_LENGTH,
                                         &length);
        
        _started = YES;
        
        NSInteger written = [_outputStream write:buffer maxLength:length];
        
        while (written < length)
        {
            if (written > 0)
            {
                length -= written;
                written = [_outputStream write:&buffer[written] maxLength:length];
            }
        }
        
        // For characters outside the supported range, do a poor impression of -[NSString dataUsingEncoding:lossy:] and skip them
        if (chars == 0) chars = 1;
        
        range = CFRangeMake(range.location + chars, range.length - chars);
    }
}

- (void)writeString:(NSString *)string;
{
	return [self writeString:string range:NSMakeRange(0, string.length)];
}

- (void)writeString:(NSString *)string range:(NSRange)nsrange;
{
    if (!_outputStream) return;
    
    // Precompose if requested
    if (_precompose)
    {
        NSMutableString *precomposed = [[string substringWithRange:nsrange] mutableCopy];
        CFStringNormalize((CFMutableStringRef)precomposed, kCFStringNormalizationFormC);
        [self writePreprocessedString:precomposed];
        [precomposed release];
    }
    else
    {
        [self writePreprocessedString:[string substringWithRange:nsrange]];
    }
}

- (void)appendString:(NSString *)aString; { [self writeString:aString]; }

- (void)close;
{
    [_outputStream release]; _outputStream = nil;
}

@end
