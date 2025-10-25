
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

__attribute__((noreturn)) void win(void){
    puts("FLAG{STAGE4_DIRECT_JUMP}");
    fflush(stdout);
    _exit(0);
}

int main(void){
    void (*fp)(void) = NULL;
    ssize_t n = read(0, &fp, 8);
    if(n != 8) return 0;
    fp();
    return 0;
}
