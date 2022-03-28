WWWUSER=www-data
WWWGROUP=www-data
WWWROOT=/var/gds820

CFLAGS=-Wall -O3

PERL=/usr/bin/perl -wc

SCRIPTDIR=$(WWWROOT)/cgi-bin
PMDIR=$(WWWROOT)/pm
HTMLDIR=$(WWWROOT)/htdocs
TMPLDIR=$(WWWROOT)/tmpl
BINDIR=$(WWWROOT)/bin
IMAGESDIR=$(WWWROOT)/images
TEMPDIR=$(WWWROOT)/temp

all: gds820d gds820c
#	/usr/bin/clear
	@echo
#	@$(PERL) comd.pl
	@$(PERL) comc.pl
	@$(PERL) /etc/perl/gds820_setup.pm
	@$(PERL) gds820.pm
	@$(PERL) index.html
	@$(PERL) pantalla.html
	@$(PERL) control.html
	@$(PERL) preferences.html
	@$(PERL) save.html
	@$(PERL) load.html
	@echo

gds820d: gds820d.o gds820.o
	$(CC) -o gds820d $(CFLAGS) gds820.o gds820d.o

gds820c: gds820c.o gds820.o
	$(CC) -o gds820c $(CFLAGS) gds820.o gds820c.o

install:
	@echo
	@install -m 550 -d -o $(WWWUSER) -g $(WWWGROUP) $(TMPLDIR)/
	@install -m 550 -d -o $(WWWUSER) -g $(WWWGROUP) $(PMDIR)/
	@install -m 550 -d -o $(WWWUSER) -g $(WWWGROUP) $(SCRIPTDIR)/
	@install -m 550 -d -o $(WWWUSER) -g $(WWWGROUP) $(BINDIR)/
	@install -m 750 -d -o $(WWWUSER) -g $(WWWGROUP) $(IMAGESDIR)/
	@install -m 750 -d -o $(WWWUSER) -g $(WWWGROUP) $(TEMPDIR)/
	@install -m 440 -o $(WWWUSER) -g $(WWWGROUP) tmpl/* $(TMPLDIR)/
	@install -m 440 -o $(WWWUSER) -g $(WWWGROUP) images/* $(IMAGESDIR)/
	@echo "1" > $(TEMPDIR)/cursor

	@install -m 550 -D -o $(WWWUSER) -g $(WWWGROUP) gds820.pm $(PMDIR)/gds820.pm
	@install -m 550 -D -o $(WWWUSER) -g $(WWWGROUP) index.html $(SCRIPTDIR)/index.html
#	@install -m 550 -D -o root -g root comd.pl /usr/sbin/comd
	@install -m 550 -D -o root -g root gds820d /usr/sbin/gds820d
	@install -m 755 -D -o root -g root gds820c /usr/bin/gds820c
	@install -m 550 -D -o root -g root gds820.rc /etc/init.d/gds820
	@install -m 550 -D -o $(WWWUSER) -g $(WWWGROUP) comc.pl $(BINDIR)/comc.pl
	@install -m 550 -D -o $(WWWUSER) -g $(WWWGROUP) pantalla.html $(SCRIPTDIR)/pantalla.html
	@install -m 550 -D -o $(WWWUSER) -g $(WWWGROUP) control.html $(SCRIPTDIR)/control.html
	@install -m 550 -D -o $(WWWUSER) -g $(WWWGROUP) preferences.html $(SCRIPTDIR)/preferences.html
	@install -m 550 -D -o $(WWWUSER) -g $(WWWGROUP) save.html $(SCRIPTDIR)/save.html
	@install -m 550 -D -o $(WWWUSER) -g $(WWWGROUP) load.html $(SCRIPTDIR)/load.html

#	@install -m 550 -D -o $(WWWUSER) -g $(WWWGROUP) menu.html $(SCRIPTDIR)/menu.html
	@chown -R $(WWWUSER).$(WWWGROUP) /etc/perl/gds820_setup.pm
	@chown -R $(WWWUSER).$(WWWGROUP) $(TEMPDIR)/cursor

