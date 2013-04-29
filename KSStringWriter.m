//
//  KSStringWriter.m
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


#import "KSStringWriter.h"


NSString *KSStringWriterWillFlushNotification = @"KSStringWriterWillFlush";


@implementation KSStringWriter

- (id)init;
{
    if (self = [super init])
    {
        _buffer = [[NSMutableString alloc] init];
        
        _bufferPoints = [[NSPointerArray alloc] initWithOptions:NSPointerFunctionsIntegerPersonality | NSPointerFunctionsOpaqueMemory];
        [_bufferPoints addPointer:0];
    }
    
    return self;
}

- (void)dealloc
{
    [_buffer release];
    [_bufferPoints release];
    
    [super dealloc];
}

#pragma mark NSString Primitives
// Not really used on the whole, but theoretically this class could be an NSString subclass

- (NSUInteger)length;
{
    return (NSUInteger)[_bufferPoints pointerAtIndex:([_bufferPoints count] - 1)];
}

- (unichar)characterAtIndex:(NSUInteger)index;
{
    NSParameterAssert(index < [self length]);
    return [_buffer characterAtIndex:index];
}

- (void)getCharacters:(unichar *)buffer range:(NSRange)aRange;
{
    NSParameterAssert(NSMaxRange(aRange) <= [self length]);
    return [_buffer getCharacters:buffer range:aRange];
}

#pragma mark Writing

- (NSUInteger)insertionPoint; { return (NSUInteger)[_bufferPoints pointerAtIndex:0]; }

- (NSString *)string;
{
    return [_buffer substringToIndex:[self length]];
}

- (void)writeString:(NSString *)string;
{
    // Flush if needed
    NSUInteger length = [string length];
    if (_flushOnNextWrite && length)
    {
        [self flush];
    }
    
    
    // Replace existing characters where possible
    NSUInteger insertionPoint = [self insertionPoint];
    NSUInteger unusedCapacity = [_buffer length] - insertionPoint;
    
    NSRange range = NSMakeRange(insertionPoint, MIN(length, unusedCapacity));
    [_buffer replaceCharactersInRange:range withString:string];
    
    insertionPoint = (insertionPoint + length);
    [_bufferPoints replacePointerAtIndex:0 withPointer:(void *)insertionPoint];
}

- (void)appendString:(NSString *)aString; { [self writeString:aString]; }

- (void)close;
{
    // Prune the buffer back down to size
    NSUInteger length = [self length];
    NSUInteger bufferLength = [_buffer length];
    if (bufferLength > length)
    {
        NSRange range = NSMakeRange(length, bufferLength - length);
        [_buffer deleteCharactersInRange:range];
    }
}

- (void)removeAllCharacters;
{
    [_bufferPoints release]; _bufferPoints = [[NSPointerArray alloc]
                                              initWithOptions:NSPointerFunctionsIntegerPersonality | NSPointerFunctionsOpaqueMemory];
    [_bufferPoints addPointer:0];
}

- (void)discardString;          // leaves only buffered content
{
    NSUInteger length = [self length];
    [_buffer deleteCharactersInRange:NSMakeRange(0, length)];
    
    NSUInteger i, count = [_bufferPoints count];
    for (i = 0; i < count; i++)
    {
        [_bufferPoints replacePointerAtIndex:i
                                 withPointer:(void *)((NSUInteger)[_bufferPoints pointerAtIndex:i] - length)];
    }
}

#pragma mark Buffering

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

- (NSUInteger)numberOfBuffers;
{
    return [_bufferPoints count] - 1;
}

- (void)startBuffering; // can be called multiple times, implementor chooses how to handle that
{
    [self beginBuffering];
}

// Can be called multiple times to set up a stack of buffers.
- (void)beginBuffering;
{
    [self cancelFlushOnNextWrite];
    [_bufferPoints insertPointer:(void *)[self insertionPoint] atIndex:0];
}

- (void)flushFirstBuffer;
{
    [_bufferPoints removePointerAtIndex:([_bufferPoints count] - 1)];
}

// Discards the most recent buffer. If there's a lower one in the stack, that is restored
- (void)discardBuffer;  
{
    NSParameterAssert([_bufferPoints count] > 1);
    [_bufferPoints removePointerAtIndex:0];
}

- (void)flush;
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:KSStringWriterWillFlushNotification
     object:self];
    
    // Ditch all buffer points except the one currently marking -insertionPoint
    for (NSUInteger i = [_bufferPoints count]-1; i > 0; i--)
    {
        [_bufferPoints removePointerAtIndex:i];
    }
    _flushOnNextWrite = NO;
}

- (void)writeString:(NSString *)string toBufferAtIndex:(NSUInteger)index;   // 0 bypasses all buffers
{
    NSUInteger invertedIndex = [_bufferPoints count] - 1 - index;
    NSUInteger insertionPoint = (NSUInteger)[_bufferPoints pointerAtIndex:invertedIndex];
    
    
    NSParameterAssert(insertionPoint <= [self insertionPoint]);
    [_buffer insertString:string atIndex:insertionPoint];
    
    NSUInteger i, count = invertedIndex + 1;
    for (i = 0; i < count; i++)
    {
        NSUInteger ind = (NSUInteger)[_bufferPoints pointerAtIndex:i];
        ind += [string length];
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

#pragma mark Flush-on-write

- (void)flushOnNextWrite; { _flushOnNextWrite = YES; }

- (void)cancelFlushOnNextWrite; { _flushOnNextWrite = NO; }

#pragma mark Debug

- (NSString *)debugDescription;
{
    NSString *result = [self description];
    result = [result stringByAppendingFormat:@" %@", [_buffer substringToIndex:[self insertionPoint]]];
    return result;
}

@end
