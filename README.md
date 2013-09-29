Features
========

KSWriter shamelessly rips off Java's Writer classes. It allows you to build up strings, piping them straight through to destination's such as:

* `NSMutableString`
* `NSMutableData` or an `NSOutputStream`
* A custom block of your design

This is generally more efficient than building up a large `NSMutableString` yourself. When outputting data, KSWriter can perform services like normalizing unicode character sequences for you.

KSWriter also provides buffering facilities for extra control.

Contact
=======

I'm Mike Abdullah, of [Karelia Software](http://karelia.com). [@mikeabdullah](http://twitter.com/mikeabdullah) on Twitter.

Questions about the code should be left as issues at https://github.com/karelia/KSWriter or message me on Twitter.

Dependencies
============

OS X 10.6 or later. No other dependencies beyond Foundation.

License
=======

Copyright © 2010-2013 Karelia Software

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

Usage
=====

### Vanilla ###

Add `KSWriter.h` and `KSWriter.m` to your project. Ideally, make this repo a submodule, but hey, it's your codebase, do whatever you feel like.

### XML/HTML/CSS ###

[KSHTMLWriter](https://github.com/karelia/KSHTMLWriter) builds on KSWriter to provide classes for generating string formats such as XML and HTML. It directly includes KSWriter as a submodule. It can also be built as a framework for Mac distribution, with the whole of KSWriter included and exposed.

Release Notes
=============

### 2.0

* The codebase has been collapsed down to a single `KSWriter` class
* There is no longer a `KSWriter` protocol, just the class. `NSMutableString` is no longer a valid writer; instead create one using `+writerWithMutableString:encoding:` or `+stringWriterWithEncoding:`
* The primitive writing method is `-writeString:range:` which allows writers to more efficiently extract just the desired range of characters, without the overhead of creating a temporary string. `-writeString:` is still present, of course, as a convenience
* All `KSWriter` instances have a `.stringEncoding` property. Even when not outputting raw data, this may be used to optimise internal buffers. It's particularly handy for classes like `KSXMLWriter` who build on `KSWriter` and need to know the encoding of their final output
* Similarly, all writers now have buffering facilities available to them
* Writing to `NSMutableData` supports precomposing
