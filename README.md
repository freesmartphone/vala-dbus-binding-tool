VALA-DBUS-BINDING-TOOL 1 "MARCH 2015" Linux "User Manuals"
==========================================

NAME
----

vala-dbus-binding-tool - Create GObject interfaces from DBus introspection files

SYNOPSIS
--------

`vala-dbus-binding-tool` [`--gdbus`] [`--api-path`=*PATH*] [`--no-synced`] [`--dbus-timeout`=*TIMEOUT*] [`--directory`=*DIR*] [`--strip-namespace`=*NS*]\* [`--rename-namespace`=*OLD_NS:NEW_NS*]\*

DESCRIPTION
-----------

This package automates the creation of *GObject* interfaces out of *DBus XML* specifications. Given a well-formatted `.xml` introspection file, you get a corresponding `.vala` file that contains the GObject-interface.

Using autogenerated C-based GObject libraries you can rely on the DBus signatures and types to match – no more handconstructing the method calls.

vala-dbus-binding-tools creates both *synchronous* and *asynchronous* variants of your interfaces. The asynchronous interfaces will contain the suffix `Async`.

OPTIONS
-------

`--help`, `-h`
  Show a brief help text.

`--version`
  Print the current version of this command.

`-v`
  Increase output verbosity.
  
`--api-path`, `-p`
  Where the DBus XML specification files can be found.

`--directory`, `-d`
  Where the output files should be placed.

`--strip-namespace`
  Whether you want to strip a namespace prefix. Can be given multiple times.
  
`--rename-namespace`
  When you want to rename a namespace. Can be given multiple times.

`--dbus-timeout`
  The DBus timeout (in seconds) for asynchronous calls.
  
`--no-synced`
  Only create asynchronous interfaces.

EXAMPLE
-------
Create interfaces for the [freesmartphone.org DBus specifications](https://github.com/freesmartphone/specs) that have been installed at `/usr/local/share/freesmartphone/xml`:

	vala-dbus-binding-tool --api-path=/usr/local/share/freesmartphone/xml --directory=../src --strip-namespace=org --rename-namespace=freedesktop:FreeDesktop --rename-namespace=freesmartphone:FreeSmartphone --gdbus

BUGS
----

Please send bug reports to fso@openphoenux.org or use our issue tracker at [the project page](https://github.com/freesmartphone/vala-dbus-binding-tool/issues).

AUTHORS
------

* Didier "Ptitjes" <ptitjes@free.fr>
* Michael 'Mickey' Lauer <mlauer@vanille-media.de>
* Frederik 'playya' Sdun <Frederik.Sdun@googlemail.com>
* Dominik Fischer <d.f.fischer@web.de>

SEE ALSO
--------

gdbus-codegen(1), [DBus Homepage](http://www.freedesktop.org/dbus), [GDBus](https://developer.gnome.org/gio/stable/gdbus.html)