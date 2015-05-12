//
//  KSBufferingTests.m
//  KSWriter
//
//  Created by Mike on 29/04/2013.
//  Copyright (c) 2013 Karelia Software. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KSWriter.h"


@interface KSBufferingTests : XCTestCase

@end


@implementation KSBufferingTests
{
	KSWriter		*_writer;
	NSMutableString *_output;
}

#pragma mark Harness

- (void)performTestUsingBlock:(void (^)(KSWriter *writer))block;
{
	// Run each test twice, once to an output, and once having the writer build up its own string
	_output = [NSMutableString string];
	_writer = [KSWriter writerWithMutableString:_output encoding:NSUnicodeStringEncoding];
	block(_writer);
	
	_output = nil;
	_writer = [[KSWriter alloc] init];
	block(_writer);
	_writer = nil;
}

- (NSString *)string;	// returns what's been written so far
{
	return (_output ? _output : _writer.string);
}

#pragma mark Tests

- (void)testNoBuffering;
{
	[self performTestUsingBlock:^(KSWriter *writer) {
		
		[writer writeString:@"test"];
		XCTAssertEqualObjects(self.string, @"test");
	}];
}

- (void)testAppend;
{
	NSMutableString *output = [NSMutableString stringWithString:@"existing"];
	KSWriter *writer = [KSWriter writerWithMutableString:output encoding:NSUnicodeStringEncoding];
	[writer writeString:@"test"];
	
	XCTAssertEqualObjects(output, @"existingtest");
}

- (void)testBeginBuffer;
{
	[self performTestUsingBlock:^(KSWriter *writer) {
		
		[writer beginBuffer];
		[writer writeString:@"test"];
		
		XCTAssertTrue(writer.numberOfBuffers == 1);
		XCTAssertEqualObjects(self.string, @"", @"Buffer should stop anything being self.string");
	}];
}

- (void)testFlush;
{
	[self performTestUsingBlock:^(KSWriter *writer) {
		
		[writer beginBuffer];
		[writer writeString:@"test"];
		[writer writeString:@"ing"];	// make sure buffers are properly concatentated
		[writer flush];
		
		XCTAssertTrue(writer.numberOfBuffers == 0);
		XCTAssertEqualObjects(self.string, @"testing");
	}];
}

- (void)testDiscardBuffer;
{
	[self performTestUsingBlock:^(KSWriter *writer) {
		
		[writer writeString:@"beforebuffer"];
		
		[writer beginBuffer];
		[writer writeString:@"test"];
		[writer discardBuffer];
		
		XCTAssertTrue(writer.numberOfBuffers == 0);
		XCTAssertEqualObjects(self.string, @"beforebuffer", @"Buffer should stop anything being output");
		
		[writer writeString:@"test2"];
		
		XCTAssertEqualObjects(self.string, @"beforebuffertest2", @"test should be discarded, ready for test2 to be written untouched");
	}];
}

- (void)testBeginNestedBuffer;
{
	[self performTestUsingBlock:^(KSWriter *writer) {
		
		[writer beginBuffer];
		[writer beginBuffer];
		XCTAssertTrue(writer.numberOfBuffers == 2);
		
		[writer writeString:@"test"];
		XCTAssertTrue(writer.numberOfBuffers == 2);
		XCTAssertEqualObjects(self.string, @"", @"Buffer should stop anything being output");
	}];
}

- (void)testFlushNestedBuffers;
{
	[self performTestUsingBlock:^(KSWriter *writer) {
		
		[writer beginBuffer];
		[writer writeString:@"test"];
		[writer beginBuffer];
		[writer writeString:@"test2"];
		[writer flush];
		
		XCTAssertTrue(writer.numberOfBuffers == 0);
		XCTAssertEqualObjects(self.string, @"testtest2");
	}];
}

