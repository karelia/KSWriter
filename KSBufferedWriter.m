//
//  KSBufferedWriter.m
//  Sandvox
//
//  Created by Mike Abdullah on 05/08/2011.
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

#import "KSBufferedWriter.h"


@implementation KSBufferedWriter

#pragma mark Lifecycle

- (id)initWithOutputWriter:(id <KSWriter>)output; // designated initializer
{
    if (self = [super init])
    {
        _output = [output retain];
    }
    return self;
}

- (void)close;
{
    [super close];
    [_output release]; _output = nil;
}

- (void)dealloc;
{
    [self close];
    [super dealloc];
}

#pragma mark Writing

- (void)writeString:(NSString *)string;
{
    // Write through to output unless buffering
    if ([self numberOfBuffers])
    {
        [super writeString:string];
    }
    else
    {
        [_output writeString:string];
    }
}

#pragma mark Buffering

- (void)finishFlush;
{
    NSString *string = [super string];
    [_output writeString:string];
    [super discardString];
}

- (void)flush;
{
    [super flush];   // now -string returns the entire buffer
    [self finishFlush];
}

#pragma mark Multi-Buffering

- (void)flushFirstBuffer;
{
    [super flushFirstBuffer];   // now -string returns the first buffer
    [self finishFlush];
}

- (void)writeString:(NSString *)string toBufferAtIndex:(NSUInteger)index;   // 0 bypasses all buffers
{
    if (index)
    {
        [super writeString:string toBufferAtIndex:index];
    }
    else
    {
        [_output writeString:string];
    }
}

@end
