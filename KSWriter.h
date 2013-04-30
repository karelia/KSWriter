//
//  KSWriter.h
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


#import <Foundation/Foundation.h>


@protocol KSStringAppending <NSObject>
- (void)appendString:(NSString *)aString;
@end


#pragma mark -


@interface KSWriter : NSObject <KSStringAppending>

#pragma mark Building up Strings

- (id)init;	// strings are buffered in-memory, to be retrieved by -string

// This can be one of the least efficient types of writer since it might have to create lots of temporary substrings for appending to the mutable string
// Reports encoding of UTF-16
+ (instancetype)writerWithMutableString:(NSMutableString *)string __attribute((nonnull(1)));


#pragma mark Encoding as Data

+ (instancetype)writerWithMutableData:(NSMutableData *)data encoding:(NSStringEncoding)encoding;

// if precompose == YES, then Unicode Normalization Form C is applied to the output. This is handy for distributing to platforms which don't have as good unicode support as Apple's. More details at http://developer.apple.com/library/mac/#qa/qa1235/_index.html#//apple_ref/doc/uid/DTS10001757
+ (instancetype)writerWithOutputStream:(NSOutputStream *)outputStream
							  encoding:(NSStringEncoding)encoding
					 precomposeStrings:(BOOL)precompose;


#pragma mark Forwarding Onto Another Writer
// If the output writer has an encoding, the returned writer matches it
+ (instancetype)writerWithOutputWriter:(KSWriter *)output __attribute((nonnull(1)));
- (id)initWithOutputWriter:(KSWriter *)output __attribute((nonnull(1)));


#pragma mark Custom Writing
// The block is called for each string to be written
// If the block isn't explicitly encoding data and you've nothing better to choose, go for NSUTF16StringEncoding
+ (instancetype)writerWithEncoding:(NSStringEncoding)encoding block:(void (^)(NSString *string, NSRange range))block __attribute((nonnull(2)));

// Designated initializer
// If called directly, receiver buffers internally (retrieve using -string), which the encoding may be used as a hint for
- (id)initWithEncoding:(NSStringEncoding)encoding;


#pragma mark Writing
- (void)writeString:(NSString *)string range:(NSRange)range;	// primitive
- (void)writeString:(NSString *)string;							// convenience


#pragma mark Properties
@property(nonatomic, readonly) NSStringEncoding encoding;	// defaults to UTF-16 for non-data-based writers


#pragma mark Output

// If the receiver was configured to pipe through to some output, returns nil
// Otherwise, a string comprised of all the non-buffered strings written so far
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


#pragma mark -


@interface NSMutableString (KSWriter) <KSStringAppending>
@end
