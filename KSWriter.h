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


@protocol KSWriter <KSStringAppending>
- (void)writeString:(NSString *)string range:(NSRange)range;	// primitive
- (void)writeString:(NSString *)string;							// convenience
- (void)close;  // most writers will ignore, but others may use it to trigger an action
@end


@protocol KSBufferingWriter <KSWriter>
- (void)startBuffering; // can be called multiple times, implementor chooses how to handle that
- (void)flush;          // writes all buffered content
- (void)writeString:(NSString *)string bypassBuffer:(BOOL)bypassBuffer;
@end


@protocol KSMultiBufferingWriter <KSBufferingWriter>
- (void)startBuffering;     // each call is expected to start a new distinct buffer, while maintaining the old
- (void)flushFirstBuffer;   // thus you can stagger beginning and ending buffers
- (NSUInteger)numberOfBuffers;
- (void)writeString:(NSString *)string toBufferAtIndex:(NSUInteger)index;   // 0 bypasses all buffers
@end


#pragma mark -


@interface KSWriter : NSObject <KSWriter>

#pragma mark Creating a Writer

- (id)initWithOutputWriter:(id <KSWriter>)stream;

// The block is called for each string to be written
- (id)initWithBlock:(void (^)(NSString *string, NSRange range))block;


@end


#pragma mark -


@interface NSMutableString (KSWriter) <KSStringAppending>
@end