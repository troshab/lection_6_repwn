#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int main(int argc, char **argv){
    if (argc != 3){
        fprintf(stderr, "usage: %s <name> <serial>\n", argv[0]);
        return 1;
    }
    const char *name = argv[1];
    const char *serial = argv[2];
    // Та сама логіка, але задачка припускає, що бінарник буде запаковано upx
    const char *EXPECTED = "PACKED-KEY-9000";
    if (strcmp(serial, EXPECTED) == 0){
        printf("FLAG{task6_ok_%s}\n", name);
        return 0;
    }
    puts("nope");
    return 2;
}
