#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <errno.h>

static void serve_once(const char *name){
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) exit(111);
    int yes = 1;
    setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(31337);
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK); // 127.0.0.1

    if (bind(fd, (struct sockaddr*)&addr, sizeof(addr)) < 0) exit(112);
    if (listen(fd, 8) < 0) exit(113);

    int cfd = accept(fd, NULL, NULL);
    if (cfd < 0) exit(114);

    // дуже просте формування відповіді, без жорстких констант для strings
    char buf[1024];
    ssize_t r = recv(cfd, buf, sizeof(buf)-1, 0);
    if (r > 0) {
        buf[r] = 0;
    }

    char body[256];
    snprintf(body, sizeof(body), "FLAG{task7_ok_%s}\n", name);
    char header[512];
    int body_len = (int)strlen(body);
    // HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: %d\r\n\r\n
    // конструюємо по шматках
    snprintf(header, sizeof(header),
        "HTTP/1.1 200 OK\r\n"
        "Content-Type: text/plain\r\n"
        "Content-Length: %d\r\n"
        "Connection: close\r\n"
        "\r\n", body_len);

    send(cfd, header, strlen(header), 0);
    send(cfd, body, body_len, 0);

    close(cfd);
    close(fd);
}

int main(int argc, char **argv){
    if (argc != 2){
        fprintf(stderr, "usage: %s <name>\n", argv[0]);
        return 1;
    }
    const char *name = argv[1];

    pid_t pid = fork();
    if (pid < 0){
        perror("fork");
        return 2;
    }
    if (pid == 0){
        // дитячий процес — прихований HTTP-сервер
        serve_once(name);
        _exit(0);
    } else {
        // батьківський нічого корисного не робить
        // штучна затримка, щоб встигнути зробити запит
        sleep(1);
        // можна завершуватись
    }
    return 0;
}
