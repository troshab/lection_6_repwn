
CC ?= gcc
CFLAGS_BASE := -m64 -O0 -g -fno-omit-frame-pointer -Wall -Wextra
LDFLAGS := 
OUT := build

all: $(OUT) \
	$(OUT)/stage01_nc \
	$(OUT)/stage02_checksec_dummy \
	$(OUT)/stage03_pwntools_dummy \
	$(OUT)/stage04_demo_no_offset \
	$(OUT)/stage05_demo_with_hint \
	$(OUT)/stage06_ret2win \
	$(OUT)/stage07_leak_demo \
	$(OUT)/stage08_ret2libc

$(OUT):
	mkdir -p $(OUT)

$(OUT)/stage01_nc: stage01_nc/server.c common/net.h common/net.c
	$(CC) $(CFLAGS_BASE) $^ -o $@

$(OUT)/stage02_checksec_dummy: stage02_checksec/dummy.c
	$(CC) $(CFLAGS_BASE) $^ -o $@

$(OUT)/stage03_pwntools_dummy: stage03_pwntools/server.c common/net.h common/net.c
	$(CC) $(CFLAGS_BASE) $^ -o $@

$(OUT)/stage04_demo_no_offset: stage04_demo_no_offset/server.c
	$(CC) $(CFLAGS_BASE) -no-pie $^ -o $@

$(OUT)/stage05_demo_with_hint: stage05_demo_with_hint/server.c
	$(CC) $(CFLAGS_BASE) -no-pie $^ -o $@

$(OUT)/stage06_ret2win: stage06_ret2win/server.c
	$(CC) $(CFLAGS_BASE) -fno-stack-protector -z execstack -no-pie -Wl,-z,norelro $^ -o $@

$(OUT)/stage07_leak_demo: stage07_leak_demo/server.c
	$(CC) $(CFLAGS_BASE) -ldl -no-pie $^ -o $@

$(OUT)/stage08_ret2libc: stage08_ret2libc/server.c
	$(CC) $(CFLAGS_BASE) -no-pie $^ -o $@

clean:
	rm -rf $(OUT)
