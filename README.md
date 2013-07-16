Features
========

KSWriter shamelessly rips off Java to provide a common interface for building up strings.

Contact
=======

I'm Mike Abdullah, of [Karelia Software](http://karelia.com). [@mikeabdullah](http://twitter.com/mikeabdullah) on Twitter.

Questions about the code should be left as issues at https://github.com/karelia/KSWriter or message me on Twitter.

Dependencies
============

None beyond Foundation. Probably works back to OS X v10.0 if you were so inclined.

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

Add `KSWriter.h` and `KSWriter.m` to your project. These files define the common interface `-writeString:` for building up strings, as well as more advanced possibilities. Ideally, make this repo a submodule, but hey, it's your codebase, do whatever you feel like.

You can use `NSMutableString` instances directly, or add other, specialist writers into your project, such as:

* KSStringWriter
* KSBufferedWriter
* KSMutableDataWriter
* KSOutputStreamWriter

`KSForwardingWriter` provides a handy starting point for your own classes that work by piping output through to another `KSWriter`.

### XML/HTML/CSS ###

[KSHTMLWriter](https://github.com/karelia/KSHTMLWriter) builds on KSWriter to provide classes for generating string formats such as XML and HTML. It directly includes KSWriter as a submodule. It can also be built as a framework for Mac distribution, with the whole of KSWriter included and exposed.