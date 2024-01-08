#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <unistd.h>

#define PORT 12345

int main() {
    // Create UDP sockets for clientA and clientB
    int serversock;
    if ((serversock = socket(AF_INET, SOCK_DGRAM, 0)) == -1 ) {
        perror("Socket creation failed");
        exit(1);
    }

    // Server address configuration for clientA
    struct sockaddr_in server_addr_A;
    memset(&server_addr_A, 0, sizeof(server_addr_A));
    server_addr_A.sin_family = AF_INET;
    server_addr_A.sin_port = htons(PORT);
    server_addr_A.sin_addr.s_addr = INADDR_ANY;


    // Bind sockets to server addresses
    if (bind(serversock, (struct sockaddr *)&server_addr_A, sizeof(server_addr_A)) == -1) {
        perror("Binding failed");
        exit(1);
    }

    printf("Server listening on ports %d (clientA)...\n", PORT);

    struct sockaddr_in clientA_addr, clientB_addr;
    socklen_t clientA_len = sizeof(clientA_addr), clientB_len = sizeof(clientB_addr);

    while (1) {
        char decisionA[256], decisionB[256];

        // Receive decision from clientA
        int bytes_received_A = recvfrom(serversock, decisionA, sizeof(decisionA), 0, (struct sockaddr *)&clientA_addr, &clientA_len);
        decisionA[bytes_received_A] = '\0';
        if (bytes_received_A < 0) {
            perror("Receive error");
        }
        // Receive decision from clientB
        int bytes_received_B = recvfrom(serversock, decisionB, sizeof(decisionB), 0, (struct sockaddr *)&clientB_addr, &clientB_len);
        decisionB[bytes_received_B] = '\0';
        if (bytes_received_B < 0) {
            perror("Receive error");
        }
        // Determine the result
        int result1,result2;
        if (strcmp(decisionA, decisionB) == 0) {
            result1= 0; // Draw
            result2= 0;
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
        int k=sendto(serversock, &result1, sizeof(result1), 0, (struct sockaddr *)&clientA_addr, clientA_len);
        if (k == -1) {
                    perror("Send error");
        }
        k=sendto(serversock, &result2, sizeof(result2), 0, (struct sockaddr *)&clientB_addr, clientB_len);
        if (k == -1) {
                    perror("Send error");
        }

        // Receive play-again decision from both clients
        char play_again_A, play_again_B;
        ssize_t bytesReceived =recvfrom(serversock, &play_again_A, sizeof(play_again_A), 0, (struct sockaddr *)&clientA_addr, &clientA_len);
         if (bytesReceived < 0) {
            perror("Receive error");
        }
        bytesReceived =recvfrom(serversock, &play_again_B, sizeof(play_again_B), 0, (struct sockaddr *)&clientB_addr, &clientB_len); 
        if (bytesReceived < 0) {
            perror("Receive error");
        }
        int result=1;
        // Determine if both clients want to play again
        if ((play_again_A == 'n' || play_again_A == 'N') || (play_again_B == 'n' || play_again_B == 'N')) {
            result=0;
            k=sendto(serversock, &result, sizeof(result), 0, (struct sockaddr *)&clientA_addr, clientA_len);
            if (k == -1) {
                    perror("Send error");
        }
            k=sendto(serversock, &result, sizeof(result), 0, (struct sockaddr *)&clientB_addr, clientB_len);
            if (k == -1) {
                    perror("Send error");
        }
            break; // Exit the loop if both clients don't want to play again
        }
        else{
        result=1;
        k=sendto(serversock, &result, sizeof(result), 0, (struct sockaddr *)&clientA_addr, clientA_len);
        if (k == -1) {
                    perror("Send error");
        }
        k=sendto(serversock, &result, sizeof(result), 0, (struct sockaddr *)&clientB_addr, clientB_len);
        if (k == -1) {
                    perror("Send error");
        }
        }
        
    }

    close(serversock);
    return 0;
}
