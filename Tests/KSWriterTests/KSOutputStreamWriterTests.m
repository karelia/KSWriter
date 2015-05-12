//
//  KSHTMLWriterTests.m
//  KSHTMLWriterTests
//
//  Created by Sam Deane on 18/01/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KSWriter.h"


@interface MockStream : NSOutputStream

@property (strong, nonatomic) NSMutableString* written;

@end


@implementation MockStream

@synthesize written;

- (NSInteger)write:(const uint8_t *)bytes maxLength:(NSUInteger)len
{
    if (!self.written)
    {
        self.written = [[NSMutableString alloc] initWithCapacity:len];
    }
    
    NSString* string = [[NSString alloc] initWithBytes:bytes length:len encoding:NSUTF8StringEncoding];
    [self.written appendString:string];
    
    return len;
}

@end


#pragma mark -


@interface KSOutputStreamWriterTests : XCTestCase
@end


@implementation KSOutputStreamWriterTests

- (void)testInitiallyEmpty
{
    MockStream* stream = [[MockStream alloc] init];
    [KSWriter writerWithOutputStream:stream encoding:NSUTF8StringEncoding precomposeStrings:NO];

    XCTAssertNil(stream.written);
}

- (void)testWriting
{
    MockStream* stream = [[MockStream alloc] init];
    KSWriter* output = [KSWriter writerWithOutputStream:stream encoding:NSUTF8StringEncoding precomposeStrings:NO];

    [output writeString:@"test"];
    XCTAssertEqualObjects(stream.written, @"test");

    [output writeString:@"test"];
    XCTAssertEqualObjects(stream.written, @"testtest");
}

@end
