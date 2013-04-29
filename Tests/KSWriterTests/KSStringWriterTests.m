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

@interface KSStringWriterTests : ECTestCase


@end

@implementation KSStringWriterTests

- (void)testInitiallyEmpty
{
    KSWriter* output = [[KSWriter alloc] init];
    STAssertTrue([[output string] isEqualToString:@""], @"starts off with empty string");
    [output release];
}

- (void)testWriting
{
    KSWriter* output = [[KSWriter alloc] init];
    [output writeString:@"test"];
    STAssertTrue([[output string] isEqualToString:@"test"], @"string is correct");

    [output writeString:@"test"];
    STAssertTrue([[output string] isEqualToString:@"testtest"], @"string is correct");

    [output release];
}

- (void)testClearing
{
    KSWriter* output = [[KSWriter alloc] init];
    [output writeString:@"test"];
    STAssertTrue([[output string] isEqualToString:@"test"], @"string is correct");
    
    [output removeAllCharacters];
    STAssertTrue([[output string] isEqualToString:@""], @"string is empty");
    
    [output release];
}

@end
