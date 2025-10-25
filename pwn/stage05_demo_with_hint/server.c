
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>

static const size_t OFFSET = 72;

__attribute__((noreturn)) void win(void){
    puts("FLAG{STAGE5_HINT_OFFSET}");
    fflush(stdout);
    _exit(0);
}

int main(void){
    char buf[256]={0};
    ssize_t n = read(0, buf, sizeof(buf));
    if(n < (ssize_t)(OFFSET + 8)){
        size_t need = (OFFSET + 8) - (size_t)n;
        dprintf(1, "NEED=%zu\n", need);
        return 0;
    }
    void (*fp)(void) = *(void (**)(void))(buf + OFFSET);
    fp();
    return 0;
}
