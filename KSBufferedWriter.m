//
//  KSBufferedWriter.m
//  Sandvox
//
//  Created by Mike on 05/08/2011.
//  Copyright 2011 Karelia Software. All rights reserved.
//

#import "KSBufferedWriter.h"


@implementation KSBufferedWriter

#pragma mark Lifecycle

- (id)initWithOutputWriter:(id <KSWriter>)output; // designated initializer
{
    [super init];
    
    _output = [output retain];
    
    return self;
}

- (void)close;
{
    [super close];
    [_output release]; _output = nil;
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
