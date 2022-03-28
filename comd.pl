#!/usr/bin/perl -w
#
#
# Universidad Blas Pascal
#
# FECHA: 15/02/2005
#
# AUTHORS:
# 	Roberto J. R. Paz
# 	Juan C. Galleguillo
#
# Descripcion: Servicio que se encarga de comunicarse con el GDS-820C via RS-232
# recibiendo los requerimientos a traves de TCP/IP.
#

use strict;
use gds820;
use Socket;
use Carp;
use IO::Handle;
use FileHandle;
use Device::SerialPort;
use POSIX qw(:termios_h :fcntl_h);

my $port = "1234";
my $serial = "/dev/ttyS1";
my $logfile = "/var/log/comd.log";

# Configuracion del puerto serial.
my $ob = Device::SerialPort->new ($serial) || die "No se puede abrir puerto serial $serial: $!";
$ob->baudrate(38400) || die "Hubo un problema al setear baudrate";
$ob->parity("none") || die "Hubo un problema al setear paridad";
$ob->databits(8) || die "Hubo un problema al tratar de setear el tama#o de la palabra de datos";
$ob->handshake("none") || die "Hubo un problema al tratar de setear el handshake";
$ob->write_settings || die "No se pudo configurar el puerto";

# Predefine la funcion que sera utilizada para escribir en el archivo
# de log.
sub logmsg;

# Define los parametros de la comunicacion TCP/IP.
my $proto = getprotobyname('tcp');
socket(SERVER, PF_INET, SOCK_STREAM, $proto) or die "socket: $!";
setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, pack("l", 1)) or die "setsockopt: $!";
bind(SERVER, sockaddr_in($port, INADDR_ANY)) or die "bind: $!";
listen(SERVER,SOMAXCONN) or die "listen: $!";

logmsg "$0 arranco en el puerto $port";

my $paddr;

$SIG{CHLD} = 'IGNORE';

#&daemon;

sub time_out
{
	print "No se obtuvo respuesta del osciloscopio\n";
	goto BEGIN;
}

$SIG{ALRM} = sub { die "timeout" };

my $respuesta = "";

BEGIN: eval
{
	# Resetea puerto serial.
	logmsg "reseteando $serial";
	&reset_port($serial);
	my $pass=$ob->write("\n*IDN?\n");

	alarm(3);
	open(DEV, "< $serial") || die "No puedo abrir puerto $serial: $_";
	{
		$respuesta = <DEV>;
	}
	close(DEV);
	alarm(0);
};

if ($@ =~ /timeout/)
{
	goto BEGIN;
}
else
{
	alarm(0);
}

