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


@protocol KSWriter <NSObject>
- (void)writeString:(NSString *)string;
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


@interface NSMutableString (KSWriter) <KSWriter>
@end