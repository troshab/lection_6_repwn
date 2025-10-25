
#pragma once
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

static inline int tcp_listen(const char* ip, int port){
    int s = socket(AF_INET, SOCK_STREAM, 0);
    int opt = 1; setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    struct sockaddr_in addr = {0};
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = inet_addr(ip);
    if(bind(s, (struct sockaddr*)&addr, sizeof(addr)) < 0){ perror("bind"); exit(1); }
    if(listen(s, 1) < 0){ perror("listen"); exit(1); }
    return s;
}

static inline int tcp_accept_one(int s){
    int c = accept(s, NULL, NULL);
    if(c < 0){ perror("accept"); exit(1); }
    return c;
}
