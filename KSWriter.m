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
//  IMPORTANT: Can't use -[NSString initWithBytes:…] internally, since it seems
//  to behave differently between encoding and decoding using
//  NSUnicodeStringEncoding. Rough guess is that routine is setup to assume the
//  string is an external rep. CFString makes this explicit to solve the problem


#import "KSWriter.h"


@implementation KSWriter
{
    void    (^_block)(NSString *, NSRange);
    NSMutableData   *_buffer;
    NSPointerArray  *_bufferPoints; // stored in reverse order for efficiency
    BOOL            _flushOnNextWrite;
}

#pragma mark Building up Strings

- (id)init;
{
	return [self initWithEncoding:NSUnicodeStringEncoding];
}

+ (KSWriter *)writerWithMutableString:(NSMutableString *)output encoding:(NSStringEncoding)encoding;
{
	return [self writerWithEncoding:encoding block:^(NSString *string, NSRange range) {

		[output appendString:[string substringWithRange:range]];
	}];
}

+ (KSWriter *)stringWriterWithEncoding:(NSStringEncoding)encoding;
{
    return [[[KSWriter alloc] initWithEncoding:encoding] autorelease];
}

#pragma mark Encoding as Data

+ (KSWriter *)writerWithMutableData:(NSMutableData *)data encoding:(NSStringEncoding)nsencoding;
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
            CFMutableStringRef mutable = CFStringCreateMutableCopy(NULL, 0, (CFStringRef)string);
            
            // Delete anything outside the desired range
            if (range.location > 0) CFStringDelete(mutable, CFRangeMake(0, range.location));
            
            CFIndex remainingLength = CFStringGetLength(mutable);
            if (range.length < remainingLength) CFStringDelete(mutable, CFRangeMake(range.length, remainingLength - range.length));
            
            // Normalize
			CFStringNormalize((CFMutableStringRef)mutable, kCFStringNormalizationFormC);
			primitiveBlock((NSString *)mutable, CFRangeMake(0, CFStringGetLength(mutable)));
			
            // Clean up
            CFRelease(mutable);
		}
		else
		{
			primitiveBlock(string, CFRangeMake(range.location, range.length));
		}
	}];
}

#pragma mark Forwarding Onto Another Writer

+ (instancetype)writerWithOutputWriter:(KSWriter *)output;
{
	return [[[self alloc] initWithOutputWriter:output] autorelease];
}

- (id)initWithOutputWriter:(KSWriter *)output;
{
    NSParameterAssert(output);
    
    return [self initWithEncoding:output.encoding block:^(NSString *string, NSRange range) {
        [output writeString:string range:range];
    }];
}

#pragma mark Custom Writing

+ (instancetype)writerWithEncoding:(NSStringEncoding)encoding block:(void (^)(NSString *string, NSRange range))block;
{
	NSParameterAssert(block);
    return [[[self alloc] initWithEncoding:encoding block:block] autorelease];
}

- (id)initWithEncoding:(NSStringEncoding)encoding;
{
	if (self = [super init])
    {
		_encoding = encoding;
    }
    return self;
}

- (id)initWithEncoding:(NSStringEncoding)encoding block:(void (^)(NSString *string, NSRange range))block;
{
    if (self = [self initWithEncoding:encoding])
    {
        _block = [block copy];
    }
    return self;
}

#pragma mark Lifecycle

- (void)close;
{
    [_block release]; _block = nil;
	
	// Prune the buffer back down to size
    [_buffer setLength:self.length];
}

- (void)dealloc
{
    [self close];
    NSAssert(!_block, @"-close failed to dispose of writer block");
    
    [_buffer release]; _buffer = nil;
    [_bufferPoints release]; _bufferPoints = nil;
    
    [super dealloc];
}

#pragma mark Writing

- (void)writeString:(NSString *)string;
{
	return [self writeString:string range:NSMakeRange(0, string.length)];
}

