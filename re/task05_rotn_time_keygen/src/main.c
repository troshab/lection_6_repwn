#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <ctype.h>

static char rot_shift(char c, int n){
    if ('a'<=c && c<='z'){
        return (char)('a' + ( (c-'a') + n )%26);
    } else if ('A'<=c && c<='Z'){
        return (char)('A' + ( (c-'A') + n )%26);
    }
    return c;
}
static void rot_apply(char *dst, const char *src, int n){
    for (int i=0; src[i]; i++){
        dst[i]=rot_shift(src[i], n);
    }
}

int main(int argc, char **argv){
    if (argc != 3){
        fprintf(stderr, "usage: %s <name> <serial>\n", argv[0]);
        return 1;
    }
    const char *name = argv[1];
    const char *serial = argv[2];
    time_t t = time(NULL);
    int N = (int)(t % 20);
    size_t L = strlen(name);
    char *tmp = calloc(L+1, 1);
    rot_apply(tmp, name, N);
    int ok = strcmp(tmp, serial)==0;
    if (ok){
        printf("FLAG{task5_ok_%s}\n", name);
    } else {
        puts("nope");
    }
    free(tmp);
    return ok?0:2;
}
