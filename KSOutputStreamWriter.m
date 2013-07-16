//
//  KSOutputStreamWriter.m
//  Sandvox
//
//  Created by Mike Abdullah on 10/03/2011.
//  Created by Mike Abdullah
//  Copyright © 2011 Karelia Software
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
    if (!_outputStream) return;
    
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