- (void)writeString:(NSString *)string range:(NSRange)nsrange;
{
    // Flush if needed
    NSUInteger length = nsrange.length;
    if (_flushOnNextWrite && length)
    {
        [self flush];
    }
    
	
	// Write through to output, or append to buffer
    if (!_block || self.numberOfBuffers)
	{
        [self setupBufferingIfNeeded];
        NSUInteger insertionPoint = [self insertionPoint];
		
        while (nsrange.length)
        {
            NSUInteger unusedCapacity = _buffer.length - insertionPoint;
            
            // Copy what we can into the buffer
            NSUInteger usedLength = 0;
            
            if (unusedCapacity) // otherwise bytes argument might evaluate to NULL leading NSString astray
            {
                [string getBytes:[_buffer mutableBytes] + insertionPoint
                       maxLength:unusedCapacity
                      usedLength:&usedLength
                        encoding:self.encoding
                         options:NSStringEncodingConversionAllowLossy
                           range:nsrange
                  remainingRange:&nsrange];
            }
            
            // Increase the buffer size if needed
            if (usedLength == 0)
            {
                [_buffer increaseLengthBy:CFStringGetMaximumSizeForEncoding(nsrange.length,
                                                                            CFStringConvertNSStringEncodingToEncoding(self.encoding))];
            }
            else
            {
                insertionPoint += usedLength;
            }
        }
        
        [_bufferPoints replacePointerAtIndex:0 withPointer:(void *)insertionPoint];
	}
	else
	{
		_block(string, nsrange);
	}
}

- (void)writeString:(NSString *)string toBufferAtIndex:(NSUInteger)index;   // 0 bypasses all buffers
{
    if (index == 0 && _block)
    {
        _block(string, NSMakeRange(0, string.length));
        return;
    }
    
    NSUInteger invertedIndex = [_bufferPoints count] - index;
    if (!_block) --invertedIndex;
    NSUInteger insertionPoint = (NSUInteger)[_bufferPoints pointerAtIndex:invertedIndex];
    NSParameterAssert(insertionPoint <= [self insertionPoint]);
    
    NSMutableData *data = [[NSMutableData alloc] initWithLength:[string maximumLengthOfBytesUsingEncoding:self.encoding]];
    
    NSUInteger length;
    [string getBytes:[data mutableBytes]
           maxLength:[data length]
          usedLength:&length
            encoding:self.encoding
             options:NSStringEncodingConversionAllowLossy
               range:NSMakeRange(0, string.length)
      remainingRange:NULL];
    
    [_buffer replaceBytesInRange:NSMakeRange(insertionPoint, 0)
                       withBytes:[data bytes]
                          length:length];
    
    [data release];
    
    NSUInteger i, count = invertedIndex + 1;
    for (i = 0; i < count; i++)
    {
        NSUInteger ind = (NSUInteger)[_bufferPoints pointerAtIndex:i];
        ind += length;
        [_bufferPoints replacePointerAtIndex:i withPointer:(void *)ind];
    }
}

- (void)writeString:(NSString *)string bypassBuffer:(BOOL)bypassBuffer;
{
    if (bypassBuffer)
    {
        [self writeString:string toBufferAtIndex:0];
    }
    else
    {
        [self writeString:string];
    }
}

#pragma mark Properties

@synthesize encoding = _encoding;

#pragma mark NSString Primitives
// Not really used on the whole, but theoretically this class could be an NSString subclass

- (NSUInteger)length;
{
	if (!_bufferPoints.count) return 0;
    return (NSUInteger)[_bufferPoints pointerAtIndex:([_bufferPoints count] - 1)];
}

#pragma mark Output

- (NSString *)string;
{
    CFStringRef result = CFStringCreateWithBytes(NULL, [_buffer bytes], self.length, CFStringConvertNSStringEncodingToEncoding(self.encoding), NO);
    return [(NSString *)result autorelease];
}

#pragma mark Buffering

- (NSUInteger)insertionPoint;
{
	if (!_bufferPoints.count) return 0;
	return (NSUInteger)[_bufferPoints pointerAtIndex:0];
}

#ifdef DEBUG
- (NSArray *)bufferPoints;
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[_bufferPoints count]];
    
    NSUInteger i, count = [_bufferPoints count];
    for (i = 0; i < count; i++)
    {
        NSUInteger anIndex = (NSUInteger)[_bufferPoints pointerAtIndex:i];
        [result addObject:[NSNumber numberWithUnsignedInteger:anIndex]];
    }
    
    return result;
}
#endif

- (void)removeAllCharacters;
{
    [_bufferPoints release]; _bufferPoints = [[NSPointerArray alloc]
                                              initWithOptions:NSPointerFunctionsIntegerPersonality | NSPointerFunctionsOpaqueMemory];
    [_bufferPoints addPointer:0];
}

- (void)discardString;          // leaves only buffered content
{
    NSUInteger length = [self length];
    [_buffer replaceBytesInRange:NSMakeRange(0, length) withBytes:NULL length:0];
    
    NSUInteger i, count = [_bufferPoints count];
    for (i = 0; i < count; i++)
    {
        [_bufferPoints replacePointerAtIndex:i
                                 withPointer:(void *)((NSUInteger)[_bufferPoints pointerAtIndex:i] - length)];
    }
}