- (void)testFlushFirstBuffer;
{
	[self performTestUsingBlock:^(KSWriter *writer) {
		
		[writer beginBuffer];
		[writer writeString:@"test"];
		[writer beginBuffer];
		[writer writeString:@"test2"];
		XCTAssertTrue(writer.numberOfBuffers == 2);
		
		[writer flushFirstBuffer];
		XCTAssertTrue(writer.numberOfBuffers == 1);
		XCTAssertEqualObjects(self.string, @"test", @"The first buffer should flush, but not the second");
		
		// Make sure the second buffer hasn't been destroyed/damaged
		[writer flush];
		XCTAssertTrue(writer.numberOfBuffers == 0);
		XCTAssertEqualObjects(self.string, @"testtest2", @"The first buffer should flush, but not the second");
	}];
}

- (void)testDiscardNestedBuffer;
{
	[self performTestUsingBlock:^(KSWriter *writer) {
		
		[writer beginBuffer];
		[writer writeString:@"test"];
		XCTAssertTrue(writer.numberOfBuffers == 1);
		
		[writer beginBuffer];
		[writer writeString:@"test2"];
		XCTAssertTrue(writer.numberOfBuffers == 2);
		
		[writer discardBuffer];
		XCTAssertTrue(writer.numberOfBuffers == 1);
		
		[writer flush];
		XCTAssertTrue(writer.numberOfBuffers == 0);
		XCTAssertEqualObjects(self.string, @"test", @"The first buffer should have made it through, with the second discarded");
	}];
}

- (void)testFlushOnWrite;
{
	[self performTestUsingBlock:^(KSWriter *writer) {
		
		[writer beginBuffer];
		[writer writeString:@"test"];
		[writer flushOnNextWrite];
		XCTAssertTrue(writer.numberOfBuffers == 1);
		
		[writer writeString:@""];
		XCTAssertTrue(writer.numberOfBuffers == 1, @"An empty string should not trigger flushing");
		
		[writer writeString:@"ing"];
		XCTAssertTrue(writer.numberOfBuffers == 0);
		XCTAssertEqualObjects(self.string, @"testing");
	}];
}

- (void)testCancelFlushOnWrite;
{
	[self performTestUsingBlock:^(KSWriter *writer) {
		
		[writer beginBuffer];
		[writer writeString:@"test"];
		[writer flushOnNextWrite];
		XCTAssertTrue(writer.numberOfBuffers == 1);
		
		[writer cancelFlushOnNextWrite];
		[writer writeString:@"ing"];
		XCTAssertTrue(writer.numberOfBuffers == 1);
		XCTAssertEqualObjects(self.string, @"");
	}];
}

- (void)testBypassBuffer;
{
    [self performTestUsingBlock:^(KSWriter *writer) {
        
        [writer beginBuffer];
        [writer writeString:@"buffer1"];
        XCTAssertTrue(writer.numberOfBuffers == 1);
        
        [writer writeString:@"test" toBufferAtIndex:0];
		XCTAssertEqualObjects(self.string, @"test", @"String should be written direct to output, leaving the buffer untouched");
    }];
}

- (void)testIndirectlyWriteToBuffer;
{
    [self performTestUsingBlock:^(KSWriter *writer) {
        
        [writer beginBuffer];
        [writer writeString:@"buffer1"];
        XCTAssertTrue(writer.numberOfBuffers == 1);
        
        [writer writeString:@"test" toBufferAtIndex:1];
		XCTAssertEqualObjects(self.string, @"", @"Nothing should have been written yet");
        
        [writer flush];
        XCTAssertTrue(writer.numberOfBuffers == 0);
		XCTAssertEqualObjects(self.string, @"buffer1test");
    }];
}

- (void)testBypassNestedBuffer;
{
    [self performTestUsingBlock:^(KSWriter *writer) {
        
        [writer beginBuffer];
        [writer writeString:@"buffer1"];
        XCTAssertTrue(writer.numberOfBuffers == 1);
        
        [writer beginBuffer];
        [writer writeString:@"buffer2"];
        XCTAssertTrue(writer.numberOfBuffers == 2);
        
        [writer writeString:@"test" toBufferAtIndex:1];
        XCTAssertEqualObjects(self.string, @"", @"Nothing should have been written yet");
        
        [writer flush];
        XCTAssertTrue(writer.numberOfBuffers == 0);
        XCTAssertEqualObjects(self.string, @"buffer1testbuffer2", @"String should be written direct to output, leaving the buffer untouched");
    }];
}

@end
