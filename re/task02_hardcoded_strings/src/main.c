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
    (void)name;
    // навмисно вшитий рядок, щоб знайти через `strings`
    const char *EXPECTED = "S3R14L-ABCD-1337";
    if (strcmp(serial, EXPECTED) == 0){
        printf("FLAG{{task2_ok_%s}}\n", name);
        return 0;
    }
    puts("nope");
    return 2;
}
