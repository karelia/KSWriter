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

/**
 Strings are buffered in-memory, to be retrieved from .string
 
 @param encoding The format of the internal buffer, so you might be able to pick a format that suits
 your input strings particularly well.
 */
+ (KSWriter *)stringWriterWithEncoding:(NSStringEncoding)encoding;

/**
 Convenience for appending to an existing mutable string.
 
 This can be one of the least efficient types of writer, since it might have to create lots of
 temporary substrings for appending to the mutable string. A lot of the time, you'll probably find
 +stringWriterWithEncoding: is simply more convenient.
 */
+ (KSWriter *)writerWithMutableString:(NSMutableString *)string encoding:(NSStringEncoding)encoding __attribute((nonnull(1)));


#pragma mark Encoding as Data

/**
 Encodes the strings and appends them to `data` buffer.
 
 @param encoding The encoding to use for the data buffer.
 
 @param precompose If YES, then Unicode Normalization Form C is applied to the output. This is handy
 for distributing to platforms which don't have as good unicode support as Apple's. More details at
 http://developer.apple.com/library/mac/#qa/qa1235/_index.html#//apple_ref/doc/uid/DTS10001757
 */
+ (KSWriter *)writerWithMutableData:(NSMutableData *)data encoding:(NSStringEncoding)encoding precomposeStrings:(BOOL)precompose;

/**
 Encodes the strings and writes to `outputStream`.
 
 @param encoding The encoding to use.
 
 @param precompose If YES, then Unicode Normalization Form C is applied to the output. This is handy
 for distributing to platforms which don't have as good unicode support as Apple's. More details at
 http://developer.apple.com/library/mac/#qa/qa1235/_index.html#//apple_ref/doc/uid/DTS10001757
 */
+ (KSWriter *)writerWithOutputStream:(NSOutputStream *)outputStream
                            encoding:(NSStringEncoding)encoding
                   precomposeStrings:(BOOL)precompose;


#pragma mark Forwarding Onto Another Writer

/**
 Creates a write whose job is purely to forward on input strings to another writer.
 
 The new writer's `.encoding` matches that of the target writer.
 */
+ (KSWriter *)writerWithOutputWriter:(KSWriter *)output __attribute((nonnull(1)));


#pragma mark Custom Writing

/**
 Create your own custom writer. For each input string to be written, your block is executed.
 
 @param encoding If your block isn't explicitly encoding data and you've nothing better to choose,
 go for NSUTF16StringEncoding
 */
+ (KSWriter *)writerWithEncoding:(NSStringEncoding)encoding block:(void (^)(NSString *string, NSRange range))block __attribute((nonnull(2)));

/**
 Designated initializer for custom subclasses to use.
 */
- (instancetype)initWithEncoding:(NSStringEncoding)encoding NS_DESIGNATED_INITIALIZER;


#pragma mark Writing

/**
 The primitive writing API. If you need to write only a subrange of a string, calling here is often
 much more efficient than creating substrings yourself.
 
 @param string The source string to be written.
 @param range The portion of `string` to be written.
 */
- (void)writeString:(NSString *)string range:(NSRange)range;

/**
 Of course, having to construct the correct range to use above gets tedious pretty quickly. Use this
 API for convenience when writing whole strings.
 */
- (void)writeString:(NSString *)string;


#pragma mark Properties

/**
 The encoding the receiver uses. Depending on what the writer was created for, this may be the
 output, or merely provide a hint for internal buffering.
 
 Defaults to UTF-16 for non-data-based writers.
 */
@property(nonatomic, readonly) NSStringEncoding encoding;


#pragma mark Output

/**
 For writers created using `+stringWriterWithEncoding:`, all the non-buffered output written so far.
 `nil` for other writer types.
 */
@property (nonatomic, readonly, copy) NSString *string;


#pragma mark Buffering

- (void)removeAllCharacters;    // reset, but cunningly keeps memory allocated for speed
- (void)discardString;          // leaves only buffered content

- (void)beginBuffer; // can be called multiple times to set up a stack of buffers.
- (void)discardBuffer;  // discards the last buffer
@property (nonatomic, readonly) NSUInteger numberOfBuffers;

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
