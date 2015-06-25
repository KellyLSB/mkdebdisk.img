# mkdebdisk.img

Is a bash library for creating disk images with debootstrap across multiple architectures.

The images for the RPi2 and Kosagi Novena are mostly working **links will be posted later**.
This should be easily adaptable for creating gold master images for netbooting and more.

## Dependencies

**This tool does require Linux!**

Debian 8/9 (jessie/sid):
- vmdebootstrap
- qemu-user-static
- awk
- sed
- bash
- chroot
- pv
- ...

__There are potentially more dependencies__

## Usage

RPi2 Example File: http://github.com/KellyLSB/rpi2

## License

The MIT License (MIT)

Copyright (c) 2015 Kelly Lauren-Summer Becker-Neuding

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
