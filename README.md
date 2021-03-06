ATTENTION
=========

This tool is outdated and I recommend you to try CMake. It's been years since I
created it and CMake does everything "dotmk" does and is much more
sophisticated.

If you really want to try "dotmk" please use it at your own risk.

INTRODUCTION
============

The "dotmk" project is composed by a set of GNU make scripts that are able to
simplify drastically the Makefile creation process. If your project needs to
use GNU make to compile its software, "dotmk" can simplify all the complicated
process of rules definitions and compiler commands creation. This task
sometimes takes lots of time to understand, define and debug, but "dotmk" does
it just by setting a couple of variables and a `include` line.

For now "dotmk" is only able to handle two basic tasks: C/C++ software building
(compilation and linking) and recursive calling GNU make in subdirectories. We
intent to implement other objectives like Doxygen extraction, LaTeX documents
compilation or Java support but this will come over the time. The instructions
to install "dotmk" in your project and execute each task follows.


INSTALL
=======

The installation process consists in the building of GNU make scripts under a
directory called `mk` in the project which will use "dotmk". tHE REsult will be
just that the project will contain that `mk` directory with some `.mk` files in
it.

To do that, unpack the "dotmk" package and call its `install.sh` script with a
target directory as its argument:

    $ tar -xzf dotmk-0.2.tar.gz
    $ cd dotmk
    $ ./install.sh ~/my-project

And that will create the `~/my-project/mk` directory with a few `.mk` files in
it. That will enable the use of "dotmk" in that project and you can proceed
with the Makefile creation in the next section.


TASKS
=====

Building C/C++ Software
-----------------------

The building process of a software coded in the C/C++ language is usually
simple. It consists in compiling its source code and linking the resulted
objects into one binary module, which might be a library or a executable. There
may be more details in this process, but this is the simplest example.

To build a Makefile without the "dotmk" project you would need to know how to
define its rules (which are not that simple), call GCC with its compiling
arguments, linking options and maybe AR. With "dotmk" you need to include the
following 3 intuitive lines in the Makefile file:

    PROG=foobar
    SRCS=foo.c bar.c
    include mk/build.mk

This would instruct GNU make compile the `foo.c` and `bar.c` files and link
them into the `foobar` executable. The last line just tells make to include
"dotmk" scripts. After that you just need to execute the following line to
build it.

    $ make

Very simple, uh?

One of the great things of "dotmk" is that it doesn't only define the building
targets, but the dependency detection and cleaning ones also. To create the
`.depend` file (please look at `mkdep` manual to understand what it is) you
need to call:

    $ make dep

And to finally clean all that mess you can call:

    $ make clean

It would clean all the built objects (create with the default `make` command),
but not the `.depend` file. To clean all the remaining file you would need to
call:

    $ make distclean

And that's it.

If you need to build a library just change the `PROG` variable name to `LIB`:

    LIB=foobar
    SRCS=foo.c bar.c
    include mk/build.mk

This would build the `libfoobar.so` and `libfoobar.a` binaries, but without
version definition. We intent to implement soon that too.

If you need to build more than one executable or library, use `PROGS` or `LIBS`
and prefix every `SRCS` line with the name of the program (or library) followed
by a underline. For example:

    PROGS=foobar qwerty
    foobar_SRCS=foo.c bar.c
    qwerty_SRCS=qwe.c rty.c
    include mk/build.mk

If you need to build the `foobar` and `qwerty` programs AND the `asdfgh` and
`zxcvbn` libraries:

    PROGS=foobar qwerty
    LIBS=asdfgh zxcvbn
    foobar_SRCS=foo.c bar.c
    qwerty_SRCS=qwe.c rty.c
    asdfgh_SRCS=asd.c fgh.c
    zxcvbn_SRCS=zxc.c vbn.c
    include mk/build.mk

And if you need to include library dependency, dynamic (.so) or static (.a),
use the `LIBDIRS` and `DEPLIBS` variables:

    PROGS=foobar
    foobar_SRCS=foo.c bar.c
    # libfftw.so is under /usr/local/lib
    foobar_LIBDIRS=/usr/local/lib
    foobar_DEPLIBS=fftw /opt/gtest/lib/libgtest.a ../lame.a
    include mk/build.mk

If your software depends on other softwares that uses `pkg-config` description
files (.pc), you just need to use the `DEPPKGCONFIG` variable:

    PROGS=foo qux
    foo_SRCS=bar.c
    foo_DEPPKGCONFIG=xinerama
    qux_SRCS=main.c
    qux_DEPPKGCONFIG=x11

