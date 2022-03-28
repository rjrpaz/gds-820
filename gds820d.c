#include <termios.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <signal.h>
#include "gds820.h"

char pregunta[MAXLINE] = "*IDN?";
char respuesta[MAXLINE*4] = "";

char *logfile="/var/log/gds820.log", *device="/dev/ttyS1", *baudrate="38400";
char lf[10] = "\r\0";
char c;
int errorfd;
pid_t pid;
int status;
int hardware_control = FALSE;
int debug = FALSE;

/*
 * Funciones
 */
void usage(char *);
void procesar_opciones(int, char *[]);
int read_line();
int tiene_respuesta (char *);
void signal_alarm(int);
void pr_exit (int);
int daemon_init();

/*
 * Programa principal
 */
int main(int argc, char *argv[])
{
	int fd, sd, cantidad, cliLen, newSd;
	int contador, rc;
	FILE *logfd;
	struct termios oldtio, newtio;
	struct sockaddr_in servAddr, cliAddr;

	procesar_opciones(argc, argv);

	daemon_init();
	/*
	 * Abre el puerto en modo lectura-escritura, y no como una tty que
	 * controla al proceso, de esta forma no se muere si por una linea
	 * ruidosa llega una señal equivalente a CTRL-C.
	 */
	fd = open(device, O_RDWR | O_NOCTTY);
	if (fd <0) 
	{
		perror(device); 
		exit(-1); 
	}
 
	/*
	 * Abre archivo de log
	 */
	logfd = fopen(logfile, "a");
	if (logfd <0) 
	{
		perror(logfile); 
		exit(EXIT_FAILURE); 
	}

	/*
	 * Guarda configuracion actual de la terminal
	 */
	tcgetattr(fd,&oldtio); 

	/*
	 * Configura el puerto con los siguientes parametros:
	 *
	 * velocidad en bps (definida por el usuario)
	 * control de flujo desde el hardware (definido por el usuario)
	 * 8 bits de palabra de datos
	 * Sin paridad
	 * 1 bit de stop
	 * Ademas, habilita la terminal para recibir caracteres
	 * newtio.c_cflag = BAUDRATE | CRTSCTS | CS8 | CLOCAL | CREAD;
	 */
	newtio.c_cflag = bps(baudrate) | CS8 | CLOCAL | CREAD;
	if (hardware_control == TRUE)
	{
		newtio.c_cflag |= CRTSCTS;
	}
 
	/*
	 * Ignora CR en la entrada
	 */
	newtio.c_iflag = 0;
 
	/*
	 * salida "raw"
	 */
	newtio.c_oflag = 0;
 
	/*
	 * No hace echo de caracteres y no genera señales
	 */
	newtio.c_lflag = 0;
 
	/*
	 * Bloquea la lectura hasta que un caracter llega por la linea
	 */
	newtio.c_cc[VMIN] = 1;
	newtio.c_cc[VTIME] = 0;
 
	/*
	 * Limpia la terminal y configura la misma con los valores
	 * previamente definidos
	 */
	tcflush(fd, TCIFLUSH);
	tcsetattr(fd,TCSANOW,&newtio);

	/*
	 * Crea el socket
	 */
	sd = socket(AF_INET, SOCK_STREAM, 0);
	if (sd < 0)
	{
		perror("No puedo abrir el socket");
		exit(EXIT_FAILURE);
	}

	/*
	 * Enlaza el socket a una direccion y puerto
	 */
	servAddr.sin_family = AF_INET;
	servAddr.sin_addr.s_addr = htonl(INADDR_ANY);
	servAddr.sin_port = htons(SERVER_PORT);

	if(bind(sd, (struct sockaddr *) &servAddr, sizeof(servAddr))<0)
	{
		perror("no puedo enlazar el puerto");
		exit(EXIT_FAILURE);
	}

	listen(sd,5);

	/*
	 * Genera un bucle infinito a la espera de conexiones
	 */
	while (1)
	{
		cliLen = sizeof(cliAddr);
		/*
		 * Se conecta un cliente
		 */
		newSd = accept(sd, (struct sockaddr *) &cliAddr, &cliLen);
		if (newSd < 0)
		{
			perror("No puedo aceptar conexion de un cliente");
			exit(EXIT_FAILURE);
		}

		/*
		 * Inicializa linea
		 */
		memset(pregunta,0x0,MAXLINE);
		memset(respuesta,0x0,MAXLINE*4);

		/*
		 * Lee el dato que le envia el cliente
		 */
		while (read_line(newSd,pregunta) != -1)
		{
			if (debug)
				printf("%s: recibido desde %s:%d : %s\n", argv[0], inet_ntoa(cliAddr.sin_addr), ntohs(cliAddr.sin_port), pregunta);
			/*
			 * Determina si el comando tiene respuesta o no.
			 *
			 * El comando SI tiene respuesta
			 */
			if (tiene_respuesta(pregunta))
			{
				if (debug)
					printf("Comando %s tiene respuesta\n", pregunta);
				/*
				 * Acomoda el comando para que sea compatible con IEEE 488.2
				 */
				cantidad = strlen(pregunta);
//				pregunta[cantidad] = LF;
//				pregunta[cantidad+1] = '\0';
				pregunta[cantidad - 1] = LF;
				pregunta[cantidad] = '\0';

				char pregunta_cortada[MAXLINE];
				memset(pregunta_cortada,0x0,MAXLINE);
				sprintf(pregunta_cortada, "%s", pregunta);
				pregunta_cortada[strlen(pregunta_cortada) - 1] = '\0';
				printf("MM%sNN\n", pregunta_cortada);
				printf("JJ%sKK\n", pregunta);

				fwrite(pregunta, strlen(pregunta), 1, logfd);
				fflush(logfd);
				if (debug)
					printf("==> %s", pregunta);

				/*
				 * Mediante un fork genera dos procesos, uno que
				 * escribira en el puerto y otro que leera del mismo.
				 */
				if ((pid = fork()) == -1)
				{
					perror("fork");
					exit (EXIT_FAILURE);
				}
				/*
				 * Proceso hijo: Lee en el puerto
				 */
				else if (pid == 0) /* if ((pid = fork()) == -1) */
				{
					/*
					 * Configura alarmas por posibles timeouts.
					 */
					signal(SIGALRM, signal_alarm);
					alarm(3);

					/*
					 * Lee la respuesta del osciloscopio
					 */
					contador = 0;
					int cantidad_de_comas = 0;
					int data_size_digit = 0;
					long int data_size = 0;

					union punto
					{
						char c[2];
						signed short int p;
					} punto_leido;

					char c_ant = 0;
					char buffer[6];
					while (read(fd,&c,1) > 0)
					{
						alarm(0);
						if (
							(strncmp(pregunta, ":ACQUIRE1:POINT", 15) == 0) ||
							(strncmp(pregunta, ":ACQUIRE2:POINT", 15) == 0) ||
							(strncmp(pregunta, ":ACQUIRE1:MEMORY", 16) == 0) ||
							(strncmp(pregunta, ":ACQUIRE2:MEMORY", 16) == 0)
						)
						{
							if ((contador == 0) && (c != '#'))
							{
								printf("Fallo en la respuesta al comando\n");
							}
							else if (contador == 1)
							{
								data_size_digit = c - 48;
							}
							else if ((contador >= 2) && (contador < (2 + data_size_digit)))
							{
								data_size = data_size * 10;
								data_size = data_size + (c - 48);
							}
							/*
							 * Todos los demas puntos los guarda como una cadena
							 */
							else if (contador > (2 + data_size_digit + 8))
							{
								if (((contador - (2 + data_size_digit + 8)) % 2) == 1)
								{
									punto_leido.c[0] = c;
									punto_leido.c[1] = c_ant;
									memset(buffer, 0x0, 6);
									if (strcmp(respuesta,"") != 0)
									{
										respuesta[strlen(respuesta)] = ',';
										cantidad_de_comas++;
									}
									sprintf(buffer,"%d", punto_leido.p);
//									printf("BUFFER: %s\n", buffer);
									strcat(respuesta, buffer);
//									printf("<== %s\n", respuesta);
								}
							}

							/*
							 * Cuando llega al ultimo punto, detiene la lectura.
							 */
							if (contador >= (1 + data_size_digit + data_size))
							{
								respuesta[strlen(respuesta)] = LF;
								break;
							}
							c_ant = c;
						}
						else
						{
							respuesta[contador] = c;
							/*
							 * Cuando llega un Line Feed, detiene la lectura.
							 */
							if (c == LF)
								break;
						}
						fwrite(&c, sizeof(c), 1, logfd);
						fflush(logfd);
						contador++;
					}
					/*
					 * Imprime un final de linea.
					 */
					c = LF;
					fwrite(&c, sizeof(c), 1, logfd);
					fflush(logfd);
					if (debug)
						printf("<== %s\n", respuesta);

					/*
					 * Para determinar el tama#o de la respuesta, no
					 * utiliza la funcion strlen, ya que la cadena
					 * puede incluir caracteres ascii = 0 como parte
					 * de los datos, por lo que se generaria un final
					 * de cadena erroneo.
					 */
					rc = send(newSd, respuesta, strlen(respuesta) + 1, 0);
					if (rc < 0)
					{
						perror("no puedo devolver respuesta al programa cliente");
						close(sd);
						exit(1);
					}
					close(sd);
					contador = 0;
					close(newSd);
					_exit (0);
				}
				/*
				 * Proceso padre: Escribe en el puerto
				 */
				else /* if ((pid = fork()) == -1) */
				{
					/*
					 * Escritura efectiva del puerto
					 */
//					usleep(100);
//					write(fd,lf,strlen(lf));
					usleep(100);
					write(fd,pregunta,strlen(pregunta));
					usleep(50);
					memset(pregunta,0x0,MAXLINE);

					if (wait(&status) != pid)
					{
						printf("El hijo finalizo con error\n");
					}
					pr_exit(status);
				} /* if ((pid = fork()) == -1) */
			}
			/*
			 * El comando NO tiene respuesta
			 */
			else /* if (tiene_respuesta(pregunta)) */
			{
				if (debug)
					printf("Comando %s no tiene respuesta\n", pregunta);
				/*
				 * Acomoda el comando para que sea compatible con IEEE 488.2
				 */
				cantidad = strlen(pregunta);
				pregunta[cantidad] = LF;
				pregunta[cantidad+1] = '\0';
				fwrite(pregunta, strlen(pregunta), 1, logfd);
				fflush(logfd);
				if (debug)
					printf("==> %s", pregunta);

				/*
				 * Escribe el comando en el puerto
				 */
				write(fd,pregunta,strlen(pregunta));
				memset(pregunta,0x0,MAXLINE);
			} /* fin de if (tiene_respuesta(pregunta)) */
		} /* fin de while (read_line(newSd,pregunta) != -1) */
	} /* fin de while (1) */
													    
	tcsetattr(fd,TCSANOW,&oldtio);
	close(fd);
	fclose(logfd);
	close(errorfd);
	exit (0);
}


