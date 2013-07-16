//
//  KSForwardingWriter.h
//  
//  Created by Mike Abdullah
//  Copyright © 2010 Karelia Software
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
//  Abstract base class for any writers that operate by sending strings along to an output writer.
//


#import <Foundation/Foundation.h>
#import "KSWriter.h"


@interface KSForwardingWriter : NSObject <KSWriter>
{
  @private
    id <KSWriter> _writer;
}

#pragma mark Creating a Writer
- (id)initWithOutputWriter:(id <KSWriter>)stream; // designated initializer
- (id)init; // calls -initWithOutputWriter with nil. Handy for iteration & deriving info, but not a lot else


#pragma mark Primitive

- (void)writeString:(NSString *)string; // calls -writeString: on our string stream. Override to customize raw writing


@end
