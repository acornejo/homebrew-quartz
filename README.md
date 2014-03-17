Homebrew-quartz
============
This repository contains a few gnu tools compiled for quartz. Its based
on the work of Sharpie, but with significant patches on inkscape to make
it work for Mountain Lion.

The main tool here is inkscape, which will run natively (i.e. will not
run inside X11 or XQuartz, but directly using GTK Quartz
backend).

This is the bleeding edge version of inkscape (0.91), since the stable
version (0.48) has problems which prevent it from compiling using clang
(and therefore require you to build gcc).

Installing Quartz Formulas
--------------------------
Just `brew tap acornejo/quartz` and then `brew install <formula>`.

To install inkscape do:
`brew install inkscape-quartz`

Expect the build to take about 20m.

You can also install via URL:

```
brew install https://raw.github.com/acornejo/homebrew-quartz/master/<formula>.rb
```

Docs
----
`brew help`, `man brew`, or the Homebrew [wiki][].

[wiki]:http://wiki.github.com/mxcl/homebrew
[homebrew-dupes]:https://github.com/Homebrew/homebrew-dupes
[homebrew-versions]:https://github.com/Homebrew/homebrew-versions
