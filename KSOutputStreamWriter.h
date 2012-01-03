//
//  KSOutputStreamWriter.h
//  Sandvox
//
//  Created by Mike on 10/03/2011.
//  Copyright 2011-2012 Karelia Software. All rights reserved.
//
//  Converts incoming strings to data and writes them to an NSOutputStream


#import "KSWriter.h"


@interface KSOutputStreamWriter : NSObject <KSWriter>
{
  @private
    NSOutputStream      *_outputStream;
    NSStringEncoding    _encoding;
    BOOL                _precompose;
}

// if precompose == YES, then Unicode Normalization Form C is applied to the output. This is handy for distributing to platforms which don't have as good unicode support as Apple's. More details at http://developer.apple.com/library/mac/#qa/qa1235/_index.html#//apple_ref/doc/uid/DTS10001757
- (id)initWithOutputStream:(NSOutputStream *)outputStream
                  encoding:(NSStringEncoding)encoding
         precomposeStrings:(BOOL)precompose;

- (id)initWithOutputStream:(NSOutputStream *)outputStream;  // uses UTF8 encoding, but doesn't precompose

@property(nonatomic, readonly) NSStringEncoding encoding;

@end
