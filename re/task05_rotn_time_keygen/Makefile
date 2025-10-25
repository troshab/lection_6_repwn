CC?=gcc
CFLAGS?=-O2 -pipe -Wall -Wextra -std=c11
LDFLAGS?=
BUILD?=build

all: $(BUILD)/re105

$(BUILD)/re105: src/main.c
	@mkdir -p $(BUILD)
	$(CC) $(CFLAGS) -o $(BUILD)/re105 src/main.c $(LDFLAGS)

clean:
	rm -rf $(BUILD)
