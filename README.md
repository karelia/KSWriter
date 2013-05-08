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

Licensed under the BSD License <http://www.opensource.org/licenses/bsd-license>
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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
