# RISC-V Embedded PIC Tock OS C App Example

## Overview

lowRISC is working on a specification and [prototype toolchain implementation](https://github.com/lowRISC/llvm-project/commits/epic) of an Embedded PIC (ePIC) ABI for RISC-V.

This repository illustrates how to use the work-in-progress ePIC toolchain implementation to create relocatable RISC-V Tock OS applications. It builds the libtock-c hello world example, `c_hello`, with an ePIC configuration and runs it under QEMU. That example has been slightly modified to print the addresses and values of some program symbols, to demonstrate the relocation capabilities.

## Building and Running

Build requirements:

- LLVM build dependencies
- crosstool-ng
- rustup

The other dependencies are installed automatically. This example has been tested against Tock commit `2910b1238`.

Use `make run` to build everything and run the example application. Use `make relocate` to patch Tock to load the app at different Flash and RAM memory addresses. For instance:

```
$ make run
# (...)
Hello World!
ePIC example: x=42 *y=42 &x=0x800030d8 y=0x800030d8 &main=0x200400b2.
# ctrl-a ctrl-x to quit QEMU

$ make relocate
cd tock && patch -p1 < ../change-app-load-addr.diff
patching file boards/hifive1/Makefile
patching file boards/kernel_layout.ld

$ make run
# (...)
Hello World!
ePIC example: x=42 *y=42 &x=0x800031d8 y=0x800031d8 &main=0x200401b2.
```

## Licensing

Unless otherwise noted, everything in this repository is covered by the Apache License, Version 2.0 (see [LICENSE](LICENSE) for full text).
