//
//  KSWriter.m
//
//  Copyright 2010-2012, Mike Abdullah and Karelia Software
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL MIKE ABDULLAH OR KARELIA SOFTWARE BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//


#import "KSWriter.h"


@implementation KSWriter
{
    void    (^_block)(NSString *, NSRange);
}

#pragma mark Encoding as Data

+ (instancetype)writerWithMutableData:(NSMutableData *)data encoding:(NSStringEncoding)nsencoding;
{
	CFStringEncoding encoding = CFStringConvertNSStringEncodingToEncoding(nsencoding);

    return [self writerWithEncoding:nsencoding block:^(NSString *string, NSRange nsrange) {
		
		CFRange range = CFRangeMake(nsrange.location, nsrange.length);
		
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
		
		[data increaseLengthBy:usedBufLen];
		UInt8 *buffer = [data mutableBytes];
		
		chars = CFStringGetBytes((CFStringRef)string,
								 range,
								 encoding,
								 0,
								 false,
								 buffer + [data length] - usedBufLen,
								 usedBufLen,
								 NULL);
		NSAssert(chars == [string length], @"Unexpected number of characters converted");
	}];
}

+ (instancetype)writerWithOutputStream:(NSOutputStream *)outputStream
							  encoding:(NSStringEncoding)nsencoding
					 precomposeStrings:(BOOL)precompose;
{
	CFStringEncoding encoding = CFStringConvertNSStringEncodingToEncoding(nsencoding);
	__block BOOL started = NO;

	void (^primitiveBlock)(NSString*, CFRange) = ^(NSString *string, CFRange range) {
		
#define BUFFER_LENGTH 1024
		UInt8 buffer[BUFFER_LENGTH];
		
		while (range.length)
		{
			CFIndex length;
			CFIndex chars = CFStringGetBytes((CFStringRef)string,
											 range,
											 encoding,
											 0,
											 !started, // only want a BOM or similar for the very first write
											 buffer,
											 BUFFER_LENGTH,
											 &length);
			
			started = YES;
			
			NSInteger written = [outputStream write:buffer maxLength:length];
			
			while (written < length)
			{
				if (written > 0)
				{
					length -= written;
					written = [outputStream write:&buffer[written] maxLength:length];
				}
			}
			
			// For characters outside the supported range, do a poor impression of -[NSString dataUsingEncoding:lossy:] and skip them
			if (chars == 0) chars = 1;
			
			range = CFRangeMake(range.location + chars, range.length - chars);
		}
	};
	
	
    return [self writerWithEncoding:nsencoding block:^(NSString *string, NSRange range) {
		
		// Precompose if requested
		if (precompose)
		{
			NSMutableString *precomposed = [[string substringWithRange:range] mutableCopy];
			CFStringNormalize((CFMutableStringRef)precomposed, kCFStringNormalizationFormC);
			primitiveBlock(precomposed, CFRangeMake(0, precomposed.length));
			[precomposed release];
		}
		else
		{
			primitiveBlock(string, CFRangeMake(range.location, range.length));
		}
	}];
}

#pragma mark Forwarding Onto Another Writer

+ (instancetype)writerWithOutputWriter:(id <KSWriter>)output;
{
    return [self writerWithEncoding:NSUTF16StringEncoding block:^(NSString *string, NSRange range) {
		[output writeString:string range:range];
	}];
}

#pragma mark Custom Writing

+ (instancetype)writerWithEncoding:(NSStringEncoding)encoding block:(void (^)(NSString *string, NSRange range))block;
{
	return [[[self alloc] initWithEncoding:encoding block:block] autorelease];
}

- (id)initWithEncoding:(NSStringEncoding)encoding block:(void (^)(NSString *string, NSRange range))block;
{
    NSParameterAssert(block);
    
    if (self = [super init])
    {
        _block = [block copy];
		_encoding = encoding;
    }
    return self;
}

#pragma mark Lifecycle

- (id)init;
{
	// Create empty block rather than have -writeString:… keep checking if it's nil
    return [self initWithEncoding:NSUTF16StringEncoding block:^(NSString *string, NSRange range) { }];
}

- (void)close;
{
    [_block release]; _block = nil;
}

- (void)dealloc
{
    [self close];
    NSAssert(!_block, @"-close failed to dispose of writer block");
    
    [super dealloc];
}

#pragma mark Writing

- (void)writeString:(NSString *)string;
{
	return [self writeString:string range:NSMakeRange(0, string.length)];
}

- (void)writeString:(NSString *)string range:(NSRange)range;
{
    _block(string, range);
}

- (void)appendString:(NSString *)aString; { [self writeString:aString]; }

#pragma mark Properties

@synthesize encoding = _encoding;

@end


#pragma mark -


@implementation NSMutableString (KSWriter)

@end
