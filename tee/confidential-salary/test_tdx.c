#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/types.h>
#include <string.h>
#include <errno.h>

// TDX Guest IOCTL definitions
#define TDX_CMD_GET_REPORT0 _IOWR('T', 1, struct tdx_report_req)

struct tdx_report_req {
    __u8 reportdata[64];
    __u8 tdreport[1024];
};

int main() {
    int fd;
    struct tdx_report_req req;
    
    printf("Opening /dev/tdx_guest...\n");
    fd = open("/dev/tdx_guest", O_RDWR);
    if (fd < 0) {
        printf("Failed to open device: %s\n", strerror(errno));
        return 1;
    }
    printf("Device opened successfully (fd=%d)\n", fd);
    
    // Prepare report request
    memset(&req, 0, sizeof(req));
    strcpy((char*)req.reportdata, "test_nonce");
    
    printf("Attempting TDX_CMD_GET_REPORT0 ioctl...\n");
    if (ioctl(fd, TDX_CMD_GET_REPORT0, &req) < 0) {
        printf("IOCTL failed: %s (errno=%d)\n", strerror(errno), errno);
        close(fd);
        return 1;
    }
    
    printf("IOCTL succeeded! TD Report obtained.\n");
    printf("First 16 bytes of report: ");
    for (int i = 0; i < 16; i++) {
        printf("%02x ", req.tdreport[i]);
    }
    printf("\n");
    
    close(fd);
    return 0;
}