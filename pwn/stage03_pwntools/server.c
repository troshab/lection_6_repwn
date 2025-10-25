
#include "../common/net.h"
int main(void){
    int s = tcp_listen("127.0.0.1", 7103);
    int c = tcp_accept_one(s);
    dprintf(c, "say the magic word\n");
    char buf[256]={0};
    ssize_t n = read(c, buf, sizeof(buf)-1);
    if(n > 0 && strstr(buf, "GIMME FLAG")){
        dprintf(c, "FLAG{STAGE3_AUTO}\n");
    } else {
        dprintf(c, "nope\n");
    }
    close(c); close(s);
    return 0;
}