// Can be called multiple times to set up a stack of buffers.
- (void)beginBuffer;
{
    [self setupBufferingIfNeeded];
    [self cancelFlushOnNextWrite];
    [_bufferPoints insertPointer:(void *)[self insertionPoint] atIndex:0];
}

- (NSUInteger)numberOfBuffers;
{
    NSUInteger result = _bufferPoints.count;
	if (!_block) --result;	// the first "buffer" is actually the output
	return result;
}

- (void)flushFirstBuffer;
{
	NSUInteger indexOfBuffer = [_bufferPoints count] - 1;
	
    if (_block)
	{
		// Write contents of first buffer directly to output
		NSUInteger bufferLength = (NSUInteger)[_bufferPoints pointerAtIndex:indexOfBuffer];
        
        CFStringRef string = CFStringCreateWithBytes(NULL,
                                                     [_buffer bytes], bufferLength,
                                                     CFStringConvertNSStringEncodingToEncoding(self.encoding), NO);
        
		_block((NSString *)string, NSMakeRange(0, CFStringGetLength(string)));
        CFRelease(string);
		
		// Shift the index of remaining buffers
		NSUInteger i;
		for (i = 0; i < indexOfBuffer; i++)
		{
			NSUInteger ind = (NSUInteger)[_bufferPoints pointerAtIndex:i];
			ind -= bufferLength;
			[_bufferPoints replacePointerAtIndex:i withPointer:(void *)ind];
		}
		
		// Throw away the buffer
		[_buffer replaceBytesInRange:NSMakeRange(0, bufferLength) withBytes:NULL length:0];
	}

	// Remove buffer point
	// If the buffer *is* the output, that's enough, job done!
	[_bufferPoints removePointerAtIndex:indexOfBuffer];
}

// Discards the most recent buffer. If there's a lower one in the stack, that is restored
- (void)discardBuffer;
{
    NSParameterAssert([_bufferPoints count] > (_block ? 0 : 1));
    [_bufferPoints removePointerAtIndex:0];
}

- (void)flush;
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:KSWriterWillFlushNotification
     object:self];
    
    if (_block)
	{
		// Ditch the buffer points and write what was buffered through to the output
		NSUInteger length = self.insertionPoint;
		[_bufferPoints setCount:0];
        
		CFStringRef string = CFStringCreateWithBytes(NULL,
                                                     [_buffer bytes], length,
                                                     CFStringConvertNSStringEncodingToEncoding(self.encoding), NO);
        
		[self writeString:(NSString *)string range:NSMakeRange(0, CFStringGetLength(string))];
        CFRelease(string);
	}
	else
	{
        NSUInteger count = _bufferPoints.count;
        if (count)
        {
            // Ditch all buffer points except the one currently marking -insertionPoint
            for (NSUInteger i = count-1; i > 0; i--)
            {
                [_bufferPoints removePointerAtIndex:i];
            }
            NSAssert(_bufferPoints.count == 1, @"Somehow disposed of all buffers");
        }
	}
	
    _flushOnNextWrite = NO;
}

- (void)setupBufferingIfNeeded;
{
    if (!_buffer && !_bufferPoints)
    {
        _buffer = [[NSMutableData alloc] init];
        _bufferPoints = [[NSPointerArray alloc] initWithOptions:NSPointerFunctionsIntegerPersonality | NSPointerFunctionsOpaqueMemory];
        if (!_block) [self beginBuffer];
    }
}

#pragma mark Flush-on-write

- (void)flushOnNextWrite; { _flushOnNextWrite = YES; }

- (void)cancelFlushOnNextWrite; { _flushOnNextWrite = NO; }

#pragma mark KSStringAppending

- (void)appendString:(NSString *)aString; { [self writeString:aString]; }

#pragma mark Debug

- (NSString *)debugDescription;
{
    NSString *result = [self description];
    
    CFStringRef buffer = CFStringCreateWithBytes(NULL,
                                                 [_buffer bytes], [self insertionPoint],
                                                 CFStringConvertNSStringEncodingToEncoding(self.encoding), NO);
    
    result = [result stringByAppendingFormat:@" %@", (NSString *)buffer];
    CFRelease(buffer);
    return result;
}

@end


NSString *KSWriterWillFlushNotification = @"KSWriterWillFlush";


#pragma mark -


@implementation NSMutableString (KSWriter)

@end
