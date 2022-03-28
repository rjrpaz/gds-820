package gds820;

use strict;
use warnings;
use gds820_setup;
use Tie::IxHash;
use POSIX;

BEGIN {
	use Exporter ();
	use Mysql;
	use gds820_setup;

	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	$VERSION     = 1.00;

	@ISA         = qw(Exporter);
	@EXPORT      = qw(@comandos_con_respuesta @comandos_sin_respuesta %show %modify_cursor %cursor_source %channel_probe %channel_coupling %channel_bwlimit %channel_invert %channel_scale_0 %channel_scale_1 %channel_scale_2 %timebase_scale &config &return_error &tiene_respuesta &ejecutar &generar_imagen &save_graph &load_graph &str2sci &str2sci_v &sci2str &sci2str_v &str2vol &time2dot &volt2dot &acomodar_case &chequeo_password &chequeo_crypt_password &md5 &get_config &set_config &get_graphname &get_existent_graphname &graphname_is_used &calcular_valor);
	%EXPORT_TAGS = ( );

	@EXPORT_OK   = qw();
	use vars qw(@comandos_con_respuesta @comandos_sin_respuesta %show %modify_cursor %cursor_source %channel_probe %channel_coupling %channel_bwlimit %channel_invert %channel_scale_0 %channel_scale_1 %channel_scale_2 %timebase_scale);
}
our @EXPORT_OK;

@comandos_con_respuesta = ('*IDN?', '*ESE?', '*ESR?', '*LRN?', '*OPC?', '*SRE?', '*STB?', ':ACQUIRE:AVERAGE?', ':ACQUIRE:MODE?', ':ACQUIRE1:MEMORY?', ':ACQUIRE2:MEMORY?', ':ACQUIRE1:POINT', ':ACQUIRE2:POINT', ':CHANNEL1:BWLIMIT?', ':CHANNEL2:BWLIMIT?', ':CHANNEL1:COUPLING?', ':CHANNEL2:COUPLING?', ':CHANNEL1:DISPLAY?', ':CHANNEL2:DISPLAY?', ':CHANNEL1:INVERT?', ':CHANNEL2:INVERT?', ':CHANNEL1:OFFSET?', ':CHANNEL2:OFFSET?', ':CHANNEL1:PROBE?', ':CHANNEL2:PROBE?', ':CHANNEL1:SCALE?', ':CHANNEL2:SCALE?', ':CURSOR:SOURCE?', ':CURSOR:X1POSITION?', ':CURSOR:X2POSITION?', ':CURSOR:XDELTA?', ':CURSOR:XDISPLAY?', ':CURSOR:Y1POSITION?', ':CURSOR:Y2POSITION?', ':CURSOR:YDELTA?', ':CURSOR:YDISPLAY?', ':DISPLAY:ACCUMULATE?', ':DISPLAY:CONTRAST?', ':DISPLAY:GRATICULE?', ':DISPLAY:WAVEFORM?', ':MEASURE:FALL?', ':MEASURE:FREQUENCY?', ':MEASURE:NWIDTH?', ':MEASURE:PDUTY?', ':MEASURE:PERIOD?', ':MEASURE:PWIDTH?', ':MEASURE:RISE?', ':MEASURE:SOURCE?', ':MEASURE:VAMPLITUDE?', ':MEASURE:VAVERAGE?', ':MEASURE:VHI?', ':MEASURE:VLO?',':MEASURE:VMAX?', ':MEASURE:VMIN?', ':MEASURE:VPP?', ':MEASURE:VRMS?', ':TEMPLATE1:DOWNLOAD?', ':TIMEBASE:DELAY?', ':TIMEBASE:SCALE?', ':TIMEBASE:SWEEP?', ':TRIGGER:COUPLE?', ':TRIGGER:LEVEL?', ':TRIGGER:SLOP?', ':TRIGGER:SOURCE?', ':TRIGGER:TYPE?');
@comandos_sin_respuesta = (':ACQUIRE:AVERAGE ', ':ACQUIRE:MODE ', ':CHANNEL1:BWLIMIT ', ':CHANNEL2:BWLIMIT ', ':CHANNEL1:COUPLING ', ':CHANNEL2:COUPLING ', ':CHANNEL1:DISPLAY ', ':CHANNEL2:DISPLAY ', ':CHANNEL1:INVERT ', ':CHANNEL2:INVERT ', ':CHANNEL1:MATH ', ':CHANNEL2:MATH ', ':CHANNEL1:OFFSET ', ':CHANNEL2:OFFSET ', ':CHANNEL1:PROBE ', ':CHANNEL2:PROBE ', ':CHANNEL1:SCALE ', ':CHANNEL2:SCALE ', ':CURSOR:SOURCE ', ':CURSOR:X1POSITION ', ':CURSOR:X2POSITION ', ':CURSOR:XDISPLAY ', ':CURSOR:Y1POSITION ', ':CURSOR:Y2POSITION ', ':CURSOR:YDISPLAY ', ':DISPLAY:ACCUMULATE ', ':DISPLAY:CONTRAST ', ':DISPLAY:GRATICULE ', ':DISPLAY:WAVEFORM ', ':MEASURE:SOURCE ', ':TIMEBASE:DELAY ', ':TIMEBASE:SCALE ', ':TIMEBASE:SWEEP ', ':TRIGGER:COUPLE ', ':TRIGGER:LEVEL ', ':TRIGGER:SLOP ', ':TRIGGER:SOURCE ', ':TRIGGER:TYPE ');


# Define las posibles fuentes de informacion a mostrar
tie %show, "Tie::IxHash";
%show= (
	'0' => 'Channel 1',
	'1' => 'Channel 2',
	'2' => 'Cursors'
	);

# Define los posible cursores a modificar
tie %modify_cursor, "Tie::IxHash";
%modify_cursor= (
	'1' => 'X1Position',
	'2' => 'X2Position',
	'3' => 'Y1Position',
	'4' => 'Y2Position'
	);

# Define los valores posibles de fuente para el cursor
tie %cursor_source, "Tie::IxHash";
%cursor_source = (
	'1' => 'Channel 1',
	'2' => 'Channel 2',
	'3' => 'Math'
	);

# Define los valores posibles de atenuacion
tie %channel_probe, "Tie::IxHash";
%channel_probe = (
	'0' => 'X 1',
	'1' => 'X 10',
	'2' => 'X 100'
	);

# Define los valores posibles de acoplamiento
tie %channel_coupling, "Tie::IxHash";
%channel_coupling = (
	'0' => 'AC',
	'1' => 'DC',
	'2' => 'Ground'
	);

# Define la habilitacion o deshabilitacion de
# la limitacion de ancho de banda.
tie %channel_bwlimit, "Tie::IxHash";
%channel_bwlimit = (
	'0' => 'Off',
	'1' => 'On'
	);

# Define la habilitacion o deshabilitacion de
# la funcion de inversion de la forma de onda.
tie %channel_invert, "Tie::IxHash";
%channel_invert = (
	'0' => 'Off',
	'1' => 'On'
	);

