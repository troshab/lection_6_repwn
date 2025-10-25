#include <stdio.h>
#include <string.h>

int main(int argc, char **argv){
    // тривіальна програма, щоб було що інвентаризувати
    const char *banner = "re101 inventory sample";
    if (argc > 1 && strcmp(argv[1], "--hello") == 0){
        puts(banner);
    } else {
        puts("usage: ./re101 [--hello]");
    }
    return 0;
}
