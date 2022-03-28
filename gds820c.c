#include <string.h>
#include <signal.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <stdio.h>
#include <unistd.h>
#include "gds820.h"

char pregunta[MAXLINE];
char respuesta[MAXLINE*2];
int debug = FALSE;
pid_t pid;
int status;

/*
 * Funciones
 */
int read_line(int, char *);
int tiene_respuesta (char *);
void signal_alarm(int);
void pr_exit (int);

int main (int argc, char *argv[])
{
	int sd, rc, cantidad, contador;
	struct sockaddr_in localAddr, servAddr;
	struct hostent *h;

  if(argc != 3)
	{
		printf("\nuso: %s <server> <comando>\n\n",argv[0]);
		exit(1);
	}
	memset(pregunta,0x0,MAXLINE);
	memset(respuesta,0x0,MAXLINE*2);
	sprintf(pregunta, "%s", argv[2]);

  h = gethostbyname(argv[1]);
  if (h == NULL)
	{
    printf("No se pudo determinar la direccion del host '%s'\n",argv[1]);
    exit(1);
  }

	servAddr.sin_family = h->h_addrtype;
	memcpy((char *) &servAddr.sin_addr.s_addr, h->h_addr_list[0], h->h_length);
	servAddr.sin_port = htons(SERVER_PORT);

  /*
	 * Crea el socket
	 */
  sd = socket(AF_INET, SOCK_STREAM, 0);
	if (sd < 0)
	{
		perror("No puedo crear el socket ");
		exit(1);
	}

  /*
	 * Enlaza el socket a un numero de puerto aleatorio
	 */
	localAddr.sin_family = AF_INET;
	localAddr.sin_addr.s_addr = htonl(INADDR_ANY);
	localAddr.sin_port = htons(0);

	rc = bind(sd, (struct sockaddr *) &localAddr, sizeof(localAddr));
	if (rc < 0)
	{
		printf("No puedo conectarme al puerto %u\n",SERVER_PORT);
		perror("error ");
		exit(1);
	}
				
  /*
	 * Nos conectamos al servidor
	 */
  rc = connect(sd, (struct sockaddr *) &servAddr, sizeof(servAddr));
  if (rc < 0)
	{
		perror("No puedo conectarme al servidor ");
		exit(1);
	}

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
		 * Acomoda el comando para que sea compatible con IEEE 488.2
		 */
		cantidad = strlen(pregunta);
		pregunta[cantidad] = LF;
		pregunta[cantidad+1] = '\0';

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
		 * Proceso hijo: Lee en el socket
		 */
		else if (pid == 0) /* if ((pid = fork()) == -1) */
		{
			/*
			 * Configura alarmas por posibles timeouts.
			 */
			signal(SIGALRM, signal_alarm);
			alarm(3);

			/*
			 * Lee la respuesta del socket
			 */
			contador = 0;
			while (read_line(sd,respuesta) != -1)
			{
				alarm(0);
				if (debug)
					printf("recibida respuesta %s\n", respuesta);

				respuesta[strlen(respuesta) - 1] = '\0';
				respuesta[strlen(respuesta)] = LF;
				break;
				contador++;
			} /* while (read_line(sd,respuesta) != -1) */
			if (debug)
				printf("<== %s", respuesta);

//			printf("Largo: %d\n", strlen(respuesta));
			printf("%s", respuesta);

			/*
			 * Para determinar el tama#o de la respuesta, no
			 * utiliza la funcion strlen, ya que la cadena
			 * puede incluir caracteres ascii = 0 como parte
			 * de los datos, por lo que se generaria un final
			 * de cadena erroneo.
			 */
//			close(sd);
//			_exit (0);
		}
		/*
		 * Proceso padre: Escribe en el socket
		 */
		else /* if ((pid = fork()) == -1) */
		{
			/*
			 * Escritura efectiva del socket
			 */
			rc = send(sd, pregunta, strlen(pregunta) + 1, 0);
			if(rc < 0)
			{
				perror("No puedo enviar datos ");
				close(sd);
				exit(1);
			}

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
		if (debug)
			printf("==> %s\n", pregunta);

		/*
		 * Escribe el comando en el socket
		 */
		rc = send(sd, pregunta, strlen(pregunta) + 1, 0);
		if(rc < 0)
		{
			perror("No puedo enviar datos ");
			close(sd);
			exit(1);
		}
	} /* fin de if (tiene_respuesta(pregunta)) */
													    
	exit(0);
}

