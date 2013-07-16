//
//  KSOutputStreamWriter.h
//  Sandvox
//
//  Created by Mike Abdullah on 10/03/2011.
//  Copyright © 2011 Karelia Software
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//  Converts incoming strings to data and writes them to an NSOutputStream


#import "KSWriter.h"


@interface KSOutputStreamWriter : NSObject <KSWriter>
{
  @private
    NSOutputStream      *_outputStream;
    NSStringEncoding    _encoding;
    BOOL                _precompose;
    BOOL                _started;
}

// if precompose == YES, then Unicode Normalization Form C is applied to the output. This is handy for distributing to platforms which don't have as good unicode support as Apple's. More details at http://developer.apple.com/library/mac/#qa/qa1235/_index.html#//apple_ref/doc/uid/DTS10001757
- (id)initWithOutputStream:(NSOutputStream *)outputStream
                  encoding:(NSStringEncoding)encoding
         precomposeStrings:(BOOL)precompose;

- (id)initWithOutputStream:(NSOutputStream *)outputStream;  // uses UTF8 encoding, but doesn't precompose

@property(nonatomic, readonly) NSStringEncoding encoding;

@end
