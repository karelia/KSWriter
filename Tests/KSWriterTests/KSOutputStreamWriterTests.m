//
//  KSHTMLWriterTests.m
//  KSHTMLWriterTests
//
//  Created by Sam Deane on 18/01/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "KSWriter.h"
#import "ECTestCase.h"

@interface MockStream : NSOutputStream

@property (strong, nonatomic) NSMutableString* written;

@end

@implementation MockStream

@synthesize written;

- (NSInteger)write:(const uint8_t *)bytes maxLength:(NSUInteger)len
{
    if (!self.written)
    {
        self.written = [[[NSMutableString alloc] initWithCapacity:len] autorelease];
    }
    
    NSString* string = [[NSString alloc] initWithBytes:bytes length:len encoding:NSUTF8StringEncoding];
    [self.written appendString:string];
    [string release];
    
    return len;
}

@end


@interface KSOutputStreamWriterTests : ECTestCase


@end

@implementation KSOutputStreamWriterTests

- (void)testInitiallyEmpty
{
    MockStream* stream = [[MockStream alloc] init];
    [KSWriter writerWithOutputStream:stream encoding:NSUTF8StringEncoding precomposeStrings:NO];

    [self assertString:stream.written matchesString:@""];

    [stream release];
}

- (void)testWriting
{
    MockStream* stream = [[MockStream alloc] init];
    KSWriter* output = [KSWriter writerWithOutputStream:stream encoding:NSUTF8StringEncoding precomposeStrings:NO];

    [output writeString:@"test"];
    [self assertString:stream.written matchesString:@"test"];

    [output writeString:@"test"];
    [self assertString:stream.written matchesString:@"testtest"];

    [stream release];
}

@end
