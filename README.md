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

Add `KSWriter.h` and `KSWriter.m` to your project. These files define the common interface `-writeString:` for building up strings, as well as more advanced possibilities. Ideally, make this repo a submodule, but hey, it's your codebase, do whatever you feel like.

You can use `NSMutableString` instances directly, or add other, specialist writers into your project, such as:

* KSStringWriter
* KSBufferedWriter
* KSMutableDataWriter
* KSOutputStreamWriter

`KSForwardingWriter` provides a handy starting point for your own classes that work by piping output through to another `KSWriter`.

### XML/HTML/CSS ###

[KSHTMLWriter](https://github.com/karelia/KSHTMLWriter) builds on KSWriter to provide classes for generating string formats such as XML and HTML. It directly includes KSWriter as a submodule. It can also be built as a framework for Mac distribution, with the whole of KSWriter included and exposed.