And that would use the headers and libraries of `Xinerama` and `X11` when
building the `foo` and `qux` programs respectively. If you wish to pass a
`pkg-config` argument while getting CFLAGS and LIBS settings, just pass it
along with the packages in the same DEPPKGCONFIG variable. Don't forget to set
the `PKG_CONFIG_PATH` variable (make or environment) if the `.pc` files
aren't located in the default search path.

To include already compiled objects in your binary you should use the OBJS
variable:

    PROG=foobar
    SRCS=main.c
    OBJS=../closed/source.o
    include mk/build.mk

For headers dependency (include) there is the `INCDIRS` variable:

    PROG=foo
    SRCS=main.c
    INCDIRS=/opt/bar/include
    include mk/build.mk

You could think that this is beginning to be too complicated but, believe me,
with only GNU make the Makefile would be *MUCH* more complicated.


Qt/Qmake Support
----------------

If you have a Qt application that is already built with "qmake" and you wish to
include it in your project that uses "dotmk" I'd say that it is possible. You
just need to define your `.pro` file with the `PRO` variable and include the
`mk/qmake.mk` script:

    PRO=foo.pro
    include mk/qmake.mk

This would make the "dotmk" call the "qmake" utility whenever needed to build
the `foo` software. You can also define the `QMAKE` variable to call "qmake" by
a different command, for example:

    QMAKE=qmake-qt3
    PRO=foo.pro
    include mk/qmake.mk

With that setting "dotmk" would use the Qt3 version of "qmake" in a Debian-like
GNU/Linux distribution.


Recursive Calling in Subdirectories
-----------------------------------

If you have a project with lots of programs or libraries to be compiled, maybe
a good way to organize them would be dividing it into subdirectories. For
example, if you have the `foo` program and the `bar` library, you could create
a project tree as:

    .
    |-- Makefile
    |-- bar
    |   |-- Makefile
    |   `-- main.c
    |-- foo
    |   |-- Makefile
    |   `-- main.c
    `-- mk
        |-- build.mk
        `-- subdir.mk

To simplify the `make` command calls without the need to enter it two or more
times, you could use "dotmk" by just creating the following Makefile the main
directory:

    SUBDIRS=bar foo
    include mk/subdir.mk

This would enable the recursive call for the `all`, `clean`, `distclean` and
`install` targets.


Global definitions
------------------

There are situations where you need to set a variable for every Makefile that
is called. For these times you need to create a local `mk` file. The name of
the file must be the base name of the `mk` file you want to precede, suffixed
by the `-local.mk` name and created in the same directory where that `mk` file
is.

For example, if you need to set the PREFIX variable to install all files of
your project in a different directory, do it in the `build-local.mk` file under
the same directory where the original `build.mk` file is:

    $ echo PREFIX=/opt/foobar >> mk/build-local.mk

And then every `make install` command called will install the built files under
the `/opt/foobar` directory.


Cross Compiling
---------------

The cross compiling procedure is pretty simple: just set the `CROSS_COMPILE`
variable. Example:

    CROSS_COMPILE=arm-linux-gnu-
    PROG=foo
    SRCS=main.cpp foo.c bar.c FooBar.cpp
    include ../mk/build.mk

This would compile the `eptime` for ARM processor using arm-linux-gnu-gcc and
arm-linux-gnu-g++ as the compilers and arm-linux-gnu-g++ as the linker.

If you have a whole project which needs to be cross compiled, you can define
that variable in the local `mk` file called `build-local.mk`. For that just go
to the directory where "dotmk" was installed and run:

    $ echo CROSS_COMPILE=arm-linux-gnu- >> mk/build-local.mk


Debug Instructions
------------------

The debug mode is disabled if the DEBUG variable isn't defined, empty, defined
as `n`, `N`, `no` or `NO`. In any other cases (defined as `y`, `yes` or even
`x`) the debug mode is enabled and some special `gcc` arguments will be passed.
These arguments are:

* `-O0`: disable optimization -- make debugging produce the expected results;
* `-ggdb3`: produce debugging information for use by GDB;
* `-DDEBUG`: a macro to determine that the code is being compiled in debug mode;

When not in debug mode, the arguments are:

* `-O2`: optimize "even more" -- perform nearly all supported optimizations;
* `-DNDEBUG`: a macro to determine that the code is NOT being compiled in debug
  mode;
