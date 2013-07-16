//
//  KSStringWriter.m
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