# Bucle sin fin que atiende a los clientes TCP.
for ( ; $paddr = accept(CLIENT,SERVER); close CLIENT)
{
	my($port,$iaddr) = sockaddr_in($paddr);
	my $name = gethostbyaddr($iaddr,AF_INET);

	logmsg "conexion desde $name [",inet_ntoa($iaddr),"] en el puerto $port";

	my $pregunta = <CLIENT>;
	{
		logmsg("Q:$pregunta");

		# Resetea puerto serial.
		&reset_port($serial);
		
		# Si el comando enviado por el cliente requiere una respuesta
		# del osciloscopio, abre otro proceso para que atienda lo que
		# responde el puerto serial, de tal manera de poder enviarselo
		# al cliente TCP.
REREAD:
		if ((&tiene_respuesta($pregunta)) == 1)
		{
			die "can't fork: $!" unless defined(my $kidpid = fork());
			if ($kidpid)
			{
				my $pid = $$;
				logmsg("PID PADRE: $pid");
				my $pass=$ob->write($pregunta);
				logmsg("Fallo en la escritura") unless ($pass);
				logmsg("Escritura incompleta") if ( $pass != length($pregunta));
			}
			else
			{
				my $respuesta = "";
				alarm(3);
				my $pid = $$;
				logmsg("PID HIJO: $pid");

				eval
				{
					open(DEV, "< $serial") || die "No puedo abrir puerto $serial: $_";
					# Segun el tipo de comando enviado al osciloscopio, la respuesta
					# del mismo puede ser una sucesion de bytes ilegible, o bien,
					# una cadena de texto legible.
					if (($pregunta =~ /:ACQUIRE[1|2]:POINT/i) || ($pregunta =~ /:ACQUIRE[1|2]:MEMORY/i) || ($pregunta =~ /:TEMPLATE\d+:DOWNLOAD/i))
					{
						read(DEV, my $numeral, 1);
						alarm(0);
						if ($numeral ne '#')
						{
							logmsg("Fallo en el formato");
							last;
						}
						$respuesta = $respuesta.$numeral;
						read(DEV, my $data_size_digit, 1);
						$respuesta = $respuesta.$data_size_digit;
						read(DEV, my $data_size, $data_size_digit);
						$respuesta = $respuesta.$data_size;
						read(DEV, my $resto, $data_size);
						$respuesta = $respuesta.$resto;
#						logmsg("R: $respuesta");
					}
					else
					{
						$respuesta = <DEV>;
						alarm(0);
					}

					print CLIENT $respuesta;
					close(DEV);

					logmsg("A:$respuesta");
				};


				if ($@ =~ /timeout/)
				{
					logmsg("timeout en respuesta");
					goto REREAD;
				}
				else
				{
					alarm(0);
				}
				close CLIENT;

				# Termina el proceso hijo que envio la respuesta al
				# cliente.
				exit (0);
			}
		}
		# Si el comando enviado por el cliente NO requiere una respuesta
		# del osciloscopio, simplemente la envia al mismo sin esperar nada.
		elsif ((&tiene_respuesta($pregunta)) == 0)
		{
			my $pass=$ob->write($pregunta);
			logmsg("1: fallo en la escritura") unless ($pass);
			logmsg("1: escritura incompleta") if ( $pass != length($pregunta));
		}
		# En cualquier otro caso, el comando no existe.
		else
		{
			logmsg("Comando inexistente: $pregunta");
		}
	}
	close CLIENT;
} 

#close CLIENT;
close SERVER;
undef $ob;
exit;


sub logmsg
{
#	chomp (@_);
	my @argumento = @_;
	chomp(@argumento);
	open (LOG, ">> $logfile");
#	print LOG scalar localtime, ": @_ \n";
	print LOG scalar localtime, ": @argumento \n";
	close (LOG);
}


sub daemon
{
	local(*TTY,*NULL);

	exit(0) if (fork);
#	write_pid($pid_file);
	if (open(NULL,"/dev/null"))
	{
		open(STDIN,">&NULL") || close(STDIN);
		open(STDOUT,">&NULL") || close(STDOUT);
		open(STDERR,">&NULL") || close(STDERR);
	}
	else
	{
		close(STDIN);
		close(STDOUT);
		close(STDERR);
	}
	eval 'require "sys/ioctl.ph";';
	return if !defined(&TIOCNOTTY);
	open(TTY,"+>/dev/tty") || return;
	ioctl(TTY,&TIOCNOTTY,0);
	close(TTY);
}                


#
# Subrutina: reset_port
#
# Descripcion: Esta subrutina resetea el puerto serial.
#
sub reset_port
{
	my $serial = $_[0];

	my $ob = Device::SerialPort->new ($serial) || die "No se puede abrir puerto serial $serial: $!";
	$ob->baudrate(38400) || die "Hubo un problema al setear baudrate";
	$ob->parity("none") || die "Hubo un problema al setear paridad";
	$ob->databits(8) || die "Hubo un problema al tratar de setear el tama#o de la palabra de datos";
	$ob->handshake("none") || die "Hubo un problema al tratar de setear el handshake";
	$ob->write_settings || die "No se pudo configurar el puerto";
	undef($ob);

	sysopen (SERIAL, $serial, O_RDWR | O_NONBLOCK ) || die "reset-serial:$serial: $!\n";
	my $serial_port = POSIX::Termios->new;
	$serial_port->getattr(fileno(SERIAL)) or die "reset-serial:getattr: $!\n";
	$serial_port->setlflag($serial_port->getlflag & ~ECHO);
	$serial_port->setcflag(($serial_port->getcflag | CREAD | CLOCAL) & ~HUPCL);
	$serial_port->setattr(fileno(SERIAL), TCSANOW) or die "reset-serial:setattr: $!\n";
	close (SERIAL);
}
