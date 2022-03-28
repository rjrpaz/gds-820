#include <stdlib.h>
#include <malloc.h>

#define CR 13
#define LF 10
#define MAXLINE 4096
#define SERVER_PORT 1234

#define TRUE 1
#define FALSE 0

#define LOGERROR "/var/log/gds820.error.log"

#define ERROR -1

#define END_LINE 0x0

void error_log (char *message, char *linea);

int bps (char *baudrate);