# Define los valores posibles de la escala vertical.
# Probe = 0
tie %channel_scale_0, "Tie::IxHash";
%channel_scale_0 = (
	'0.002' => '2.00mV',
	'0.005' => '5.00mV',
	'0.01' => '10.0mV',
	'0.02' => '20.0mV',
	'0.05' => '50.0mV',
	'0.1' => '100mV',
	'0.2' => '200mV',
	'0.5' => '500mV',
	'1' => '1.00V',
	'2' => '2.00V',
	'5' => '5.00V'
);

# Probe = 1
tie %channel_scale_1, "Tie::IxHash";
%channel_scale_1 = (
	'0.02' => '20.0mV',
	'0.05' => '50.0mV',
	'0.1' => '100mV',
	'0.2' => '200mV',
	'0.5' => '500mV',
	'1' => '1.00V',
	'2' => '2.00V',
	'5' => '5.00V',
	'10' => '10.0V',
	'20' => '20.0V',
	'50' => '50.0V'
);

# Probe = 2
tie %channel_scale_2, "Tie::IxHash";
%channel_scale_2 = (
	'0.2' => '200mV',
	'0.5' => '500mV',
	'1' => '1.00V',
	'2' => '2.00V',
	'5' => '5.00V',
	'10' => '10.0V',
	'20' => '20.0V',
	'50' => '50.0V',
	'100' => '100V',
	'200' => '200V',
	'500' => '500V'
);

# Define los valores posibles en la escala de la base de tiempos.
tie %timebase_scale, "Tie::IxHash";
%timebase_scale = (
	'1e-9' => '1.000ns',
	'2.5e-9' => '2.500ns',
	'5e-9' => '5.000ns',
	'10e-9' => '10.00ns',
	'25e-9' => '25.00ns',
	'50e-9' => '50.00ns',
	'100e-9' => '100.0ns',
	'250e-9' => '250.0ns',
	'500e-9' => '500.0ns',
	'1e-6' => '1.000us',
	'2.5e-6' => '2.500us',
	'5e-6' => '5.000us',
	'10e-6' => '10.00us',
	'25e-6' => '25.00us',
	'50e-6' => '50.00us',
	'100e-6' => '100.0us',
	'250e-6' => '250.0us',
	'500e-6' => '500.0us',
	'1e-3' => '1.000ms',
	'2.5e-3' => '2.500ms',
	'5e-3' => '5.000ms',
	'10e-3' => '10.00ms',
	'25e-3' => '25.00ms',
	'50e-3' => '50.00ms',
	'100e-3' => '100.0ms',
	'250e-3' => '250.0ms',
	'500e-3' => '500.0ms',
	'1' => '1.000s',
	'2.5' => '2.500s',
	'5' => '5.000s',
	'10' => '10.00s'
	);


sub config
{
	use Mysql;
	my $atributo = $_[0];

	my $dbh = Mysql->connect($host, $database, $user, $pass);

	my $sql_statement = "SELECT valor FROM Configuracion WHERE atributo LIKE '".$atributo."'";

	my $sth = $dbh->query($sql_statement)
	or die "Error en el proceso";

	return $sth->fetchrow;
}


sub return_error
{
	use CGI qw(:standard escapeHTML);
	my $keyword = $_[0];
	my $message = $_[1];
	my $mysql_error = $_[2];
	my $code = $_[3];

	my $alarma = "";

	print header();
	my $tmpldir = &config('path_template');
	my $template_header = HTML::Template->new(filename => 'header.tmpl', path => $tmpldir);
	my $titulo = &config('titulo_principal');
	$titulo = $titulo." - Error";
	$template_header->param(titulo => $titulo);
	my $color_de_fondo = &config('color_de_fondo');
	$template_header->param(color_de_fondo => $color_de_fondo);
	print $template_header->output;

	print STDERR "ERR0: $code \n";
	$alarma = $code;
	print STDERR "ERR1: $keyword \n";
	$alarma = $alarma."\n".$keyword;
	print STDERR "ERR2: $message \n";
	$alarma = $alarma."\n".$message;

	if ($mysql_error ne '')
	{
		print STDERR "ERR3: $mysql_error \n";
		$alarma = $alarma."\n".$mysql_error;
	}
	print "  <DIV ALIGN=\"center\">\n";
	print "   <H1>\n";
	print "    $keyword\n";
	print "   </H1>\n";
	print "   $message\n";
	print "  <BR>\n";
	print "  <BR>\n";
	if ($mysql_error ne "")
	{
		print "  El mensaje de Error que devolvio la base de datos fue:\n";
		print "  <BR>\n";
		print "  $mysql_error\n";
	}
	print "  </DIV>\n";

	my $template = HTML::Template->new(filename => 'footer.tmpl', path => $tmpldir);

	my $usar_link_pagina_principal = 0;
	$template->param(usar_link_pagina_principal => $usar_link_pagina_principal);
	print $template->output;

	exit(1);
}



# 
# Subrutina: tiene_respuesta
#
# Descripcion: Devuelve 1 si el comando debe esperar una respuesta del
# osciloscopio, y 0 si no debe esperarla. Devuelve -1 si el comando no
# esta en la lista de comandos existentes.
#
# Argumentos:
# 1) comando: Comando que se envia al osciloscopio.
# 

sub tiene_respuesta
{
	my $comando = $_[0];
	chomp($comando);
	my $resultado = -1;

	foreach my $valor (@comandos_con_respuesta)
	{
		my $valorm = quotemeta($valor);
		if ($comando =~ m/$valorm/)
		{
			$resultado = 1;
			last;
		}
	}

	foreach my $valor (@comandos_sin_respuesta)
	{
		my $valorm = quotemeta($valor);
		if ($comando =~ m/$valorm/)
		{
			$resultado = 0;
			last;
		}
	}

	return $resultado;
}


# 
# Subrutina: ejecutar
#
# Descripcion: Esta subrutina envia comandos al osciloscopio
# a traves del servidor TCP, repitiendo la operacion la cantidad
# de veces que haga falta hasta que el equipo devuelva un valor.
# Como limite, no ejecuta los comandos mas de 3 veces.
#
# Argumentos:
# 1) comando: Comando que se envia al osciloscopio.
# 
# Resultado:
# 1) resultado: Cadena de texto que devuelve el osciloscopio.
# 
sub ejecutar
{
	my $comando = $_[0];
	my $resultado = "";
	my $contador = 0;
	print STDERR "COMANDO: $comando \n";

	# Guarda el comando ingresado en una nueva variable
	my $comando_a_ejecutar = $comando;

	# Si el comando ingresado tiene un espacio, ejecuta con comillas.
	$comando_a_ejecutar = "/usr/bin/gds820c localhost \"".$comando."\"";

	if ((&tiene_respuesta($comando)) == 1)
	{
		while (($resultado eq "") && ($contador < 4))
		{
			$resultado = `$comando_a_ejecutar`;
			chomp($resultado);
#			print STDERR "RESULTADO: $resultado \n";
			return $resultado if ($resultado ne "");
			sleep (1);
			$contador++
		}
	}
	else
	{
		system($comando_a_ejecutar);
	}
	return "";
}



