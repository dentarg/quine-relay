require_relative "code-gen"
require "erb"
require "cairo"

other_packages = %w(cmake libpng12-dev libgd2-xpm-dev groff)
other_packages.each do |package|
  `dpkg -s #{ package }` # just check the packages
end

pkg_versions = {}
apts = RunSteps.map {|s| s.apt }
`which apt-get >/dev/null && dpkg -s #{ apts.join(" ") }`.b.split("\n\n").each do |s|
  name = s[/^Package: (.*)$/, 1]
  version = s[/^Version: (.*)$/, 1]
  pkg_versions[name] = version if name && version
end

rows = [["\\#", "language", "ubuntu package", "version"]]
rows += RunSteps.flat_map.with_index do |s, idx|
  (s.apt.is_a?(Array) ? s.apt : [s.apt]).map.with_index do |apt, i|
    [i == 0 ? (idx + 1).to_s : "", i == 0 ? s.name : "", apt || "*N/A*", pkg_versions[apt] || '-']
  end
end

ws = rows.transpose.map {|row| row.map {|s| s.size }.max + 1 }
rows[1, 0] = [ws.map {|w| "-" * w }]
rows = rows.map do |col|
  (col.zip(ws).map {|s, w| s.ljust(w) } * "|").rstrip
end

apt_get = "sudo apt-get install #{ [*apts.flatten.compact.uniq, *other_packages].sort * " " }"
apt_get.gsub!(/.{,70}( |\z)/) do
  $&[-1] == " " ? $& + "\\\n      " : $&
end

cmds = [*RunSteps, RunStep["Ruby", "QR2.rb"]].each_cons(2).map do |s1, s2|
  cmd = s1.cmd_raw
  src = s2.src
  cmd = cmd.gsub("OUTFILE", src)

  cmd = cmd.gsub(/.{60,}?&&/, "\\0\n     ")

  cmd
end

File.write("../README.md", ERB.new(DATA.read, nil, "%").result(binding))


__END__
# Quine Relay

[![Build Status](https://travis-ci.org/mame/quine-relay.svg?branch=master)](https://travis-ci.org/mame/quine-relay)

## What this is

This is a <%= RunSteps[0].name %> program that generates
<%= RunSteps[1].name %> program that generates
<%= RunSteps[2].name %> program that generates
...(through <%= RunSteps.size %> languages in total)...
<%= RunSteps[-1].name %> program that generates
the original <%= RunSteps[0].name %> code again.

![Language Uroboros][langs]

[langs]: https://raw.github.com/mame/quine-relay/master/langs.png

(If you want to see the old 50-language version, see [50](https://github.com/mame/quine-relay/tree/50) branch.)

## Usage

### Ubuntu

#### 1. Install all interpreters/compilers.

If you are using Ubuntu 14.10 "Utopic Unicorn", you can perform the following steps:

First, you have to type the following apt-get command to install all of them.

    $ <%= apt_get %>

Then, you have to build the bundled interpreters.

    $ make -C vendor

To run it on Ubuntu 12.04 LTS, you might want to refer to `.travis.yml`.

#### 2. Run each program on each interpreter/compiler.

% cmds.each do |cmd|
    $ <%= cmd %>
% end

You will see that `QR.rb` is the same as `QR2.rb`.

    $ diff QR.rb QR2.rb

Alternatively, just type `make`.

    $ make

Note: It may require huge memory to compile some files.

### Arch Linux

Just install [quine-relay-git](https://aur.archlinux.org/packages/quine-relay-git/) from AUR and run `quine-relay`.
Report any problems as comments to the AUR package or to the respective packages, if one of the many compilers should have issues.

### Other platforms

You may find [instructions for other platforms in the wiki](https://github.com/mame/quine-relay/wiki/Installation).

If you are not using these Linux distributions, please find your way yourself.
If you could do it, please let me know.  Good luck.

## Tested interpreter/compiler versions

I used the following Ubuntu deb packages to test this program.

% rows.each do |row|
<%= row %>
% end

Note that some languages are not available in Ubuntu (marked as *N/A*).
This repository includes their implementations in `vendor/`.
See also `vendor/README` in detail.


## Frequently asked questions

### Q. Why?

A. [Take your pick](https://github.com/mame/quine-relay/issues/11).

### Q. How?

A. *TBD*

### Q. Language XXX is missing!

A. See [the criteria for language inclusion][criteria] in detail.

In short: please create a deb package and contribute it to Ubuntu.

[criteria]: https://github.com/mame/quine-relay/wiki/Criteria-for-language-inclusion)

### Q. Does it really work?

A. [![Build Status](https://travis-ci.org/mame/quine-relay.svg?branch=master)](https://travis-ci.org/mame/quine-relay)

### Q. The code does not fit into my display!

A. [Here you go][thumbnail].

[thumbnail]: https://raw.github.com/mame/quine-relay/master/thumbnail.png

### Q. How was the code generated?

A.

    $ sudo apt-get install rake ruby-cairo ruby-rsvg2 ruby-gdk-pixbuf2 \
      optipng advancecomp ruby-chunky-png
    $ cd src
    $ rake2.0 clobber
    $ rake2.0

## License

The MIT License applies to all resources
*except* the files in the `vendor/` directory.

The files in the `vendor/` directory are from third-parties
and are distributed under different licenses.
See `vendor/README` in detail.

---

The MIT License (MIT)

Copyright (c) 2013, 2014 Yusuke Endoh (@mametter), @hirekoke

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
