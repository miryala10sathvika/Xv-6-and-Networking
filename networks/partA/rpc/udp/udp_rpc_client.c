#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <unistd.h>

#define SERVER_IP "127.0.0.1"
#define PORT 12345

int main() {
    // Create UDP socket
    int serversock;
    if ((serversock = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
        perror("Socket creation failed");
        exit(1);
    }

    // Server address configuration
    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT); // Connect to clientA's port initially
    server_addr.sin_addr.s_addr = inet_addr(SERVER_IP);

    char decision[256];

    while (1) {
        // Get user's decision
        printf("Enter your decision (Rock, Paper, Scissors): ");
        scanf("%s", decision);

        // Send decision to the server
        int k=sendto(serversock, decision, strlen(decision), 0, (struct sockaddr *)&server_addr, sizeof(server_addr));
        if (k == -1) {
                    perror("Send error");
        }
        // Receive the game result from the server
        int result;
        ssize_t bytesReceived = recvfrom(serversock, &result, sizeof(result), 0, NULL, NULL);
        if (bytesReceived < 0) {
            perror("Receive error");
        }
        //printf("%d to declare winner\n",result);
        // Display the result
        if (result == 0) {
            printf("It's a draw!\n");
        } else if (result == 1) {
            printf("You win!\n");
        } else {
            printf("You lose!\n");
        }

        // Prompt for another game
        char play_again;
        printf("Do you want to play again? (y/n): ");
        scanf(" %c", &play_again);
        // Send the play-again decision to the server
        k=sendto(serversock, &play_again, sizeof(play_again), 0, (struct sockaddr *)&server_addr, sizeof(server_addr));
        if (k == -1) {
                    perror("Send error");
        }
        bytesReceived =recvfrom(serversock, &result, sizeof(result), 0, NULL, NULL);
        if (bytesReceived < 0) {
            perror("Receive error");
        }
        //printf("%d to play again\n",result);
        if ((play_again == 'n' || play_again == 'N') || result==0) {
            break;
        }
    }
     if(close(serversock) == -1) {
        perror("close");
    }
    return 0;
}
