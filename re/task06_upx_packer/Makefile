CC?=gcc
CFLAGS?=-O2 -pipe -Wall -Wextra -std=c11
LDFLAGS?=
BUILD?=build

all: $(BUILD)/re106

$(BUILD)/re106: src/main.c
	@mkdir -p $(BUILD)
	$(CC) $(CFLAGS) -o $(BUILD)/re106 src/main.c $(LDFLAGS)

clean:
	rm -rf $(BUILD)