# 
# Subrutina: generar_imagen
#
# Descripcion: Esta subrutina genera la imagen de la pantalla del
# osciloscopio, en base a una operacion de captura.
#
# Argumentos:
# 

sub generar_imagen
{
	my $mostrar_channel_1 =  $_[0];
	my $mostrar_channel_2 =  $_[1];
	my $mostrar_cursors =  $_[2];
	my $volts_por_division_1 =  $_[3];
	my $channel1_offset =  $_[4];
	my $volts_por_division_2 =  $_[5];
	my $channel2_offset =  $_[6];
	my $cursor_source =  $_[7];
	my $cursor_x1position =  $_[8];
	my $cursor_x2position =  $_[9];
	my $cursor_y1position =  $_[10];
	my $cursor_y2position =  $_[11];
	my $acquire1 =  $_[12];
	my $acquire2 =  $_[13];

	my $gnuplot = "/usr/bin/gnuplot";
	my $process_id = $$;
	my $datafile = join ("", "/tmp/", $process_id, ".lst");
	my $output_png = join ("", "/var/gds820/images/", $process_id, ".png");
	system ("/bin/rm -f /var/gds820/images/*.png");
	my $contador = 0;
	my $grid_on = 0;

	my %y1 = ();
	my %y2 = ();
	my %y = ();

	# Determina los valores de los margenes verticales
	# del grafico.
	my $ymax_1 = sprintf("%.6f", $volts_por_division_1 * 4);
	my $ymin_1 = $ymax_1 * (-1);
	my $ymax_2 = sprintf("%.6f", $volts_por_division_2 * 4);
	my $ymin_2 = $ymax_2 * (-1);

	# Adquiere datos de CHANNEL 1
	if ($mostrar_channel_1 == 1)
	{
		if ($acquire1 eq "")
		{
			# Obtiene la curva de voltaje.
			$acquire1 = &ejecutar(":ACQUIRE1:POINT");
		}

		# Para que el muestreo se asemeje a lo que se ve en pantalla,
		# de los 500 puntos que recibo, selecciono los 300 puntos
		# centrados en esos 500. Esto implica que debo descartar
		# los primeros 100 puntos (200 bytes) y los ultimos 100 puntos.
		# (ver pag. 13 del manual del operador).
		# REVISAR SI GUARDO TODO, O SOLO LOS 600 bytes siguientes.
		$contador = 0;

		my @puntos = split /,/, $acquire1;

		# Con el while, descarto los ultimos 200 bytes
		# (ver comentario anterior).
		while ($contador < 300)
		{
			$contador = sprintf ("%05d", $contador);

			# Como cada punto ocupa dos bytes, con el MSB primero
			# y el LSB despues (ver pag. 28), por lo que se calcula
			# el valor decimal equivalente.
			$y1{$contador} = $puntos[$contador + 100];
			$contador++;
		}
	}

	# Adquiere datos de CHANNEL 2
	if ($mostrar_channel_2 == 1)
	{
		if ($acquire2 eq "")
		{
			# Obtiene la curva de voltaje.
			$acquire2 = &ejecutar(":ACQUIRE2:POINT");
		}

		# Para que el muestreo se asemeje a lo que se ve en pantalla,
		# de los 500 puntos que recibo, selecciono los 300 puntos
		# centrados en esos 500. Esto implica que debo descartar
		# los primeros 100 puntos (200 bytes) y los ultimos 100 puntos.
		# (ver pag. 13 del manual del operador).
		$contador = 0;

		my @puntos = split /,/, $acquire2;

		# Por el valor 200, ver comentario anterior.
		while ($contador < 300)
		{
			$contador = sprintf ("%05d", $contador);

			# Como cada punto ocupa dos bytes, con el MSB primero
			# y el LSB despues (ver pag. 28), por lo que se calcula
			# el valor decimal equivalente.
			$y2{$contador} = $puntos[$contador + 100];
			$contador++;
		}
	}

	# Si la fuente de informacion del grafico de los
	# cursores es canal 1, calcula los valores donde
	# dibujara las lineas verticales que representan
	# al cursor.
	if ($cursor_source == 1)
	{
		$cursor_y1position =  (($ymin_1 - $ymax_1) / 200) * $cursor_y1position + $ymax_1;
		$cursor_y2position =  (($ymin_1 - $ymax_1) / 200) * $cursor_y2position + $ymax_1;
	}
	# Si la fuente de informacion del grafico de los
	# cursores es canal 2, calcula los valores donde
	# dibujara las lineas verticales que representan
	# al cursor.
	elsif ($cursor_source == 2)
	{
		$cursor_y1position =  (($ymin_2 - $ymax_2) / 200) * $cursor_y1position + $ymax_2;
		$cursor_y2position =  (($ymin_2 - $ymax_2) / 200) * $cursor_y2position + $ymax_2;
	}

	if (defined($y1{'00000'}))
	{
		%y = %y1;
	}
	else
	{
		%y = %y2;
	}

	# Escribe los datos de las curvas en un archivo que sera
	# leido por Gnuplot para generar los graficos.
	open (DATAFILE, ">" . $datafile);
	foreach my $x (sort keys %y)
	{
		print DATAFILE $x;
		my $valor = 0;

		$valor = sprintf("%.6f", ($y1{$x} * $volts_por_division_1) / 25 + $channel1_offset) if ($mostrar_channel_1 == 1);
		print DATAFILE " ",  $valor;
		
		$valor = 0;
		$valor = sprintf("%.6f", ($y2{$x} * $volts_por_division_2) / 25 + $channel2_offset) if ($mostrar_channel_2 == 1);
		print DATAFILE " ",  $valor;

		print DATAFILE "\n";
	}
	close (DATAFILE);

	# Genera los valores para el grid en pantalla.
	my $xtics = "";
	$contador = 0;
	while ($contador <= 300)
	{
		($xtics = $xtics.",") if ($xtics ne "");
		$xtics = $xtics."\"\" $contador";
		$contador = $contador + 25;
	}

	my $ytics1 = "";
	if ($mostrar_channel_1 == 1)
	{
		$contador = 0;
		while ($contador <= 8)
		{
			($ytics1 = $ytics1.",") if ($ytics1 ne "");
			my $valor = $ymin_1 + ($contador * $ymax_1) / 4;
			$valor = sprintf("%.6f", $valor);
			$ytics1 = $ytics1."\"\" ".$valor;
			$contador++;
		}
	}
	# Fin de generacion de grid.

	my $ytics2 = "";
	if ($mostrar_channel_2 == 1)
	{
		$contador = 0;
		while ($contador <= 8)
		{
			($ytics2 = $ytics2.",") if ($ytics2 ne "");
			my $valor = $ymin_2 + ($contador * $ymax_2) / 4;
			$valor = sprintf("%.6f", $valor);
			$ytics2 = $ytics2."\"\" ".$valor;
			$contador++;
		}
	}

	print STDERR "DATAFILE: $datafile \n";

	open (GNUPLOT, "|$gnuplot");
	print GNUPLOT <<Done;

# Salida en archivo png. Los colores definidos son: background: black,
# border: white, Eje: gray, Colores para las curvas: yellow, orange,
# medium aquamarine, green, light blue, blue, plum and dark violet.
# El tama#o elegido (320x240), se hizo en base a la definicion del
# manual respecto a la pantalla del aparato.
set terminal png medium size 320,240 x000000 xffffff x404040 xffff00 xffa500 x66cdaa x00ff00 xadd8e6 x0000ff xdda0dd x9500d3

# Elimina la leyenda en el borde superior derecho.
set key off

set xtics ($xtics)

# Lineas color amarillo
set style line 1 lt 1 lw 1 pt 1 ps 0.5
# Lineas color green
set style line 4 lt 4 lw 1 pt 3 ps 0.5
# Lineas color azul suave
set style line 5 lt 5 lw 1 pt 3 ps 0.5

set origin

set output "$output_png"
set multiplot
Done
	my $graficos = "";

	if ($mostrar_channel_1 == 1)
	{
		# Agrega cuadriculado en la pantalla.
		print GNUPLOT "set grid back\n";
		$grid_on = 1;
		print GNUPLOT "set ytics ($ytics1)\n";
		print GNUPLOT "set yrange [$ymin_1:$ymax_1]\n";
		print GNUPLOT "plot \"$datafile\" using 1:2 with lines ls 1\n";
	}
	if ($mostrar_channel_2 == 1)
	{
		print GNUPLOT "unset grid\n" if ($grid_on == 1);
		print GNUPLOT "set ytics ($ytics2)\n";
		print GNUPLOT "set yrange [$ymin_2:$ymax_2]\n";
		print GNUPLOT "plot \"$datafile\" using 1:3 with lines ls 5\n";
	}
	if ($mostrar_cursors == 1)
	{
		# Colores: varian segun la fuente del cursor
		# Src: Channel 1 => color = amarillo
		# Src: Channel 2 => color = azul/celeste
		# Src: Math      => color = rojo
		# Cursores horizontales.
		# Varian el color segun la fuente.
		if ($cursor_source == 1)
		{
			print GNUPLOT "plot $cursor_y1position with lines ls 1\n";
			print GNUPLOT "plot $cursor_y2position with lines ls 1\n";
		}
		else
		{
			print GNUPLOT "plot $cursor_y1position with lines ls 5\n";
			print GNUPLOT "plot $cursor_y2position with lines ls 5\n";
		}

		# Cursores verticales.
		print GNUPLOT "unset grid\n" if ($grid_on == 1);
		print GNUPLOT "set origin 0,0\n";
		print GNUPLOT "set parametric\n";
		print GNUPLOT "set xrange [0:299]\n";
		print GNUPLOT "set yrange [$ymin_1:$ymax_1]\n";
		print GNUPLOT "plot $cursor_x1position, t with lines ls 4\n";

		print GNUPLOT "unset grid\n" if ($grid_on == 1);
		print GNUPLOT "set origin 0,0\n";
		print GNUPLOT "set parametric\n";
		print GNUPLOT "set xrange [0:299]\n";
		print GNUPLOT "set yrange [$ymin_1:$ymax_1]\n";
		print GNUPLOT "plot $cursor_x2position, t with lines ls 4\n";
	}
	close (GNUPLOT);


	($output_png) = ($output_png =~ /gds820(.*)/);
	return $output_png;
#	system ("/bin/rm -f $datafile");
}


