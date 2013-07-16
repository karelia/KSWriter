//
//  KSStringWriter.h
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

#import "KSWriter.h"


@interface KSStringWriter : NSObject <KSMultiBufferingWriter>
{
  @private
    NSMutableString *_buffer;
    NSPointerArray  *_bufferPoints; // stored in reverse order for efficiency
    BOOL            _flushOnNextWrite;
}

- (NSUInteger)length;
- (NSString *)string;

- (void)removeAllCharacters;    // reset, but cunningly keeps memory allocated for speed
- (void)close;                  // no effect on output/state, but frees any unused memory
- (void)discardString;          // leaves only buffered content

#pragma mark Buffering

- (void)beginBuffering; // can be called multiple times to set up a stack of buffers.
- (void)discardBuffer;  // discards the most recent buffer


#pragma mark Flush-on-write
- (void)flushOnNextWrite;   // calls -flush at next write. Can still use -discardBuffer to effectively cancel this
- (void)cancelFlushOnNextWrite;


@end


extern NSString *KSStringWriterWillFlushNotification;