//
//  KSHTMLWriterTests.m
//  KSHTMLWriterTests
//
//  Created by Sam Deane on 18/01/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KSWriter.h"


@interface KSMutableDataWriterTests : XCTestCase


@end


@implementation KSMutableDataWriterTests

- (void)testInitiallyEmpty
{
    NSMutableData* data = [NSMutableData data];
	[KSWriter writerWithMutableData:data encoding:NSUTF8StringEncoding precomposeStrings:NO];
    XCTAssertTrue([data length] == 0, @"doesn't do anything with data until strings are written");
}

- (void)testWriting
{
    NSMutableData* data = [NSMutableData data];
    KSWriter* output = [KSWriter writerWithMutableData:data encoding:NSUTF8StringEncoding precomposeStrings:NO];

    [output writeString:@"test"];
    NSString* string1 = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(string1, @"test");
    
    [output writeString:@"test"];
    NSString* string2 = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(string2, @"testtest");
}

@end
