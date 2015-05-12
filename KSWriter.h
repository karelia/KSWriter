//
//  KSWriter.h
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

#import <Foundation/Foundation.h>


//! Project version number for KSWriter.
FOUNDATION_EXPORT double KSWriterVersionNumber;

//! Project version string for KSWriter.
FOUNDATION_EXPORT const unsigned char KSWriterVersionString[];


@interface KSWriter : NSObject

#pragma mark Building up Strings

// Strings are buffered in-memory, to be retrieved by -string
// Encoding provides a hint for efficiency of buffering
+ (KSWriter *)stringWriterWithEncoding:(NSStringEncoding)encoding;

// This can be one of the least efficient types of writer since it might have to create lots of temporary substrings for appending to the mutable string
+ (KSWriter *)writerWithMutableString:(NSMutableString *)string encoding:(NSStringEncoding)encoding __attribute((nonnull(1)));


#pragma mark Encoding as Data

// if precompose == YES, then Unicode Normalization Form C is applied to the output. This is handy for distributing to platforms which don't have as good unicode support as Apple's. More details at http://developer.apple.com/library/mac/#qa/qa1235/_index.html#//apple_ref/doc/uid/DTS10001757

+ (KSWriter *)writerWithMutableData:(NSMutableData *)data encoding:(NSStringEncoding)encoding precomposeStrings:(BOOL)precompose;

+ (KSWriter *)writerWithOutputStream:(NSOutputStream *)outputStream
                            encoding:(NSStringEncoding)encoding
                   precomposeStrings:(BOOL)precompose;


#pragma mark Forwarding Onto Another Writer
// Encoding is taken from the target writer
+ (KSWriter *)writerWithOutputWriter:(KSWriter *)output __attribute((nonnull(1)));


#pragma mark Custom Writing

// The block is called for each string to be written
// If the block isn't explicitly encoding data and you've nothing better to choose, go for NSUTF16StringEncoding
+ (KSWriter *)writerWithEncoding:(NSStringEncoding)encoding block:(void (^)(NSString *string, NSRange range))block __attribute((nonnull(2)));

// Designated initializer, generally only useful for custom subclasses
// Encoding may be used as a hint for buffering
- (id)initWithEncoding:(NSStringEncoding)encoding;


#pragma mark Writing
- (void)writeString:(NSString *)string range:(NSRange)range;	// primitive
- (void)writeString:(NSString *)string;							// convenience


#pragma mark Properties
@property(nonatomic, readonly) NSStringEncoding encoding;	// defaults to UTF-16 for non-data-based writers


#pragma mark Output

// A string comprised of all the non-buffered strings written so far
// nil if the receiver wasn't created using `+stringWriterWithEncoding:`
- (NSString *)string;


#pragma mark Buffering

- (void)removeAllCharacters;    // reset, but cunningly keeps memory allocated for speed
- (void)discardString;          // leaves only buffered content

- (void)beginBuffer; // can be called multiple times to set up a stack of buffers.
- (void)discardBuffer;  // discards the last buffer
- (NSUInteger)numberOfBuffers;

- (void)flush;          // flushes all buffers
- (void)flushFirstBuffer;   // flushes only the first buffer, leaving any others intact

- (void)writeString:(NSString *)string toBufferAtIndex:(NSUInteger)index;   // 0 bypasses all buffers


#pragma mark Flush-on-write
- (void)flushOnNextWrite;   // calls -flush at next write. Can still use -discardBuffer to effectively cancel this
- (void)cancelFlushOnNextWrite;


#pragma mark Lifecycle
- (void)close;  // clears any buffers and stops writing to output


@end


extern NSString *KSWriterWillFlushNotification;
