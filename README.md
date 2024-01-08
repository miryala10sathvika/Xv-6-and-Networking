1)
1. the typical TCP connection has initial sequence number generated randomly,but here in the implementation it always starts with 0.
2. The acknowledgement is sent with number of byte it want to have next.
3. here every thing is decided by packet number.In the TCP connection , the retransmission is sent by 3 or 6 seconds ,here it is 0.1 seconds
4. In the tcp it has in header with 32 bits dedicated to it and it frequently changes the ISN to avoid hacking of the data.
5. Data sequencing in the TCP is done by byte sequence numbers by receiving the data, then by printing the whole.However it idetifies by byte sequence and retransmits the data.
6. If multiple times retransmission takes place, it is going to change the window size but it doesn't happen here.
7. It is using a wide range of bits to track all this in its header like RST,SYN,FYN but here we are only using a single sequence number.
8. The error debugging there is identified easily by byte numbers which is vey hard here.Here the implementation takes in always fixed number bytes , but in TCP change of window size after multiple    		 retransmissions is very Advanced and efficient.
9. the retranmission is estimated in TCP by RTT and corresponding some measures which is not done here (predefined).

2)
1. Here we can implement the flow control by adding the window size in the header(struct) to track the receiver's data processing speed.
2. We can implement like this,Initially we send a initial setup packet with zero data to send a suitable window size.
3. When the receiver receives it it sends the suitable data again by changing the window size according to some heuristics or it's previous processing speed.
4. When sender receives it, it changes its window size according to that and starts sending the data.
5. When the sender acknowledges too many retranmissions for the same packet ,it decreases it to half and starts retransmission,transmission of the data.
6. If the receiver still cannot process it and doesn't send any acknowledgement it again decreases to half , thus the process continues.
7. When the connection stabilises that mean it is receiving less retransissions or no retransmission it increases it by 0.2 or 0.3 percent of (window size) and thus go on.
8. To implement it we need to track the retransmissions by a counter variable and the window size by storing it and dynamically changing them according to traffic.
9. We can predefine a fixed number based on type of device and later on alter dynamically according to its processing of data.
10. When it sends zero we can just stop sending for some time and then decrease window size and then start sending them.  
11. The another primitive way is known as "STOP AND WAIT" which is typically done in the process where the sender sends the data continuously and receiver starts processing it, it sends acknowledgement to the sender with the byte number till which it can process the data.
  
qr