sub save_graph
{
	my $username = $_[0];
	my $label = $_[1];

	my %mostrar = ();
	$mostrar{0} = &ejecutar(":CHANNEL1:DISPLAY?");
	$mostrar{1} = &ejecutar(":CHANNEL2:DISPLAY?");
	$mostrar{2} = 0;
	my $cursor1 = &ejecutar(":CURSOR:XDISPLAY?");
	my $cursor2 = &ejecutar(":CURSOR:YDISPLAY?");

	print STDERR "CURSOR1: $cursor1 \n";
	print STDERR "CURSOR2: $cursor2 \n";

	if (($cursor1 == 1) || ($cursor2 == 1))
	{
		$mostrar{2} = 1;
	}

	my $channel1_scale = "";
	my $volts_por_division_1 = "";
	my $channel1_offset = "";
	my $acquire1_point = "";
	my $channel2_scale = "";
	my $volts_por_division_2 = "";
	my $channel2_offset = "";
	my $acquire2_point = "";
	my $cursor_source = 1;
	my $cursor_x1position = 1;
	my $cursor_x2position = 1;
	my $cursor_y1position = 1;
	my $cursor_y2position = 1;
	my $channel_scale = "";
	my $channel_offset = "";

	$channel1_scale = &ejecutar(":CHANNEL1:SCALE?");
	$volts_por_division_1 = str2sci_v($channel1_scale);
	$channel1_offset = &ejecutar(":CHANNEL1:OFFSET?");

	$channel2_scale = &ejecutar(":CHANNEL2:SCALE?");
	$volts_por_division_2 = str2sci_v($channel2_scale);
	$channel2_offset = &ejecutar(":CHANNEL2:OFFSET?");


	if ($mostrar{0} == 1)
	{
#		$channel1_scale = &ejecutar(":CHANNEL1:SCALE?");
#		$volts_por_division_1 = str2sci_v($channel1_scale);
#		$channel1_offset = &ejecutar(":CHANNEL1:OFFSET?");
		$acquire1_point = &ejecutar(":ACQUIRE1:POINT");
	}
	if ($mostrar{1} == 1)
	{
#		$channel2_scale = &ejecutar(":CHANNEL2:SCALE?");
#		$volts_por_division_2 = str2sci_v($channel2_scale);
#		$channel2_offset = &ejecutar(":CHANNEL2:OFFSET?");
		$acquire2_point = &ejecutar(":ACQUIRE2:POINT");
	}
	$cursor_source = &ejecutar(":CURSOR:SOURCE?");

	if ($cursor_source == 1)
	{
		$channel_offset = $channel1_offset;
		$channel_scale = $channel1_scale;
	}
	elsif ($cursor_source == 2)
	{
		$channel_offset = $channel2_offset;
		$channel_scale = $channel2_scale;
	}

#	if ($mostrar{2} == 1)
#	{
##		$cursor_source = &ejecutar(":CURSOR:SOURCE?");
		$cursor_x1position = &ejecutar(":CURSOR:X1POSITION?");
		$cursor_x2position = &ejecutar(":CURSOR:X2POSITION?");
		$cursor_y1position = &ejecutar(":CURSOR:Y1POSITION?");
		$cursor_y1position = &volt2dot($cursor_y1position, $channel_scale, $channel_offset);
		$cursor_y2position = &ejecutar(":CURSOR:Y2POSITION?");
		$cursor_y2position = &volt2dot($cursor_y2position, $channel_scale, $channel_offset);
#	}

	my $timebase_scale = &calcular_valor('timebase_scale');
	$cursor_x1position = &time2dot($cursor_x1position, $timebase_scale);
	$cursor_x2position = &time2dot($cursor_x2position, $timebase_scale);

	$channel1_offset = str2sci_v($channel1_offset);
	$channel2_offset = str2sci_v($channel2_offset);

	my $dbh = Mysql->connect($host, $database, $user, $pass);

	my $sql_statement = "INSERT INTO Graph (username, label, mostrar_channel_1, mostrar_channel_2, mostrar_cursors, volts_por_division_1, channel1_offset, volts_por_division_2, channel2_offset, cursor_source, cursor_x1position, cursor_x2position, cursor_y1position, cursor_y2position, acquire1_point, acquire2_point) VALUES ('".$username."', '".$label."', ".$mostrar{0}.", ".$mostrar{1}.", ".$mostrar{2}.", '".$volts_por_division_1."', '".$channel1_offset."', '".$volts_por_division_2."', '".$channel2_offset."', ".$cursor_source.", '".$cursor_x1position."', '".$cursor_x2position."', '".$cursor_y1position."', '".$cursor_y2position."', '".$acquire1_point."', '".$acquire2_point."')";
	print STDERR "SQL: $sql_statement \n";

	$dbh->query($sql_statement) or die "Error en el proceso";
}



