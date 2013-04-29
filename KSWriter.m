//
//  KSWriter.m
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


#import "KSWriter.h"


@implementation KSWriter
{
    void    (^_block)(NSString *, NSRange);
}

#pragma mark Init & Dealloc

- (id)initWithOutputWriter:(id <KSWriter>)output; // designated initializer
{
    return [self initWithBlock:^(NSString *string, NSRange range) {
		[output writeString:string range:range];
	}];
}

- (id)initWithBlock:(void (^)(NSString *string, NSRange range))block;
{
    NSParameterAssert(block);
    
    if (self = [self init])
    {
        _block = [block copy];
    }
    return self;
}

- (id)init;
{
	// Create empty block rather than have -writeString:… keep checking if it's nil
    return [self initWithBlock:^(NSString *string, NSRange range) { }];
}

- (void)dealloc
{
    [self close];
    NSAssert(!_block, @"-close failed to dispose of writer block");
    
    [super dealloc];
}

#pragma mark Primitive

- (void)writeString:(NSString *)string;
{
	return [self writeString:string range:NSMakeRange(0, string.length)];
}

- (void)writeString:(NSString *)string range:(NSRange)range;
{
    _block(string, range);
}

- (void)appendString:(NSString *)aString; { [self writeString:aString]; }

- (void)close;
{
    [_block release]; _block = nil;
}

@end


#pragma mark -


@implementation NSMutableString (KSWriter)

@end