void usage(char *comando)
{
	printf("\nuso: %s [OPCIONES] consulta\n", comando);
	puts("OPCIONES:");
	puts("\t-l <archivo_log> (Valor por defecto: /var/log/gds820.log)");
	puts("\t-b {38400 | 19200 | 9600 | 4800 | 2400 | 1200 | 600 | 300}");
	puts("\t\t(Valor por defecto: 1200 bps)");
	puts("\t-d <device_capturado> (Valor por defecto: /dev/ttyS0)");
	puts("\t-D (Imprime informacion de debug)");
	puts("\t-c <comando> (Valor por defecto: *IDN?)");
	puts("\t-x (Habilita control de flujo por hardware)");
	puts("\t-c (Habilita control de flujo por hardware)");
	puts("\t-h Presenta este menu de ayuda\n");
}


void procesar_opciones(int argc, char *argv[])
{
	while ((c = getopt(argc, argv, "l:b:d:c:xDh")) != EOF)
	{
		switch (c)
		{
			case 'l':
				logfile = optarg;
				break;
			case 'b':
				baudrate = optarg;
				break;
			case 'd':
				device = optarg;
				break;
			case 'c':
				sprintf(pregunta, "%s", optarg);
				break;
			case 'x':
				hardware_control = TRUE;
				break;
			case 'D':
				debug = TRUE;
				break;
			case 'h':
			default:
				usage(argv[0]);
				exit(1);
		}
	}
	argc -= optind;
	argv += optind;

	if (argc > 1)
	{
		usage(argv[0]);
		exit(1);
	}
}


int daemon_init (void)
{
	pid_t pid;

	if ((pid = fork()) < 0)
		return (-1);
	else if (pid != 0)
		exit (0);

	setsid();
	chdir("/");
	umask(0);
	return(0);
}


