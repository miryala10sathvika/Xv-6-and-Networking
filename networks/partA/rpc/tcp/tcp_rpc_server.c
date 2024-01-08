#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <unistd.h>

#define PORT 12345

int main() {
    // Create TCP socket
    int server_socket;
    if ((server_socket = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
        perror("Socket creation failed");
        exit(1);
    }

    // Server address configuration
    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    server_addr.sin_addr.s_addr = INADDR_ANY;

    // Bind socket to server address
    if (bind(server_socket, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1) {
        perror("Binding failed");
        exit(1);
    }

    // Listen for incoming connections
    if (listen(server_socket, 2) == -1) {
        perror("Listening failed");
        exit(1);
    }

    printf("Server listening on port %d...\n", PORT);

    struct sockaddr_in clientA_addr, clientB_addr;
    socklen_t clientA_len = sizeof(clientA_addr), clientB_len = sizeof(clientB_addr);
    int clientA_socket, clientB_socket;
        clientA_socket = accept(server_socket, (struct sockaddr *)&clientA_addr, &clientA_len);
        clientB_socket = accept(server_socket, (struct sockaddr *)&clientB_addr, &clientB_len);
        if (clientB_socket < 0) {
            perror("Accept error");
        }
        if (clientA_socket < 0) {
            perror("Accept error");
        }

    while (1) {
        // Accept connections from clientA and clientB

        char decisionA[256], decisionB[256];

        // Receive decision from clientA
        int bytes_received_A = recv(clientA_socket, decisionA, sizeof(decisionA), 0);
        decisionA[bytes_received_A] = '\0';
         if (bytes_received_A < 0) {
                perror("Receive error");
            }
         
        // Receive decision from clientB
        int bytes_received_B = recv(clientB_socket, decisionB, sizeof(decisionB), 0);
        decisionB[bytes_received_B] = '\0';
        if (bytes_received_B < 0) {
                perror("Receive error");
            }
        // Determine the result
        int result1, result2;
        if (strcmp(decisionA, decisionB) == 0) {
            result1 = 0; // Draw
            result2 = 0;
        } else if ((strcmp(decisionA, "Rock") == 0 && strcmp(decisionB, "Scissors") == 0) ||
                   (strcmp(decisionA, "Paper") == 0 && strcmp(decisionB, "Rock") == 0) ||
                   (strcmp(decisionA, "Scissors") == 0 && strcmp(decisionB, "Paper") == 0)) {
            result1 = 1;
            result2 = 2; // clientA wins
        } else {
            result2 = 1;
            result1 = 2; // clientB wins
        }

        // Send the result to both clients
        int k=send(clientA_socket, &result1, sizeof(result1), 0);
        if (k<0 ) {
                perror("Send error interrupt.");
        }
        k=send(clientB_socket, &result2, sizeof(result2), 0);
        if (k<0 ) {
                perror("Send error interrupt.");
        }
        // Receive play-again decision from both clients
        char play_again_A, play_again_B;
        int bytes_received=recv(clientA_socket, &play_again_A, sizeof(play_again_A), 0);
        if (bytes_received < 0) {
                perror("Receive error");
            }
        bytes_received=recv(clientB_socket, &play_again_B, sizeof(play_again_B), 0);
        if (bytes_received < 0) {
                perror("Receive error");
            }
        // Determine if both clients want to play again
        if ((play_again_A == 'n' || play_again_A == 'N') || (play_again_B == 'n' || play_again_B == 'N')) {
            int result = 0;
            k=send(clientA_socket, &result, sizeof(result), 0);
            if (k<0 ) {
                perror("Send error interrupt.");
        }
            k=send(clientB_socket, &result, sizeof(result), 0);
            if (k<0 ) {
                perror("Send error interrupt.");
        }
        } else {
            int result = 1;
            k=send(clientA_socket, &result, sizeof(result), 0);
            if (k<0 ) {
                perror("Send error interrupt.");
        }
            k=send(clientB_socket, &result, sizeof(result), 0);
            if (k<0 ) {
                perror("Send error interrupt.");
        }
        }
    }
        // Close the client sockets
         if(close(clientA_socket)) {
        perror("close");
    }
         if(close(clientB_socket)) {
        perror("close");
    }
     if(close(server_socket)) {
        perror("close");
    }
    return 0;
}
