#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>  // Include the <unistd.h> header for the close() function

#define PORT 12345
#define MAX_BUFFER_SIZE 1024
void handle_error(const char *message) {
    perror(message);
    exit(1);
}
int main() {
    int sockfd;
    struct sockaddr_in serverAddr, clientAddr;
    socklen_t addr_size;
    char buffer[MAX_BUFFER_SIZE];

    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) {
        handle_error("Socket creation error");
    }

    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons(PORT);
    // Convert and check the port number
    int port = PORT;
    if ((serverAddr.sin_port = htons(port)) == 0) {
        perror("Port conversion error");
        close(sockfd);  // Close the socket before exiting
        exit(1);
    }
    serverAddr.sin_addr.s_addr = INADDR_ANY;

    if (bind(sockfd, (struct sockaddr*)&serverAddr, sizeof(serverAddr)) < 0) {
        handle_error("Binding error");
        
    }

    printf("Server is listening on port %d...\n", PORT);

    while (1) {
        addr_size = sizeof(clientAddr);
         if (memset(buffer, 0, sizeof(buffer)) == NULL) {
            perror("Buffer memset error");
            close(sockfd);  // Close the socket before exiting
            exit(1);
        }

        // Receive a text message from the client
        ssize_t bytesReceived = recvfrom(sockfd, buffer, sizeof(buffer), 0, (struct sockaddr*)&clientAddr, &addr_size);
        if (bytesReceived < 0) {
            handle_error("Receive error");
        }

        // Send a response message back to the client
        ssize_t bytesSent = sendto(sockfd, buffer, strlen(buffer), 0, (struct sockaddr*)&clientAddr, addr_size);
        if (bytesSent < 0) {
            handle_error("Send error");
        }
        if (bytesSent != strlen(buffer)) {
            handle_error("Send error");
        }
    }

    // Close the socket when done
    if(close(sockfd) == -1) {
        handle_error("close");
    }
    return 0;
}