sub load_graph
{
	my $username = $_[0];
	my $label = $_[1];

	my $dbh = Mysql->connect($host, $database, $user, $pass);

	my $sql_statement = "SELECT mostrar_channel_1, mostrar_channel_2, mostrar_cursors, volts_por_division_1, channel1_offset, volts_por_division_2, channel2_offset, cursor_source, cursor_x1position, cursor_x2position, cursor_y1position, cursor_y2position, acquire1_point, acquire2_point FROM Graph WHERE username LIKE '".$username."' AND label LIKE '".$label."'";

	my $sth = $dbh->query($sql_statement) or die "Error en el proceso";

	my ($mostrar_0, $mostrar_1, $mostrar_2, $volts_por_division_1, $channel1_offset, $volts_por_division_2, $channel2_offset, $cursor_source, $cursor_x1position, $cursor_x2position, $cursor_y1position, $cursor_y2position, $acquire1_point, $acquire2_point) = $sth->fetchrow;

	print STDERR "KK $mostrar_0 KK\n";
	print STDERR "KK $mostrar_1 KK\n";
	print STDERR "KK $mostrar_2 KK\n";
	print STDERR "KK VPD1 $volts_por_division_1 KK\n";
	print STDERR "KK $channel1_offset KK\n";
	print STDERR "KK VPD2 $volts_por_division_2 KK\n";
	print STDERR "KK $channel2_offset KK\n";
	print STDERR "KK $cursor_source KK\n";
	print STDERR "KK CX1P $cursor_x1position KK\n";
	print STDERR "KK CX2P $cursor_x2position KK\n";
	print STDERR "KK CY1P $cursor_y1position KK\n";
	print STDERR "KK CY2P $cursor_y2position KK\n";
	print STDERR "KK $acquire1_point KK\n";
	print STDERR "KK $acquire2_point KK\n";

#	$volts_por_division_1 = str2sci_v($channel1_scale);
#	$volts_por_division_2 = str2sci_v($channel1_scale);

   ########################
	 ### genera la imagen ###
	 ########################
	 my $datafile = &generar_imagen($mostrar_0, $mostrar_1, $mostrar_2, $volts_por_division_1, $channel1_offset, $volts_por_division_2, $channel2_offset, $cursor_source, $cursor_x1position, $cursor_x2position, $cursor_y1position, $cursor_y2position, $acquire1_point, $acquire2_point);
	 return $datafile;
}



# 
# Subrutina: str2sci
#
# Descripcion: En base a un valor de tiempo que haya sido devuelto por
# el osciloscopio como una cadena de texto, devuelve la notacion cientifica
# correspondiente. Ej:
# Entrada: 20.00us		->		Devuelve: 2E-05
#
# Argumentos:
# 1) numero a convertir
# 

sub str2sci
{
	my $numero = $_[0];
	my $numero_puro = 0;
	my $exponente = 0;

	#	Separa los numeros (con . incluido), del valor de texto
	#	que indica la unidad
	($numero_puro, $exponente) = ($numero =~ /([\d\.]+)(\D+)$/);
	if ($exponente =~ /ns/)
	{
		$numero_puro = $numero_puro * 1E-9;
	}
	elsif ($exponente =~ /us/)
	{
		$numero_puro = $numero_puro * 1E-6;
	}
	elsif ($exponente =~ /ms/)
	{
		$numero_puro = $numero_puro * 1E-3;
	}
	($numero_puro = (-1) * $numero_puro) if ($numero =~ /^-/);
	return $numero_puro;
}



# 
# Subrutina: str2sci_v
#
# Descripcion: En base a un valor de voltaje que haya sido devuelto por
# el osciloscopio como una cadena de texto, devuelve el valor en decimal
# correspondiente. Ej:
# Entrada: 40.0mV		->		Devuelve: 0.04
#
# Argumentos:
# 1) numero a convertir
# 

sub str2sci_v
{
	my $numero = $_[0];
	my $numero_puro = 0;
	my $exponente = 0;

	#	Separa los numeros (con . incluido), del valor de texto
	#	que indica la unidad
	($numero_puro, $exponente) = ($numero =~ /([\d\.]+)(\D+)$/);
	if ($exponente =~ /mV/i)
	{
		$numero_puro = $numero_puro * 0.001;
	}
	elsif ($exponente =~ /uV/i)
	{
		$numero_puro = $numero_puro * 0.000001;
	}
	$numero_puro = $numero_puro * -1 if ($numero =~ /^-/);
	return $numero_puro;
}



# 
# Subrutina: sci2str
#
# Descripcion: En base a un valor de tiempo que este en notacion cientifica
# genera una cadena de texto mas legible. Ej:
# Entrada: 2E-05 	->		Devuelve: 20us
#
# Argumentos:
# 1) numero a convertir
# 

