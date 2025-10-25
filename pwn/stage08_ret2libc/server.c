
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>

void menu(void){
    puts("stage08: type LEAK to get libc address, or PAYLOAD for BOF:");
    fflush(stdout);
}

void leak(void){
    void* p = dlsym(RTLD_NEXT, "puts");
    dprintf(1, "PUTS=%p\n", p);
}

void bof(void){
    char buf[64];
    puts("send payload:");
    ssize_t n = read(0, buf, 400); // BOF with NX On
    dprintf(1, "got %zd bytes\n", n);
}

int main(void){
    setbuf(stdout, NULL);
    menu();
    char in[16]={0};
    if(read(0, in, sizeof(in)-1)<=0) return 0;
    if(!strncmp(in,"LEAK",4)){
        leak();
        bof();
    } else if(!strncmp(in,"PAYL",4)){
        bof();
    } else {
        puts("unknown");
    }
    return 0;
}
