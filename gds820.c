#include <termios.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <signal.h>
#include "gds820.h"


void error_log (char *message, char *linea)
{
	FILE *errorfd;
	/**************************************\
	* Abre archivo de log para los errores *
	\**************************************/

	errorfd = fopen(LOGERROR, "a");
	if (errorfd <0) 
	{
		perror(LOGERROR); 
	}

	setvbuf(errorfd, message, _IONBF, 0);
	fwrite(message, strlen(message), 1, errorfd);
	fwrite(" en la linea: ", 14, 1, errorfd);
	fwrite(linea, strlen(linea), 1, errorfd);
	fwrite("\n", 1, 1, errorfd);
	fflush(errorfd);
	fclose (errorfd);
}


int bps (char *baudrate)
{
	if (strcmp(baudrate, "38400") == 0) return B38400;
	else if (strcmp(baudrate, "19200") == 0) return B19200;
	else if (strcmp(baudrate, "9600") == 0) return B9600;
	else if (strcmp(baudrate, "4800") == 0) return B4800;
	else if (strcmp(baudrate, "2400") == 0) return B2400;
	else if (strcmp(baudrate, "1200") == 0) return B1200;
	else if (strcmp(baudrate, "600") == 0) return B600;
	else if (strcmp(baudrate, "300") == 0) return B300;
	else
	{
		return B1200;
	}
}


int read_line(int newSd, char *line_to_return)
{
	static int rcv_ptr=0;
	static char rcv_msg[MAXLINE];
	static int n;
	int offset;

	offset=0;

	while (1)
	{
		if (rcv_ptr == 0)
		{
			/*
			 * Leo datos del socket
			 */
			memset(rcv_msg,0x0,MAXLINE);
			/*
			 * Espero por datos que lleguen
			 */
			n = recv(newSd, rcv_msg, MAXLINE, 0);
			if (n < 0)
			{
				perror("No puedo recibir datos del cliente");
				return ERROR;
			}
			else if (n == 0)
			{
				close(newSd);
				return ERROR;
			}
		}

		/*
		 * Si se leyo un nuevo dato en el socket, o
		 * si otra linea esta todavia en el buffer,
		 * copia la linea en 'line_to_return'
		 */
		while (*(rcv_msg+rcv_ptr) != END_LINE && rcv_ptr < n)
		{
			memcpy(line_to_return+offset,rcv_msg+rcv_ptr,1);
			offset++;
			rcv_ptr++;
		}
 
		/*
		 * Fin de linea + Fin de buffer => devolver linea
		 */
		if (rcv_ptr == n-1)
		{
			/*
			 * Escribe END_LINE en el ultimo byte
			 */
			*(line_to_return+offset)=END_LINE;
			rcv_ptr=0;
			return ++offset;
		} 
 
		/*
		 * Si llegamos a final de linea pero todavia
		 * existen datos en el buffer => devolver linea
		 */
		if (rcv_ptr <n-1)
		{
			/*
			 * Escribe END_LINE en el ultimo byte
			 */
			*(line_to_return+offset) = END_LINE;
			rcv_ptr++;
			return ++offset;
		}

		/*
		 * Se llego al final del buffer pero no al
		 * final de linea => esperar por mas datos
		 * que lleguen por el socket
		 */
		if (rcv_ptr == n)
		{
			rcv_ptr = 0;
		} 
	} /* while (1) */
}