sub sci2str
{
	my $numero = $_[0];
	my $cadena = "";
	my $numero_puro = "";
	my $exponente = "";

	if (($numero == 0) || (abs($numero) < 1e-15))
	{
		$numero_puro = $exponente = 0;
	}
	else
	{
		($numero_puro, $exponente) = ($numero =~ /([^e]*)e(.*)/);
	}
	$cadena = $numero_puro;
	if ($exponente == -9)
	{
		$cadena = sprintf("%.f", $cadena);
		$cadena = $cadena."ns"
	}
	elsif ($exponente == -8)
	{
		$cadena = sprintf("%.f", $cadena * 10);
		$cadena = $cadena."ns"
	}
	elsif ($exponente == -7)
	{
		$cadena = sprintf("%.f", $cadena * 100);
		$cadena = $cadena."ns"
	}
	elsif ($exponente == -6)
	{
		$cadena = sprintf("%.f", $cadena);
		$cadena = $cadena."us"
	}
	elsif ($exponente == -5)
	{
		$cadena = sprintf("%.f", $cadena * 10);
		$cadena = $cadena."us"
	}
	elsif ($exponente == -4)
	{
		$cadena = sprintf("%.f", $cadena * 100);
		$cadena = $cadena."us"
	}
	elsif ($exponente == -3)
	{
		$cadena = sprintf("%.3f", $cadena);
		$cadena = $cadena."ms";
	}
	elsif ($exponente == -2)
	{
		$cadena = sprintf("%.f", $cadena * 10);
		$cadena = $cadena."ms"
	}
	elsif ($exponente == -1)
	{
		$cadena = sprintf("%.f", $cadena * 100);
		$cadena = $cadena."ms"
	}
	else
	{
		$cadena = sprintf("%.f", $cadena);
		$cadena = $cadena."s"
	}
	return $cadena;
}































# 
# Subrutina: sci2str_v
#
# Descripcion: En base a un valor de voltaje que este en decimal
# genera una cadena de texto mas legible. Ej:
# Entrada: 0.06 	->		Devuelve:60mV 
#
# Argumentos:
# 1) numero a convertir
# 

sub sci2str_v
{
	my $numero = $_[0];
	my $cadena = "";
	my $entero = "";
	my $decimal = "";

	if (($numero == 0) || (abs($numero) < 1e-15))
	{
		$cadena = "0V";
		return $cadena;
	}
	elsif ($numero =~ /\./)
	{
		($entero, $decimal) = ($numero =~ /([^\.]*)\.(.*)/);
	}
	elsif ($numero =~ /e/i)
	{
		($entero, my $exponente) = ($numero =~ /([^e]*)e-(.*)/);
		my $multiplo = sprintf("%d", 6 - $exponente);
		$entero = $entero * (10 ** $multiplo);
		$cadena = $entero."uV";
		return $cadena;
	}
	else
	{
		$cadena = $numero;
	}

	if (($entero eq '0') || ($entero eq '-0'))
	{
#		$cadena = sprintf("%0.3f", $numero);
		$cadena = $numero;
		$cadena = $cadena * 1000;
		$cadena = $cadena."mV"
	}
	else
	{
#		$cadena = $cadena."V"
		$cadena = $numero."V"
	}
	return $cadena;
}



























# 
# Subrutina: str2vol
#
# Descripcion: En base a un valor de voltaje que haya sido devuelto por
# el osciloscopio como una cadena de texto, devuelve el valor
# en volts correspondiente. Ej:
# Entrada: 2mV		->		Devuelve: 0.002
#
# Argumentos:
# 1) numero a convertir
# 

sub str2vol
{
	my $numero = $_[0];
	my $numero_puro = 0;
	my $exponente = 0;

	#	Separa los numeros (con . incluido), del valor de texto
	#	que indica la unidad
	($numero_puro, $exponente) = ($numero =~ /([\d\.]+)(\D+)$/);
	if ($exponente =~ /mV/)
	{
		$numero_puro = $numero_puro / 1000;
	}
	$numero_puro = sprintf("%.3f", $numero_puro);
	return $numero_puro;
}


# 
# Subrutina: time2dot
#
# Descripcion: A partir de valores de cursores en tiempo, lo convierte
# a puntos en pantalla, segun la escala de tiempo empleada.
# Entrada: 1ms		->		Devuelve: 175 para una escala de 500us/div
#
# Argumentos:
# 1) numero a convertir
# 2) base de tiempo
# 

sub time2dot
{
	my $time = $_[0];
	my $escala = $_[1];
	my $resultado = 0;

#	print STDERR "TIME: $time \n";
#	print STDERR "ESCALA: $escala \n";
	$time = &str2sci($time);
	$escala = &str2sci($escala);
#	print STDERR "TIME_D: $time \n";
#	print STDERR "ESCALA_D: $escala \n";

	$resultado = sprintf("%d", (25 * ($time / $escala)) + 125);

	return $resultado;
}



# 
# Subrutina: volt2dot
#
# Descripcion: A partir de valores de cursores en voltaje, lo convierte
# a puntos en pantalla, segun la escala vertical empleada, y segun el
# offset vertical.
# Entrada: 1ms		->		Devuelve: 175 para una escala de 500us/div
#
# Entrada: -60mV	->		Devuelve: 75 para una escala de 500 mV/Div y
# 												offset = 560 mV
#
# Argumentos:
# 1) numero a convertir
# 2) escala de voltaje
# 3) offset de voltaje
# 

sub volt2dot
{
	my $volt = $_[0];
	my $escala = $_[1];
	my $offset = $_[2];
	my $resultado = 0;

	print STDERR "VOLT: $volt \n";
	print STDERR "ESCALA: $escala \n";
	print STDERR "OFFSET: $offset \n";
	$volt = &str2sci_v($volt);
	$escala = &str2sci_v($escala);
	$offset = &str2sci_v($offset);
	print STDERR "VOLT_D: $volt \n";
	print STDERR "ESCALA_D: $escala \n";
	print STDERR "OFFSET_D: $offset \n";

	$resultado = 100 - 25 * (($volt + $offset) / $escala);
	$resultado = sprintf("%d", $resultado);

	return $resultado;
}


# 
# Subrutina: acomodar_case
#
# Descripcion: Acomoda mayusculas y minusculas ante un nombre
# ingresado. 
#
# Argumentos:
# 1) nombre. "Nombre de Abonado".
# 

sub acomodar_case
{
	my $nombre = $_[0];

	my @nombre_partido = split /\s+/, $nombre;
	foreach my $nombre_partido (@nombre_partido)
	{
		$nombre_partido = "\u\L$nombre_partido";
	}
        $nombre = join " ", @nombre_partido;

        return ($nombre);
}


# 
# Subrutina: chequeo_password
#
# Descripcion: Chequea usuario y password ingresadas
# por el usuario del sistema ABM.
#
# Argumentos:
# 1) usuario. "Nombre de usuario" ingresada por el usuario.
# 2) password. "Palabra clave" ingresada por el usuario.
# 

sub chequeo_password
{
	my $usuario = $_[0];
	my $password = $_[1];

	my $dbh = Mysql->connect($host, $database, $user, $pass);

	my $sql_statement = "SELECT ID FROM Usuario WHERE atributo LIKE 'username' AND valor LIKE '$usuario'";
	my $sth = $dbh->query($sql_statement)
	or die &return_error("Error en el proceso", "Hubo un error al intentar obtener el ID del usuario.", $dbh->errmsg(), "1000");
	return 0 if (($sth->numrows) != 1);
	my $id = $sth->fetchrow;

	$sql_statement = "SELECT valor FROM Usuario WHERE atributo LIKE 'password' AND ID = ".$id;
	$sth = $dbh->query($sql_statement)
	or die &return_error("Error en el proceso", "Hubo un error al intentar obtener la password del usuario.", $dbh->errmsg(), "1001");
	return 0 if (($sth->numrows) != 1);
	my $password_tabla = $sth->fetchrow;

	my $password_form = &md5($password);

	return 1 if ($password_tabla eq $password_form);

	return 0;
}


