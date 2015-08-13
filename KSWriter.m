//
//  KSWriter.m
//
//  Created by Mike Abdullah
//  Copyright © 2010 Karelia Software
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

- (instancetype)init;
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
    return [[KSWriter alloc] initWithEncoding:encoding];
}

#pragma mark Encoding as Data

+ (KSWriter *)writerWithMutableData:(NSMutableData *)data encoding:(NSStringEncoding)nsencoding precomposeStrings:(BOOL)precompose;
{
	CFStringEncoding encoding = CFStringConvertNSStringEncodingToEncoding(nsencoding);

    return [self writerWithEncoding:nsencoding precomposeStrings:precompose block:^(NSString *string, NSRange nsrange) {
		
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

	return [self writerWithEncoding:nsencoding precomposeStrings:(BOOL)precompose block:^(NSString *string, NSRange range) {
		
#define BUFFER_LENGTH 1024
		UInt8 buffer[BUFFER_LENGTH];
		
		while (range.length)
		{
			CFIndex length;
			CFIndex chars = CFStringGetBytes((CFStringRef)string,
											 CFRangeMake(range.location, range.length),
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
			
			range = NSMakeRange(range.location + chars, range.length - chars);
		}

	}];
}

+ (KSWriter *)writerWithEncoding:(NSStringEncoding)nsencoding precomposeStrings:(BOOL)precompose block:(void (^)(NSString *string, NSRange range))block;
{
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
			block((__bridge NSString *)mutable, NSMakeRange(0, CFStringGetLength(mutable)));
			
            // Clean up
            CFRelease(mutable);
		}
		else
		{
			block(string, range);
		}
    }];
}

#pragma mark Forwarding Onto Another Writer

+ (instancetype)writerWithOutputWriter:(KSWriter *)output;
{
	return [[self alloc] initWithOutputWriter:output];
}

- (instancetype)initWithOutputWriter:(KSWriter *)output;
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
    return [[self alloc] initWithEncoding:encoding block:block];
}

- (instancetype)initWithEncoding:(NSStringEncoding)encoding;
{
	if (self = [super init])
    {
		_encoding = encoding;
    }
    return self;
}

- (instancetype)initWithEncoding:(NSStringEncoding)encoding block:(void (^)(NSString *string, NSRange range))block;
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
    _block = NULL;
	
	// Prune the buffer back down to size
    [_buffer setLength:self.length];
}

- (void)dealloc
{
    [self close];
    
    _buffer = nil;
    _bufferPoints = nil;
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
    return (NSString *)CFBridgingRelease(result);
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
        [result addObject:@(anIndex)];
    }
    
    return result;
}
#endif

- (void)removeAllCharacters;
{
    _bufferPoints = [[NSPointerArray alloc]
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
        
		_block((__bridge NSString *)string, NSMakeRange(0, CFStringGetLength(string)));
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
        
		[self writeString:(__bridge NSString *)string range:NSMakeRange(0, CFStringGetLength(string))];
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
    if (!_buffer) {
        _buffer = [[NSMutableData alloc] init];
    }
    
    if (!_bufferPoints) {
        _bufferPoints = [[NSPointerArray alloc] initWithOptions:NSPointerFunctionsIntegerPersonality | NSPointerFunctionsOpaqueMemory];
        if (!_block) [self beginBuffer];
    }
}

#pragma mark Flush-on-write

- (void)flushOnNextWrite; { _flushOnNextWrite = YES; }

- (void)cancelFlushOnNextWrite; { _flushOnNextWrite = NO; }

#pragma mark Debug

- (NSString *)debugDescription;
{
    NSString *result = [self description];
    
    CFStringRef buffer = CFStringCreateWithBytes(NULL,
                                                 [_buffer bytes], [self insertionPoint],
                                                 CFStringConvertNSStringEncodingToEncoding(self.encoding), NO);
    
    result = [result stringByAppendingFormat:@"\n%@", (__bridge NSString *)buffer];
    CFRelease(buffer);
    return result;
}

@end


NSString *KSWriterWillFlushNotification = @"KSWriterWillFlush";
