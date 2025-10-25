
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

int main(void){
    char cmd[64]={0};
    read(0, cmd, sizeof(cmd)-1);
    if(strncmp(cmd, "LEAK", 4)==0){
        void* p = dlsym(RTLD_NEXT, "puts");
        dprintf(1, "PUTS=%p\n", p);
    }else{
        dprintf(1, "send LEAK\\n\n");
    }
    return 0;
}
