#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <linux/can.h>
#include <linux/can/raw.h>

int main() {
    int s;
    struct sockaddr_can addr;
    struct ifreq ifr;
    struct can_frame frame;
    
    // 创建套接字
    s = socket(PF_CAN, SOCK_RAW, CAN_RAW);
    
    strcpy(ifr.ifr_name, "can1");
    ioctl(s, SIOCGIFINDEX, &ifr);
    
    addr.can_family = AF_CAN;
    addr.can_ifindex = ifr.ifr_ifindex;
    
    bind(s, (struct sockaddr *)&addr, sizeof(addr));
    
    // 设置接收超时
    struct timeval tv = {1, 0}; // 1秒
    setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
    
    // 发送 CAN 帧
    frame.can_id = 0x123;
    frame.can_dlc = 8;
    memset(frame.data, 0xAA, 8);
    write(s, &frame, sizeof(frame));
    
    // 接收 CAN 帧
    while(1) {
        int nbytes = read(s, &frame, sizeof(frame));
        if(nbytes > 0) {
            printf("收到帧 ID: 0x%X 数据: ", frame.can_id);
            for(int i = 0; i < frame.can_dlc; i++)
                printf("%02X ", frame.data[i]);
            printf("\n");
        }
    }
    
    close(s);
    return 0;
}