int tiene_respuesta (char *comando)
{
	if (
		(strcmp(comando, "*IDN?") == 0) ||
		(strcmp(comando, "*ESE?") == 0) ||
		(strcmp(comando, "*LRN?") == 0) ||
		(strcmp(comando, "*OPC?") == 0) ||
		(strcmp(comando, "*SRE?") == 0) ||
		(strcmp(comando, "*STB?") == 0) ||
		(strcmp(comando, ":ACQUIRE:AVERAGE?") == 0) ||
		(strcmp(comando, ":ACQUIRE:MODE?") == 0) ||
		(strcmp(comando, ":ACQUIRE1:MEMORY?") == 0) ||
		(strcmp(comando, ":ACQUIRE2:MEMORY?") == 0) ||
		(strcmp(comando, ":ACQUIRE1:POINT?") == 0) ||
		(strcmp(comando, ":ACQUIRE2:POINT?") == 0) ||
		(strcmp(comando, ":CHANNEL1:BWLIMIT?") == 0) ||
		(strcmp(comando, ":CHANNEL2:BWLIMIT?") == 0) ||
		(strcmp(comando, ":CHANNEL1:COUPLING?") == 0) ||
		(strcmp(comando, ":CHANNEL2:COUPLING?") == 0) ||
		(strcmp(comando, ":CHANNEL1:DISPLAY?") == 0) ||
		(strcmp(comando, ":CHANNEL2:DISPLAY?") == 0) ||
		(strcmp(comando, ":CHANNEL1:INVERT?") == 0) ||
		(strcmp(comando, ":CHANNEL2:INVERT?") == 0) ||
		(strcmp(comando, ":CHANNEL1:OFFSET?") == 0) ||
		(strcmp(comando, ":CHANNEL2:OFFSET?") == 0) ||
		(strcmp(comando, ":CHANNEL1:PROBE?") == 0) ||
		(strcmp(comando, ":CHANNEL2:PROBE?") == 0) ||
		(strcmp(comando, ":CHANNEL1:SCALE?") == 0) ||
		(strcmp(comando, ":CHANNEL2:SCALE?") == 0) ||
		(strcmp(comando, ":CURSOR:SOURCE?") == 0) ||
		(strcmp(comando, ":CURSOR:X1POSITION?") == 0) ||
		(strcmp(comando, ":CURSOR:X2POSITION?") == 0) ||
		(strcmp(comando, ":CURSOR:XDELTA?") == 0) ||
		(strcmp(comando, ":CURSOR:XDISPLAY?") == 0) ||
		(strcmp(comando, ":CURSOR:Y1POSITION?") == 0) ||
		(strcmp(comando, ":CURSOR:Y2POSITION?") == 0) ||
		(strcmp(comando, ":CURSOR:YDELTA?") == 0) ||
		(strcmp(comando, ":CURSOR:YDISPLAY?") == 0) ||
		(strcmp(comando, ":DISPLAY:ACCUMULATE?") == 0) ||
		(strcmp(comando, ":DISPLAY:CONTRAST?") == 0) ||
		(strcmp(comando, ":DISPLAY:GRATICULE?") == 0) ||
		(strcmp(comando, ":DISPLAY:WAVEFORM?") == 0) ||
		(strcmp(comando, ":MEASURE:FALL?") == 0) ||
		(strcmp(comando, ":MEASURE:FREQUENCY?") == 0) ||
		(strcmp(comando, ":MEASURE:NWIDTH?") == 0) ||
		(strcmp(comando, ":MEASURE:PDUTY?") == 0) ||
		(strcmp(comando, ":MEASURE:PERIOD?") == 0) ||
		(strcmp(comando, ":MEASURE:PWIDTH?") == 0) ||
		(strcmp(comando, ":MEASURE:RISE?") == 0) ||
		(strcmp(comando, ":MEASURE:VAMPLITUDE?") == 0) ||
		(strcmp(comando, ":MEASURE:VAVERAGE?") == 0) ||
		(strcmp(comando, ":MEASURE:VHI?") == 0) ||
		(strcmp(comando, ":MEASURE:VLO?") == 0) ||
		(strcmp(comando, ":MEASURE:VMAX?") == 0) ||
		(strcmp(comando, ":MEASURE:VMIN?") == 0) ||
		(strcmp(comando, ":MEASURE:VPP?") == 0) ||
		(strcmp(comando, ":MEASURE:VRMS?") == 0) ||
		(strcmp(comando, ":TEMPLATE1:DOWNLOAD?") == 0) ||
		(strcmp(comando, ":TIMEBASE:DELAY?") == 0) ||
		(strcmp(comando, ":TIMEBASE:SCALE?") == 0) ||
		(strcmp(comando, ":TIMEBASE:SWEEP?") == 0) ||
		(strcmp(comando, ":TRIGGER:COUPLE?") == 0) ||
		(strcmp(comando, ":TRIGGER:LEVEL?") == 0) ||
		(strcmp(comando, ":TRIGGER:SLOP?") == 0) ||
		(strcmp(comando, ":TRIGGER:SOURCE?") == 0) ||
		(strcmp(comando, ":TRIGGER:TYPE?") == 0)
		)
	{
		return 1;
	}
	else if (
		(strncmp(comando, ":ACQUIRE:AVERAGE ", 17) == 0) ||
		(strncmp(comando, ":ACQUIRE:MODE ", 14) == 0) ||
		(strncmp(comando, ":CHANNEL1:BWLIMIT ", 18) == 0) ||
		(strncmp(comando, ":CHANNEL2:BWLIMIT ", 18) == 0) ||
		(strncmp(comando, ":CHANNEL1:COUPLING ", 19) == 0) ||
		(strncmp(comando, ":CHANNEL2:COUPLING ", 19) == 0) ||
		(strncmp(comando, ":CHANNEL1:DISPLAY ", 18) == 0) ||
		(strncmp(comando, ":CHANNEL2:DISPLAY ", 18) == 0) ||
		(strncmp(comando, ":CHANNEL1:INVERT ", 17) == 0) ||
		(strncmp(comando, ":CHANNEL2:INVERT ", 17) == 0) ||
		(strncmp(comando, ":CHANNEL1:MATH ", 15) == 0) ||
		(strncmp(comando, ":CHANNEL2:MATH ", 15) == 0) ||
		(strncmp(comando, ":CHANNEL1:OFFSET ", 17) == 0) ||
		(strncmp(comando, ":CHANNEL2:OFFSET ", 17) == 0) ||
		(strncmp(comando, ":CHANNEL1:PROBE ", 16) == 0) ||
		(strncmp(comando, ":CHANNEL2:PROBE ", 16) == 0) ||
		(strncmp(comando, ":CHANNEL1:SCALE ", 16) == 0) ||
		(strncmp(comando, ":CHANNEL2:SCALE ", 16) == 0) ||
		(strncmp(comando, ":CURSOR:SOURCE ", 15) == 0) ||
		(strncmp(comando, ":CURSOR:X1POSITION ", 19) == 0) ||
		(strncmp(comando, ":CURSOR:X2POSITION ", 19) == 0) ||
		(strncmp(comando, ":CURSOR:XDISPLAY ", 17) == 0) ||
		(strncmp(comando, ":CURSOR:Y1POSITION ", 19) == 0) ||
		(strncmp(comando, ":CURSOR:Y2POSITION ", 19) == 0) ||
		(strncmp(comando, ":CURSOR:YDISPLAY ", 17) == 0) ||
		(strncmp(comando, ":DISPLAY:ACCUMULATE ", 20) == 0) ||
		(strncmp(comando, ":DISPLAY:CONTRAST ", 18) == 0) ||
		(strncmp(comando, ":DISPLAY:GRATICULE ", 19) == 0) ||
		(strncmp(comando, ":DISPLAY:WAVEFORM ", 18) == 0) ||
		(strncmp(comando, ":MEASURE:SOURCE ", 16) == 0) ||
		(strncmp(comando, ":TIMEBASE:DELAY ", 16) == 0) ||
		(strncmp(comando, ":TIMEBASE:SCALE ", 16) == 0) ||
		(strncmp(comando, ":TIMEBASE:SWEEP ", 16) == 0) ||
		(strncmp(comando, ":TRIGGER:COUPLE ", 16) == 0) ||
		(strncmp(comando, ":TRIGGER:LEVEL ", 15) == 0) ||
		(strncmp(comando, ":TRIGGER:SLOP ", 14) == 0) ||
		(strncmp(comando, ":TRIGGER:SOURCE ", 16) == 0) ||
		(strncmp(comando, ":TRIGGER:TYPE ", 14) == 0)
		)
	{
		return 0;
	}
	else
	{
		return -1;
	}
}


void signal_alarm(int s)
{
	/* Reprogramamos el signal */
//	signal(SIGALRM, signal_alarm);

	/* Reprogramamos la alarma para dentro de 3 segundos */
	_exit (EXIT_FAILURE);
}


void pr_exit (int status)
{
//	char *cadena = "";
	if (WIFEXITED(status))
	{
//		printf("El proceso finalizo correctamente con codigo: %d\n", WEXITSTATUS(status));
		;
	}
	else if (WIFSIGNALED(status))
	{
		printf("El proceso finalizo de manera anormal, numero de senal: %d\n", WTERMSIG(status));
	}
	else if (WIFSTOPPED(status))
	{
		printf("El proceso hijo se detuvo, numero de senal: %d\n", WSTOPSIG(status));
	}
}

