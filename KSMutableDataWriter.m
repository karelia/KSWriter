//
//  KSMutableDataWriter.m
//  Sandvox
//
//  Created by Mike Abdullah on 12/03/2011.
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
    CFRange range = CFRangeMake(0, CFStringGetLength((CFStringRef)string));
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

- (void)close;
{
    [_data release];
}

@end