# 
# Subrutina: chequeo_crypt_password
#
# Descripcion: Chequea usuario y password encriptada ingresadas
# por el usuario del sistema ABM.
#
# Argumentos:
# 1) usuario. "Nombre de usuario" ingresada por el usuario.
# 2) password. "Palabra clave (encriptada)" ingresada por el usuario.
# 

sub chequeo_crypt_password
{
	my $usuario = $_[0];
	my $password = $_[1];

	my $dbh = Mysql->connect($host, $database, $user, $pass);

	my $sql_statement = "SELECT ID FROM Usuario WHERE atributo LIKE 'username' AND valor LIKE '$usuario'";
	my $sth = $dbh->query($sql_statement)
	or die &return_error("Error en el proceso", "Hubo un error al intentar obtener el ID del usuario.", $dbh->errmsg(), "1010");
	return 0 if (($sth->numrows) != 1);
	my $id = $sth->fetchrow;

	$sql_statement = "SELECT valor FROM Usuario WHERE atributo LIKE 'password' AND ID = ".$id;
	$sth = $dbh->query($sql_statement)
	or die &return_error("Error en el proceso", "Hubo un error al intentar obtener la password del usuario.", $dbh->errmsg(), "1011");
	return 0 if (($sth->numrows) != 1);
	my $password_tabla = $sth->fetchrow;

	return 1 if ($password_tabla eq $password);

	return 0;
}


#
# Subrutina: md5
#
# Descripcion: Obtiene la encriptacion md5 de un texto provisto,
# utilizando la funcion en Mysql.
#
# Argumentos:
# 1) password. Palabra clave ingresada por el usuario.
# 

sub md5
{
	my $password = $_[0];

	my $dbh = Mysql->connect($host, $database, $user, $pass);

	my $sql_statement = "SELECT MD5('$password')";
	my $sth = $dbh->query($sql_statement) or die &return_error ("Error en el proceso", "Hubo un error al intentar usar la función de encriptación de la Base de Datos.", $dbh->errmsg(), "1020");
	$password = $sth ->fetchrow;
	
	return $password;
}


sub esta_en_array
{
	my ($elemento, @cadena) = @_;

	foreach my $item (@cadena)
	{
		return 1 if ($item eq $elemento);
	}
	return 0;

}


#
# Subrutina: get_config
#
# Descripcion: Obtiene el perfil de configuracion de un
# usuario determinado, la cual esta guardada en una
# tabla de la Base de Datos.
#
# Argumentos:
# 1) usuario. Usuario.
# 

sub get_config
{
	my $usuario = $_[0];
	my %config = ();

	my $dbh = Mysql->connect($host, $database, $user, $pass);

	my $sql_statement = "SELECT ID FROM Usuario WHERE atributo LIKE 'username' AND valor LIKE '".$usuario."'";
	my $sth = $dbh->query($sql_statement) or die &return_error ("Error en el proceso", "Hubo un error al intentar usar la función de encriptación de la Base de Datos.", $dbh->errmsg(), "1020");
	my $id = $sth->fetchrow;

	$sql_statement = "SELECT atributo, valor FROM Usuario WHERE ID LIKE '".$id."'";
	$sth = $dbh->query($sql_statement) or die &return_error ("Error en el proceso", "Hubo un error al intentar usar la función de encriptación de la Base de Datos.", $dbh->errmsg(), "1020");
	while (my ($atributo, $valor) = $sth ->fetchrow)
	{
		$config{$atributo} = $valor;
	}
	return %config;
}


#
# Subrutina: set_config
#
# Descripcion: Establece el valor de algun atributo de
# usuario determinado, 
#
# Argumentos:
# 1) usuario. Usuario.
# 2) atributo. Atributo.
# 3) valor. Valor.
# 

sub set_config
{
	my $usuario = $_[0];
	my $atributo = $_[1];
	my $valor = $_[2];

	my $dbh = Mysql->connect($host, $database, $user, $pass);

	my $sql_statement = "SELECT ID FROM Usuario WHERE atributo LIKE 'username' AND valor LIKE '".$usuario."'";
	my $sth = $dbh->query($sql_statement) or die &return_error ("Error en el proceso", "Hubo un error al intentar usar la función de encriptación de la Base de Datos.", $dbh->errmsg(), "1020");
	my $id = $sth->fetchrow;

	$sql_statement = "UPDATE Usuario SET valor = '".$valor."' WHERE atributo LIKE '".$atributo."' AND ID LIKE '".$id."'";
	$dbh->query($sql_statement) or die &return_error ("Error en el proceso", "Hubo un error al intentar usar la función de encriptaci&oacute;n de la Base de Datos.", $dbh->errmsg(), "1020");
}



#
# Subrutina: get_graphname
#
# Descripcion: Obtiene un valor sugerido para nombrar un
# grafico, que no este siendo utilizado ya por el mismo
# usuario.
#
# Argumentos:
# 1) usuario. Usuario.
# 

sub get_graphname
{
	my $usuario = $_[0];

	my $date = `/bin/date +%y%m%d`;
	chomp($date);

	my $dbh = Mysql->connect($host, $database, $user, $pass);
	my $contador = 0;
	while ($contador < 100)
	{
		$contador = sprintf("%02d", $contador);
		my $label = $usuario."_".$date."_".$contador;
		if (&graphname_is_used($usuario, $label) == 0)
		{
			return $label;
		}
		$contador++;
	}
	return "";
}



#
# Subrutina: get_existent_graphname
#
# Descripcion: Obtiene el ultimo nombre utilizado
# para nombrar un grafico por parte de un usuario.
#
# Argumentos:
# 1) usuario. Usuario.
# 

sub get_existent_graphname
{
	my $usuario = $_[0];

	my $dbh = Mysql->connect($host, $database, $user, $pass);
	my $sql_statement = "SELECT label FROM Graph WHERE username LIKE '".$usuario."' ORDER BY ID DESC LIMIT 1";
	my $sth = $dbh->query($sql_statement) or die &return_error ("Error en el proceso", "Hubo un error al intentar usar la función de encriptación de la Base de Datos.", $dbh->errmsg(), "1020");
	if (($sth->numrows) != 0)
	{
		return $sth->fetchrow;
	}
	return "";
}



#
# Subrutina: graphname_is_used
#
# Descripcion: Se fija en la base de datos si el nombre
# para el grafico ya esta siendo utilizado por ese
# usuario.
#
# Argumentos:
# 1) usuario. Usuario.
# 2) label. Nombre para el grafico.
# 

