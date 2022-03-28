#!/bin/sh

cd /root/projects/gds-820c/sql
mysql -u root < crear_tablas.sql
mysql -u root < crear_configuracion_inicial.sql
mysql -u root < cargar_valores_de_prueba.sql

