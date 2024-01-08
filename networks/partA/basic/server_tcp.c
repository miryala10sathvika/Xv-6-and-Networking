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
    int sockfd, newsockfd;
    struct sockaddr_in serverAddr, clientAddr;
    socklen_t addr_size;
    char buffer[MAX_BUFFER_SIZE];

    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd == -1) {
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

    if (listen(sockfd, 5) < 0) {
        handle_error("Listening error");
        
    }

    printf("Server is listening on port %d...\n", PORT);

    while (1) {
        addr_size = sizeof(clientAddr);
        newsockfd = accept(sockfd, (struct sockaddr*)&clientAddr, &addr_size);
        if (newsockfd < 0) {
            handle_error("Accept error");
        }

        while (1) {
            memset(buffer, 0, sizeof(buffer));
            if (memset(buffer, 0, sizeof(buffer)) == NULL) {
            perror("Buffer memset error");
            close(sockfd);  // Close the socket before exiting
            exit(1);
        }

            // Receive a text message from the client
            ssize_t bytesReceived = recv(newsockfd, buffer, sizeof(buffer), 0);
            if (bytesReceived < 0) {
                handle_error("Receive error");
            }

            if (bytesReceived == 0) {
                // Client has closed the connection
                break;
            }
            strcpy(buffer,"Response received");
            // Send a response message back to the client
            ssize_t bytesSent = send(newsockfd, buffer, strlen(buffer), 0);
            if (bytesSent < 0) {
                handle_error("Send error");
               
            }
        }

        // Close the connection with the client
        if(close(newsockfd) == -1) {
        handle_error("close");
    }
    }
    if(close(sockfd) == -1) {
        handle_error("close");
    }
    return 0;
}