sub graphname_is_used
{
	my $usuario = $_[0];
	my $label = $_[1];
	print STDERR "USUARIO: $usuario \n";
	print STDERR "GRAPHNAME: $label \n";

	my $dbh = Mysql->connect($host, $database, $user, $pass);
	my $sql_statement = "SELECT ID FROM Graph WHERE username LIKE '".$usuario."' AND label LIKE '".$label."'";
	my $sth = $dbh->query($sql_statement) or die &return_error ("Error en el proceso", "Hubo un error al intentar usar la función de encriptación de la Base de Datos.", $dbh->errmsg(), "1020");
	if (($sth->numrows) != 0)
	{
		return 1;
	}
	return 0;
}



sub calcular_valor
{
	my $resultado = "";
	my $consulta = "";

	my $parametro = $_[0];
	my $comando = $parametro;
	$comando =~ s/\_/:/;
	$comando =~ tr/[a-z]/[A-Z]/;
	$comando = ":".$comando;
#	print STDERR "PARAMETRO: $parametro \n";

	if (defined(param($parametro)))
	{
		my $valor = param($parametro);
		print STDERR "PARAMETRO: $parametro \n";
		print STDERR "VALOR: $valor \n";

		if ($parametro =~ /channel(.)_scale/)
		{
#			my $var = "channel".$1."_probe";
			my %channel_scale = ();

			my $argumento = "CHANNEL".$1.":PROBE?";
#			$var = &calcular_valor($var);
			my $var = &ejecutar($argumento);
			print STDERR "VAR: $var \n";
#			if ($1 eq "1")
#			{
#				$var = $channel1_probe;
#			}
#			else
#			{
#				$var = $channel2_probe;
#			}
			%channel_scale = %channel_scale_0 if ($var == 0);
			%channel_scale = %channel_scale_1 if ($var == 1);
			%channel_scale = %channel_scale_2 if ($var == 2);
			foreach my $key (keys %channel_scale)
			{
				if ($channel_scale{$key} eq $valor)
				{
					$consulta = $comando." ".$key;
					last;
				}
			}
			&ejecutar($consulta);
		}
		elsif ($parametro =~ /channel(.)_offset/)
		{
			my $channel_number = $1;
			# Configura el valor de posicion vertical de canal, en base a lo seleccionado
			# por el formulario (variable $channelX_offset).
			my $argumento = ":CHANNEL".$1.":OFFSET ";
			my $channelx_offset = &str2sci_v($valor);
			$argumento = $argumento.$channelx_offset;
			&ejecutar($argumento);

			my $channel1_scale = &ejecutar(':CHANNEL1:SCALE?');
			my $channel2_scale = &ejecutar(':CHANNEL2:SCALE?');

			# En el caso en que la cantidad de volts/div supera el valor de 1V, y
			# debido al hecho de que la cantidad de numeros que destina para manejar los
			# valores de offset vertical es de tres numeros a los sumo (Ej.: 3.82, 10.2, etc.),
			# cuando los valores de offset que estamos manejando superan los 10 volts, debemos
			# especificar valores como 10.12, pero no podemos obtener este valor luego cuando
			# realizamos la consulta nos devuelve 10.1. En el caso de que seteamos 10.16 sucederia
			# lo mismo, por lo que el valor entraria en una ventana que no podria salir.
			# Este fenomeno sucede para el menor valor de volts/div (y por ende para el menor
			# paso), y a medida que nos acercamos a los valores maximos posibles que puede
			# adoptar el offset vertical, a saber:
			# volts/div			paso				valores de offset
			#
			# 2 mV/div.			80uV				> 10mV
			# 5 mV/div.			200uV				> 100mV
			# 10 mV/div.		400uV				> 100mV
			# 20 mV/div.		800uV				> 100mV
			# 50 mV/div.		2mV					Sin inconvenientes
			# 100 mV/div.		4mV					> 1V
			# 200 mV/div.		8mV					> 1V
			# 500 mV/div.		20mV				Sin inconvenientes
			# 1 V/div				40mV				> 10V
			# 2 V/div				80mV				> 10V
			# 5 V/div.			200mV				Sin inconvenientes
			#
			# INVESTIGAR
			# Investigar este hecho, ya que pasa tambien para los valores chicos de offset
			# en los cuales el paso sea menos a 2mV. En este caso, no se puede enviar un
			# valor mas chico que el paso, por lo que se vuelve imposible. En ese caso, el
			# paso deberia estar determinado por el menor valor posible para el rango
			# vertical dado.
			# FIN INVESTIGAR

			# Es por ello que vamos a ignorar los valores que obtenemos de la consulta, y
			# nos manejaremos con los valores especificados en el formulario.

			if ((($channel_number == 1) &&
					(((abs($channelx_offset) >= 0.01) && ($channel1_scale eq '2.00mV')) ||
				  ((abs($channelx_offset) >= 0.1) && ($channel1_scale eq '5.00mV')) ||
		  		((abs($channelx_offset) >= 0.1) && ($channel1_scale eq '10.0mV')) ||
				  ((abs($channelx_offset) >= 0.1) && ($channel1_scale eq '20.0mV')) ||
				  ((abs($channelx_offset) >= 1) && ($channel1_scale eq '100mV')) ||
				  ((abs($channelx_offset) >= 1) && ($channel1_scale eq '200mV')) ||
				  ((abs($channelx_offset) >= 10) && ($channel1_scale eq '1.00V')) ||
				  ((abs($channelx_offset) >= 10) && ($channel1_scale eq '2.00V')))) ||
					(($channel_number == 2) &&
					(((abs($channelx_offset) >= 0.01) && ($channel2_scale eq '2.00mV')) ||
				  ((abs($channelx_offset) >= 0.1) && ($channel2_scale eq '5.00mV')) ||
		  		((abs($channelx_offset) >= 0.1) && ($channel2_scale eq '10.0mV')) ||
				  ((abs($channelx_offset) >= 0.1) && ($channel2_scale eq '20.0mV')) ||
				  ((abs($channelx_offset) >= 1) && ($channel2_scale eq '100mV')) ||
				  ((abs($channelx_offset) >= 1) && ($channel2_scale eq '200mV')) ||
				  ((abs($channelx_offset) >= 10) && ($channel2_scale eq '1.00V')) ||
				  ((abs($channelx_offset) >= 10) && ($channel2_scale eq '2.00V')))))
			{
				$resultado = &sci2str_v($channelx_offset);
				return ($resultado);
			}
		}
		elsif ($parametro =~ /timebase_/)
		{
			$valor = str2sci($valor);
			$consulta = $comando." ".$valor;
			&ejecutar($consulta);
		}
		else
		{
			$consulta = $comando." ".$valor;
			&ejecutar($consulta);
		}
	}

	$consulta = $comando."?";
	$resultado = &ejecutar($consulta);
	print STDERR "RESULTADO: $resultado \n";
	return ($resultado);
}



END {}

1;
