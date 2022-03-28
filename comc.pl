#!/usr/bin/perl -w
#
#
# Universidad Blas Pascal
#
# FECHA: 15/02/2005
#
# AUTORES:
# 	Roberto J. R. Paz
# 	Juan C. Galleguillo
#
# Descripcion: Se comunica con el servicio que se encarga de la
# comunicacion con el osciloscopio a traves de RS-232
#

use strict;
use gds820;
use Socket;

my $remote = 'localhost';
my $port = 1234;

my $pregunta = $ARGV[0];
#$pregunta = $pregunta."\n";
$pregunta = $pregunta.chr(0);

# print STDOUT "$pregunta";
if ($port =~ /\D/)
{
	$port = getservbyname($port, 'tcp')
}
die "Sin puerto" unless $port;
my $iaddr = inet_aton($remote) or die "no host: $remote";
my $paddr = sockaddr_in($port, $iaddr);
my $proto  = getprotobyname('tcp');

# Si el comando enviado requiere una respuesta, se genera un nuevo
# proceso que esperara la respuesta desde el servidor TCP.
if ((&tiene_respuesta($pregunta)) == 1)
{
	socket(SOCK, PF_INET, SOCK_STREAM, $proto) or die "socket: $!";
	connect(SOCK, $paddr) or die "connect: $!";
	die "can't fork: $!" unless defined(my $kidpid = fork());
	# Espera respuesta del servidor
	if ($kidpid)
	{
		alarm(3);
		my $respuesta = "";
		$respuesta = <SOCK>;
		alarm(0);
		close (SOCK) or die "close: $!";
		print STDOUT $respuesta if (defined($respuesta));
		kill ("TERM" => $kidpid);
	}
	# Realiza la pregunta al servidor
	else
	{
		print SOCK $pregunta;
		close (SOCK) or die "close: $!";
	}
	if ($@ =~ /timeout/)
	{
		close (SOCK);
	}
	else
	{
		alarm(0);
	}
#	close (SOCK) or die "close: $!";
}
# Si el comando enviado NO requiere una respuesta, simplemente se lo envia
# al servidor sin esperar nada.
elsif ((&tiene_respuesta($pregunta)) == 0)
{
	socket(SOCK, PF_INET, SOCK_STREAM, $proto) or die "socket: $!";
	connect(SOCK, $paddr) or die "connect: $!";
	print SOCK $pregunta;
	close (SOCK) or die "close: $!";
}
# En cualquier otro caso, el comando no existe.
else
{
	print "Comando inexistente\n";
}

exit;
