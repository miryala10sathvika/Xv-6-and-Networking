#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

#define SERVER_IP "127.0.0.1"  // Change this to the server's IP address
#define PORT 12345
#define MAX_BUFFER_SIZE 1024
void handle_error(const char *message) {
    perror(message);
}
int main() {
    int sockfd;
    struct sockaddr_in serverAddr;
    char buffer[MAX_BUFFER_SIZE];

    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) {
        handle_error("Socket creation error");
    }

    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons(PORT);
    // Convert and check the port number
    int port = PORT;
    if ((serverAddr.sin_port = htons(port)) == 0) {
        handle_error("Port conversion error");
    }
    serverAddr.sin_addr.s_addr = inet_addr(SERVER_IP);  // Change to the server's IP address
    if (inet_pton(AF_INET, SERVER_IP, &serverAddr.sin_addr) <= 0) {
        handle_error("Invalid server address");
    }

    if (connect(sockfd, (struct sockaddr*)&serverAddr, sizeof(serverAddr)) < 0) {
        handle_error("Connection error");
    }

    while (1) {
        // Prompt user for a text message
        printf("Enter a message to send to the server: ");
        if (fgets(buffer, MAX_BUFFER_SIZE, stdin) == NULL) {   
            handle_error("Input error");
        }

        // Send the text message to the server
        int k=send(sockfd, buffer, strlen(buffer), 0);
        if ( k!= strlen(buffer)) {
                handle_error("Send error interrupt.Only some data is sent");
        }
        if (k<0 ) {
                handle_error("Send error interrupt.");
        }

        // Receive the response message from the server
        ssize_t bytesReceived = recv(sockfd, buffer, sizeof(buffer), 0);
        if (bytesReceived < 0) {
            handle_error("Receive error");
        }

        buffer[bytesReceived] = '\0';
        printf("Server response: %s\n", buffer);
    }
    if(close(sockfd) == -1) {
        handle_error("close");
    }
    return 0;
}
