
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

__attribute__((noreturn)) void win(void){
    puts("FLAG{STAGE6_RET2WIN}");
    fflush(stdout);
    _exit(0);
}

void vuln(void){
    char name[64];
    puts("stage06: send your name");
    ssize_t n = read(0, name, 256); // BOF
    dprintf(1, "hi %.*s\n", (int)(n>0?n:0), name);
}

int main(void){
    setbuf(stdout, NULL);
    vuln();
    return 0;
}
