use gds820;

--
-- Table structure for table 'Configuracion'
--

DROP TABLE IF EXISTS Configuracion;
CREATE TABLE IF NOT EXISTS Configuracion (
  ID int(10) NOT NULL auto_increment,
  atributo varchar(255) NOT NULL default '',
  valor varchar(255) NOT NULL default '',
  PRIMARY KEY  (ID),
  KEY atributo_idx (atributo)
) TYPE=MyISAM;


--
-- Table structure for table 'Usuario'
--

DROP TABLE IF EXISTS Usuario;
CREATE TABLE IF NOT EXISTS Usuario (
  ID int(10) NOT NULL,
  atributo varchar(255) NOT NULL default '',
  valor varchar(255) NOT NULL default '',
  KEY id_idx (ID),
  KEY atributo_idx (atributo)
) TYPE=MyISAM;


--
-- Table structure for table 'Graph'
--

DROP TABLE IF EXISTS Graph;
CREATE TABLE IF NOT EXISTS Graph (
  ID int(10) unsigned DEFAULT '0' NOT NULL auto_increment,
  username varchar(255) NOT NULL default '',
  label varchar(255) NOT NULL default '',
  mostrar_channel_1 int(1) NOT NULL default 0,
  mostrar_channel_2 int(1) NOT NULL default 0,
  mostrar_cursors int(1) NOT NULL default 0,
  volts_por_division_1 varchar(10) NOT NULL default '',
  channel1_offset varchar(10) NOT NULL default '',
  volts_por_division_2 varchar(10) NOT NULL default '',
  channel2_offset varchar(10) NOT NULL default '',
  cursor_source int(1) NOT NULL default 0,
  cursor_x1position varchar(10) NOT NULL default 0,
  cursor_x2position varchar(10) NOT NULL default 0,
  cursor_y1position varchar(10) NOT NULL default 0,
  cursor_y2position varchar(10) NOT NULL default 0,
  acquire1_point text NOT NULL default '',
  acquire2_point text NOT NULL default '',
  KEY id_idx (ID),
  KEY username_idx (username),
  KEY label_idx (label)
) TYPE=MyISAM;


