
#include "../common/net.h"
int main(void){
    int s = tcp_listen("127.0.0.1", 7101);
    int c = tcp_accept_one(s);
    dprintf(c, "say HELLO or GIMME FLAG\n");
    char buf[256]={0};
    ssize_t n = read(c, buf, sizeof(buf)-1);
    if(n > 0 && strstr(buf, "GIMME FLAG")){
        dprintf(c, "FLAG{STAGE1_HELLO}\n");
    } else if(n > 0 && strstr(buf, "HELLO")){
        dprintf(c, "hi\n");
    } else {
        dprintf(c, "nope\n");
    }
    close(c); close(s);
    return 0;
}
