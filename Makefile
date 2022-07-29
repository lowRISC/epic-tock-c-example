# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

export PATH := $(PATH):$(PWD)/llvm-project/build/bin
export PATH := $(PWD)/elf2tab/target/debug:$(PATH)

example=libtock-c/examples/c_hello
tbf=build/rv32imac/rv32imac.tbf
elf2tab=elf2tab/target/debug/elf2tab

run: $(example)/$(tbf) tock tock/tools/qemu
	cd tock/boards/hifive1 && QEMU=../../tools/qemu/build/qemu-system-riscv32 APP=$(PWD)/$(example)/$(tbf) make qemu-app
	cd tock/boards/opentitan/earlgrey-cw310 && OPENTITAN_BOOT_ROM=../../../tools/qemu-runner/opentitan-boot-rom.elf APP=$(PWD)/$(example)/$(tbf) make qemu-app

relocate: tock
	cd tock && patch -p1 < ../change-app-load-addr.diff

$(example)/$(tbf): libtock-c $(elf2tab) llvm-project/build/bin/riscv32-unknown-elf-clang libtock-c/newlib/newlib-4.1.0
	cd $(example) && make V=1 TOCK_TARGETS="rv32imac|rv32imac" CC=-clang CPPFLAGS="-fepic -I$(PWD)/libtock-c/newlib/newlib-4.1.0/newlib/libc/include" WLFLAGS="-Wl,--emit-relocs -fuse-ld=lld"

libtock-c/newlib/newlib-4.1.0: libtock-c
	cd libtock-c/newlib && make newlib-4.1.0

libtock-c:
	git clone -b epic-example https://github.com/luismarques/libtock-c.git

tock:
	git clone --recursive https://github.com/tock/tock.git

$(elf2tab): elf2tab
	cd elf2tab && cargo build

elf2tab:
	git clone -b rela_lld https://github.com/luismarques/elf2tab.git

llvm-project:
	git clone -b epic --depth=1 https://github.com/lowRISC/llvm-project.git

llvm-project/build/bin/riscv32-unknown-elf-clang: llvm-project
	mkdir -p llvm-project/build && cd llvm-project/build && cmake ../llvm -G Ninja -DCMAKE_BUILD_TYPE="Release" -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DLLVM_ENABLE_LLD=True -DLLVM_TARGETS_TO_BUILD="RISCV" -DLLVM_ENABLE_PROJECTS="clang;lld" && ninja
	cd llvm-project/build/bin && ln -sf clang riscv32-unknown-elf-clang
	cd llvm-project/build/bin && ln -sf llvm-size riscv32-unknown-elf-size
	cd llvm-project/build/bin && ln -sf llvm-ar riscv32-unknown-elf-ar
	cd llvm-project/build/bin && ln -sf llvm-ar riscv32-unknown-elf-ranlib

tock/tools/qemu: tock
	cd tock && CI=y make ci-setup-qemu

rebuild-newlib: libtock-c llvm-project/build/bin/riscv32-unknown-elf-clang
	cd llvm-project/build/bin && ln -sf llvm-ar riscv64-unknown-elf-ar
	cd llvm-project/build/bin && ln -sf llvm-ar riscv64-unknown-elf-ranlib
	cd llvm-project/build/bin && ln -sf clang riscv64-unknown-elf-cc
	cd libtock-c/newlib && make

.PHONY: run relocate rebuild-newlib
