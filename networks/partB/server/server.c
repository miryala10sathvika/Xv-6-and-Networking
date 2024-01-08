#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <stdbool.h>
#include <errno.h>
#include <sys/time.h>
#include <sys/select.h>

#define PORT 12345
#define BUFFER_SIZE 10000
#define CHUNK_SIZE 250
#define FILENAME "stored_data.txt"
#define TIMEOUT_SEC 0
#define TIMEOUT_USEC 10000000

// Struct for received chunks with sequence numbers
struct ReceivedChunk {
    int sequence_number;
    int complete;
    char data[CHUNK_SIZE];
};
struct AckPacket {
    int sequence_number;
};
void handle_error(const char *message) {
    perror(message);
    exit(EXIT_FAILURE);
}

// Function to append data to the file with correct ordering
// Function to append data to the file with correct ordering
void append_ordered_data(FILE *file, struct ReceivedChunk *received_chunk) {
    // Open a temporary file to store the reordered data
    FILE *temp_file = fopen("temp.txt", "w+");
    if (temp_file == NULL) {
        handle_error("Temporary file opening failed");
    }

    // Copy the received data to the temporary file in the correct order
    char buffer[BUFFER_SIZE];
    int current_sequence = 0;

    while (true) {
        fseek(file, 0, SEEK_SET);
        bool inserted = false;

        while (fgets(buffer, sizeof(buffer), file) != NULL) {
            int sequence;
            char data[CHUNK_SIZE];

            // Parse sequence number and data manually
            if (sscanf(buffer, "%d:", &sequence) == 1) {
                const char *data_start = strchr(buffer, ':');
                if (data_start != NULL) {
                    data_start++; // Move past the ':'
                    strcpy(data, data_start);
                }

                if (sequence == current_sequence) {
                    fprintf(temp_file, "%d:%s\n", sequence, data);
                    current_sequence++;

                    // Check if the received_chunk should be inserted here
                    if (received_chunk->sequence_number == current_sequence) {
                        fprintf(temp_file, "%d:%s\n", received_chunk->sequence_number, received_chunk->data);
                        current_sequence++;
                        inserted = true;
                    }
                } else {
                    fprintf(temp_file, "%d:%s\n", sequence, data);
                }
            }
        }
        // If received_chunk hasn't been inserted yet, append it now
        if (!inserted && received_chunk->sequence_number == current_sequence) {
            fprintf(temp_file, "%d:%s\n", received_chunk->sequence_number, received_chunk->data);
            current_sequence++;
        }
        // Check if all data has been processed
        if (received_chunk->complete == 1 || current_sequence > received_chunk->sequence_number) {
            break;
        }
    }
    // Close and rename the temporary file to the original file
    fclose(temp_file);
    remove(FILENAME);
    rename("temp.txt", FILENAME);
}

