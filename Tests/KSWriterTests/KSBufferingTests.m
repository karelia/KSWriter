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
{
	KSWriter		*_writer;
	NSMutableString *_output;
}

#pragma mark Harness

- (void)performTestUsingBlock:(void (^)(KSWriter *writer))block;
{
	// Run each test twice, once to an output, and once having the writer build up its own string
	_output = [NSMutableString string];
	_writer = [KSWriter writerWithMutableString:_output];
	block(_writer);
	
	_output = nil;
	_writer = [[KSWriter alloc] init];
	block(_writer);
	[_writer release]; _writer = nil;
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
		STAssertEqualObjects(self.string, @"test", nil);
	}];
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
	[self performTestUsingBlock:^(KSWriter *writer) {
		
		[writer beginBuffer];
		[writer writeString:@"test"];
		
		STAssertTrue(writer.numberOfBuffers == 1, nil);
		STAssertEqualObjects(self.string, @"", @"Buffer should stop anything being self.string");
	}];
}

- (void)testFlush;
{
	[self performTestUsingBlock:^(KSWriter *writer) {
		
		[writer beginBuffer];
		[writer writeString:@"test"];
		[writer writeString:@"ing"];	// make sure buffers are properly concatentated
		[writer flush];
		
		STAssertTrue(writer.numberOfBuffers == 0, nil);
		STAssertEqualObjects(self.string, @"testing", nil);
	}];
}

- (void)testDiscardBuffer;
{
	[self performTestUsingBlock:^(KSWriter *writer) {
		
		[writer writeString:@"beforebuffer"];
		
		[writer beginBuffer];
		[writer writeString:@"test"];
		[writer discardBuffer];
		
		STAssertTrue(writer.numberOfBuffers == 0, nil);
		STAssertEqualObjects(self.string, @"beforebuffer", @"Buffer should stop anything being output");
		
		[writer writeString:@"test2"];
		
		STAssertEqualObjects(self.string, @"beforebuffertest2", @"test should be discarded, ready for test2 to be written untouched");
	}];
}

- (void)testBeginNestedBuffer;
{
	[self performTestUsingBlock:^(KSWriter *writer) {
		
		[writer beginBuffer];
		[writer beginBuffer];
		STAssertTrue(writer.numberOfBuffers == 2, nil);
		
		[writer writeString:@"test"];
		STAssertTrue(writer.numberOfBuffers == 2, nil);
		STAssertEqualObjects(self.string, @"", @"Buffer should stop anything being output");
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
		
		STAssertTrue(writer.numberOfBuffers == 0, nil);
		STAssertEqualObjects(self.string, @"testtest2", nil);
	}];
}

- (void)testFlushFirstBuffer;
{
	[self performTestUsingBlock:^(KSWriter *writer) {
		
		[writer beginBuffer];
		[writer writeString:@"test"];
		[writer beginBuffer];
		[writer writeString:@"test2"];
		STAssertTrue(writer.numberOfBuffers == 2, nil);
		
		[writer flushFirstBuffer];
		STAssertTrue(writer.numberOfBuffers == 1, nil);
		STAssertEqualObjects(self.string, @"test", @"The first buffer should flush, but not the second");
		
		// Make sure the second buffer hasn't been destroyed/damaged
		[writer flush];
		STAssertTrue(writer.numberOfBuffers == 0, nil);
		STAssertEqualObjects(self.string, @"testtest2", @"The first buffer should flush, but not the second");
	}];
}

- (void)testDiscardNestedBuffer;
{
	[self performTestUsingBlock:^(KSWriter *writer) {
		
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
		STAssertEqualObjects(self.string, @"test", @"The first buffer should have made it through, with the second discarded");
	}];
}

- (void)testFlushOnWrite;
{
	[self performTestUsingBlock:^(KSWriter *writer) {
		
		[writer beginBuffer];
		[writer writeString:@"test"];
		[writer flushOnNextWrite];
		STAssertTrue(writer.numberOfBuffers == 1, nil);
		
		[writer writeString:@""];
		STAssertTrue(writer.numberOfBuffers == 1, @"An empty string should not trigger flushing");
		
		[writer writeString:@"ing"];
		STAssertTrue(writer.numberOfBuffers == 0, nil);
		STAssertEqualObjects(self.string, @"testing", nil);
	}];
}

- (void)testCancelFlushOnWrite;
{
	[self performTestUsingBlock:^(KSWriter *writer) {
		
		[writer beginBuffer];
		[writer writeString:@"test"];
		[writer flushOnNextWrite];
		STAssertTrue(writer.numberOfBuffers == 1, nil);
		
		[writer cancelFlushOnNextWrite];
		[writer writeString:@"ing"];
		STAssertTrue(writer.numberOfBuffers == 1, nil);
		STAssertEqualObjects(self.string, @"", nil);
	}];
}

- (void)testBypassBuffer;
{
    [self performTestUsingBlock:^(KSWriter *writer) {
        
        [writer beginBuffer];
        [writer writeString:@"buffer1"];
        STAssertTrue(writer.numberOfBuffers == 1, nil);
        
        [writer writeString:@"test" toBufferAtIndex:0];
		STAssertEqualObjects(self.string, @"test", @"String should be written direct to output, leaving the buffer untouched");
    }];
}

- (void)testIndirectlyWriteToBuffer;
{
    [self performTestUsingBlock:^(KSWriter *writer) {
        
        [writer beginBuffer];
        [writer writeString:@"buffer1"];
        STAssertTrue(writer.numberOfBuffers == 1, nil);
        
        [writer writeString:@"test" toBufferAtIndex:1];
		STAssertEqualObjects(self.string, @"", @"Nothing should have been written yet");
        
        [writer flush];
        STAssertTrue(writer.numberOfBuffers == 0, nil);
		STAssertEqualObjects(self.string, @"buffer1test", nil);
    }];
}

- (void)testBypassNestedBuffer;
{
    [self performTestUsingBlock:^(KSWriter *writer) {
        
        [writer beginBuffer];
        [writer writeString:@"buffer1"];
        STAssertTrue(writer.numberOfBuffers == 1, nil);
        
        [writer beginBuffer];
        [writer writeString:@"buffer2"];
        STAssertTrue(writer.numberOfBuffers == 2, nil);
        
        [writer writeString:@"test" toBufferAtIndex:1];
        STAssertEqualObjects(self.string, @"", @"Nothing should have been written yet");
        
        [writer flush];
        STAssertTrue(writer.numberOfBuffers == 0, nil);
        STAssertEqualObjects(self.string, @"buffer1testbuffer2", @"String should be written direct to output, leaving the buffer untouched");
    }];
}

@end
