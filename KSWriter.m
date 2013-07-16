//
//  KSWriter.m
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

#import "KSWriter.h"


@implementation NSMutableString (KSWriter)

- (void)writeString:(NSString *)string
{
    /*  This was some experimental code to see if it would speed up writing:
    const UniChar *characters = CFStringGetCharactersPtr((CFStringRef)string);
    if (characters)
    {
        CFStringAppendCharacters((CFMutableStringRef)self,
                                 characters,
                                 CFStringGetLength((CFStringRef)string));
    }
    else
    {
        CFStringAppend((CFMutableStringRef)self, (CFStringRef)string);
    }*/

    [self appendString:string];
}

- (void)close; { }  // do nothing as it makes no sense to close a mutable string

@end