int main() {
    int sockfd;
    struct sockaddr_in server_addr, client_addr;
    socklen_t addr_len = sizeof(client_addr);
    struct ReceivedChunk received_chunk, send_chunk;
    FILE *file = NULL;
    int received_count = 0;

    // Create UDP socket
    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
        handle_error("Socket creation failed");
    }

    // Initialize server address
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    server_addr.sin_addr.s_addr = INADDR_ANY;

    // Bind socket to server address
    if (bind(sockfd, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1) {
        handle_error("Binding failed");
    }

    printf("UDP server is running on port %d...\n", PORT);

    while (true) {
        // Receive a packet from the client
        ssize_t recv_len = recvfrom(sockfd, &received_chunk, sizeof(received_chunk), 0, (struct sockaddr *)&client_addr, &addr_len);
        received_count++;
        if (recv_len == -1) {
            handle_error("Receive error");
        } else {
            struct AckPacket ack;
            ack.sequence_number = received_chunk.sequence_number;
            if (sendto(sockfd, &ack, sizeof(ack), 0, (struct sockaddr *)&client_addr, addr_len) == -1) {
                handle_error("ACK Send error");
            }
            
                if (file == NULL) {
                    // Open the file for appending and reading
                    file = fopen(FILENAME, "a+");
                    if (file == NULL) {
                        handle_error("File opening failed");
                    }
                }
                // Append the received data to the file with correct ordering
                append_ordered_data(file, &received_chunk);

                // Close the file to flush changes
                fclose(file);
                file = NULL;
                if (received_chunk.complete == 1) {
                // Reopen the file in read mode
                file = fopen(FILENAME, "r");
                    if (file == NULL) {
                        perror("File opening failed");
                        return 1; // Return an error code
                    }
                    printf("Received response from client\n");
                    // Print the entire file as a single continuous text
                    char buffer[BUFFER_SIZE];
                    while (fgets(buffer, sizeof(buffer), file) != NULL) {
                        char* colon_ptr = strchr(buffer, ':');
                        if (colon_ptr != NULL) {
                            printf("%s", colon_ptr + 1);
                        }
                    }
                    // Close the file after reading
                    fclose(file);
                    file = NULL;

                }
              if (received_chunk.complete == 1) {
                // Erase the total data from the file
                file = fopen(FILENAME, "w"); // Use "w" to truncate the file
                if (file == NULL) {
                    handle_error("File opening failed");
                }
                fclose(file);
                file = NULL;
            }
        }

        // Check for messages to send to the client
        if (received_chunk.complete == 1) {
            char input_buffer[BUFFER_SIZE];
            printf("Enter message to send to the client (or type 'exit' to quit): ");
            if (fgets(input_buffer, sizeof(input_buffer), stdin) != NULL) {
                if (strncmp(input_buffer, "exit", 4) == 0) {
                    printf("Exiting...\n");
                    break;
                }
                int total_chunks = strlen(input_buffer) / CHUNK_SIZE;
                if (strlen(input_buffer) % CHUNK_SIZE != 0) {
                    total_chunks++;
                }
                struct timeval start_time, current_time;
                gettimeofday(&start_time, NULL);
                current_time = start_time;
                int sent_chunks = 0; // Number of chunks sent
                int acked_chunks = 0; // Number of chunks acknowledged
                while (acked_chunks < total_chunks) {
                    // Check for acknowledgment
                    if (sent_chunks >= acked_chunks) {
                        // We have sent more chunks than acknowledged, check for ACK
                        struct timeval timeout;
                        timeout.tv_sec = TIMEOUT_SEC;
                        timeout.tv_usec = TIMEOUT_USEC;

                        fd_set read_fds;
                        FD_ZERO(&read_fds);
                        FD_SET(sockfd, &read_fds);

                        int select_result;
                        while (true) {
                            // Check for ACK or timeout
                            while (sent_chunks < total_chunks) {
                                send_chunk.sequence_number = sent_chunks;
                                send_chunk.complete = (sent_chunks == total_chunks - 1) ? 1 : 0;
                                strncpy(send_chunk.data, input_buffer + sent_chunks * CHUNK_SIZE, CHUNK_SIZE);
                                if (sendto(sockfd, &send_chunk, sizeof(send_chunk), 0, (struct sockaddr *)&client_addr, addr_len) == -1) {
                                    handle_error("Send error");
                                }
                                sent_chunks++;
                            }
                            select_result = select(sockfd + 1, &read_fds, NULL, NULL, &timeout);
                            if (select_result == -1) {
                                handle_error("Select error");
                            } else if (select_result == 0) {
                                // Timeout: No ACK received, need to retransmit the earliest unacknowledged chunk
                                send_chunk.sequence_number = acked_chunks;
                                send_chunk.complete = (acked_chunks == total_chunks - 1) ? 1 : 0;
                                strncpy(send_chunk.data, input_buffer + acked_chunks * CHUNK_SIZE, CHUNK_SIZE);
                                if (sendto(sockfd, &send_chunk, sizeof(send_chunk), 0, (struct sockaddr *)&client_addr, addr_len) == -1) {
                                    handle_error("Send error");
                                }
                            } else {
                                // ACK received, process it
                                struct AckPacket ack;
                                ssize_t ack_len = recvfrom(sockfd, &ack, sizeof(ack), 0, NULL, NULL);
                                if (ack_len == -1) {
                                    handle_error("ACK Receive error");
                                } else {
                                    // Check if the ACK corresponds to the current chunk
                                    if (ack.sequence_number == acked_chunks) {
                                        acked_chunks++;
                                        break; // Move on to the next chunk
                                    }
                                }
                            }
                        }
                    }
                    // Send new chunks as long as there are unsent chunks
                    while (sent_chunks < total_chunks) {
                        send_chunk.sequence_number = sent_chunks;
                        send_chunk.complete = (sent_chunks == total_chunks - 1) ? 1 : 0;
                        strncpy(send_chunk.data, input_buffer + sent_chunks * CHUNK_SIZE, CHUNK_SIZE);
                        if (sendto(sockfd, &send_chunk, sizeof(send_chunk), 0, (struct sockaddr *)&client_addr, addr_len) == -1) {
                            handle_error("Send error");
                        }
                        sent_chunks++;
                    }
                    // Check the time to avoid busy-waiting
                    gettimeofday(&current_time, NULL);
                    if ((current_time.tv_sec - start_time.tv_sec) * 1000000 + (current_time.tv_usec - start_time.tv_usec) >= TIMEOUT_USEC) {
                        break; // Exit the loop if the timeout has elapsed
                    }
                }
            }
        }
    }
    // Close the file if it's open
    if (file != NULL) {
        fclose(file);
    }
    // Close the socket
    close(sockfd);
    return 0;
}
