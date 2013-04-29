//
//  KSBufferingTests.m
//  KSWriter
//
//  Created by Mike on 29/04/2013.
//  Copyright (c) 2013 Karelia Software. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "KSWriter.h"


@interface KSBufferingTests : SenTestCase

@end


@implementation KSBufferingTests

- (void)testNoBuffering;
{
	NSMutableString *output = [NSMutableString string];
	KSWriter *writer = [KSWriter writerWithMutableString:output];
	[writer writeString:@"test"];
	
	STAssertEqualObjects(output, @"test", nil);
}

- (void)testAppend;
{
	NSMutableString *output = [NSMutableString stringWithString:@"existing"];
	KSWriter *writer = [KSWriter writerWithMutableString:output];
	[writer writeString:@"test"];
	
	STAssertEqualObjects(output, @"existingtest", nil);
}

- (void)testBeginBuffer;
{
	NSMutableString *output = [NSMutableString string];
	KSWriter *writer = [KSWriter writerWithMutableString:output];
	[writer beginBuffer];
	[writer writeString:@"test"];
	
	STAssertTrue(writer.numberOfBuffers == 1, nil);
	STAssertEqualObjects(output, @"", @"Buffer should stop anything being output");
}

- (void)testFlush;
{
	NSMutableString *output = [NSMutableString string];
	KSWriter *writer = [KSWriter writerWithMutableString:output];
	[writer beginBuffer];
	[writer writeString:@"test"];
	[writer writeString:@"ing"];	// make sure buffers are properly concatentated
	[writer flush];
	
	STAssertTrue(writer.numberOfBuffers == 0, nil);
	STAssertEqualObjects(output, @"testing", nil);
}

- (void)testDiscardBuffer;
{
	NSMutableString *output = [NSMutableString string];
	KSWriter *writer = [KSWriter writerWithMutableString:output];
	[writer beginBuffer];
	[writer writeString:@"test"];
	[writer discardBuffer];
	
	STAssertTrue(writer.numberOfBuffers == 0, nil);
	STAssertEqualObjects(output, @"", @"Buffer should stop anything being output");
	
	[writer writeString:@"test2"];
	
	STAssertEqualObjects(output, @"test2", @"test should be discarded, ready for test2 to be written untouched");
}

- (void)testBeginNestedBuffer;
{
	NSMutableString *output = [NSMutableString string];
	KSWriter *writer = [KSWriter writerWithMutableString:output];
	[writer beginBuffer];
	[writer beginBuffer];
	STAssertTrue(writer.numberOfBuffers == 2, nil);

	[writer writeString:@"test"];
	STAssertTrue(writer.numberOfBuffers == 2, nil);
	STAssertEqualObjects(output, @"", @"Buffer should stop anything being output");
}

- (void)testFlushNestedBuffers;
{
	NSMutableString *output = [NSMutableString string];
	KSWriter *writer = [KSWriter writerWithMutableString:output];
	[writer beginBuffer];
	[writer writeString:@"test"];
	[writer beginBuffer];
	[writer writeString:@"test2"];
	[writer flush];
	
	STAssertTrue(writer.numberOfBuffers == 0, nil);
	STAssertEqualObjects(output, @"testtest2", nil);
}

- (void)testFlushFirstBuffer;
{
	NSMutableString *output = [NSMutableString string];
	KSWriter *writer = [KSWriter writerWithMutableString:output];
	[writer beginBuffer];
	[writer writeString:@"test"];
	[writer beginBuffer];
	[writer writeString:@"test2"];
	STAssertTrue(writer.numberOfBuffers == 2, nil);

	[writer flushFirstBuffer];
	STAssertTrue(writer.numberOfBuffers == 1, nil);
	STAssertEqualObjects(output, @"test", @"The first buffer should flush, but not the second");
	
	// Make sure the second buffer hasn't been destroyed/damaged
	[writer flush];
	STAssertTrue(writer.numberOfBuffers == 0, nil);
	STAssertEqualObjects(output, @"testtest2", @"The first buffer should flush, but not the second");
}

- (void)testDiscardNestedBuffer;
{
	NSMutableString *output = [NSMutableString string];
	KSWriter *writer = [KSWriter writerWithMutableString:output];
	
	[writer beginBuffer];
	[writer writeString:@"test"];
	STAssertTrue(writer.numberOfBuffers == 1, nil);
	
	[writer beginBuffer];
	[writer writeString:@"test2"];
	STAssertTrue(writer.numberOfBuffers == 2, nil);
	
	[writer discardBuffer];
	STAssertTrue(writer.numberOfBuffers == 1, nil);

	[writer flush];
	STAssertTrue(writer.numberOfBuffers == 0, nil);
	STAssertEqualObjects(output, @"test", @"The first buffer should have made it through, with the second discarded");
}

- (void)testFlushOnWrite;
{
	NSMutableString *output = [NSMutableString string];
	KSWriter *writer = [KSWriter writerWithMutableString:output];
	[writer beginBuffer];
	[writer writeString:@"test"];
	[writer flushOnNextWrite];
	STAssertTrue(writer.numberOfBuffers == 1, nil);
	
	[writer writeString:@""];
	STAssertTrue(writer.numberOfBuffers == 1, @"An empty string should not trigger flushing");
	
	[writer writeString:@"ing"];
	STAssertTrue(writer.numberOfBuffers == 0, nil);
	STAssertEqualObjects(output, @"testing", nil);
}

- (void)testCancelFlushOnWrite;
{
	NSMutableString *output = [NSMutableString string];
	KSWriter *writer = [KSWriter writerWithMutableString:output];
	[writer beginBuffer];
	[writer writeString:@"test"];
	[writer flushOnNextWrite];
	STAssertTrue(writer.numberOfBuffers == 1, nil);
	
	[writer cancelFlushOnNextWrite];
	[writer writeString:@"ing"];
	STAssertTrue(writer.numberOfBuffers == 1, nil);
	STAssertEqualObjects(output, @"", nil);
}

@end
