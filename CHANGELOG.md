# Changelog
All notable changes to vala-dbus-binding-tool will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Added
- A manpage (@mickeyl)

### Changed
- Modernized some Vala constructs (@tintou)
- Bring back the high-level ChangeLog format (@mickeyl)

### Removed
- glib-dbus support (@tintou)

## [0.4.1] - 2015-02-04

2015-02-04  Dr. Michael Lauer  <mickey@vanille-media.de>

	README++

	fix mailing list in configure.ac

	fix mixed up indendation styles and update (C) with proper mailing list address

	Merge pull request #3 from dffischer/libgee
	update libgee dependency

2014-11-05  XZS  <d.f.fischer@web.de>

	remove functions from map and set constructors
	The new libgee creates the adequate functions automatically.

	This commit restores correct compilation.

	update configuration for newer libgee
	This revision will not compile. Further commits will restore
	functionality by modification of the sources to use the newer API.

	Conversely, libgee-0.8 is indeed newer than libgee-1.0. The projects
	homepage <https://wiki.gnome.org/action/show/Projects/Libgee> states
	under "Versions": "From version 0.1 to 0.6 the suffix for the libgee was
	1.0 even though the API and ABI was not always kept stable."

2014-11-05  Dr. Michael Lauer  <mickey@vanille-media.de>

	Merge pull request #2 from dffischer/readonly
	support "read" as an access modifier

	Merge pull request #1 from dffischer/recursive-structs
	Support recursive structs

2014-11-04  XZS  <d.f.fischer@web.de>

	treat access modifier "read" as "readonly"
	Some descriptions use just "read" to mean "readonly". It is unambiguous
	enough to assume their equivalence.

2014-07-24  Dominik Fischer  <d.f.fischer@web.de>

	accept "read" as a valid access type as well

	copy map of structs to create before iteration
	In case of nested structs like "(b(oss))", structs_to_create could be
	modified while it is currently iterated. This violates assertions in
	libgee and crashes the program. Iterate over a copy instead, then
	continue iterating with the difference set to create nested structs.

	save a call to Map.get by iterating entries

2012-06-01  Simon Busch  <morphis@gravedo.de>

	Complex types needs an owned get accessor

2012-05-30  Simon Busch  <morphis@gravedo.de>

	Update for release of version 0.4.0

	Properties in vala interfaces needs to be abstract

	Add support for properties in the interface definition

	Add support for deprecated element in the XML specification

2011-05-23  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	get rid of intltool

2011-02-24  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	catch up with deprecations, bump Vala and Gee requirements

2011-02-03  Klaus Kurzmann  <mok@fluxnetz.de>

	emit [DBus (name = ...)] for signals too

2011-02-02  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	fix emitting [DBus name()] directives

	always emit [DBus (name = ...)] in order to cope with DBus interfaces violating the DBus CamelCase naming scheme

2010-11-01  Frederik 'playya' Sdun  <Frederik.Sdun@googlemail.com>

	gdbus: generate convinience method to convert Variants to structs

2010-10-26  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	gdbus methods need to throw at least IOError, DBusError

2010-10-10  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	post-release version bump

	add command line argument --gdbus. This will emit code that uses gio-2.0 instead of dbus(-glib).

2010-10-04  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	new way to detect Vala

2010-09-09  Frederik 'playya' Sdun  <Frederik.Sdun@googlemail.com>

	Generate sync proxy getter

2010-08-29  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	we don't need anything from vala-1.0.vapi

	bump vala dependency

2010-07-16  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	try harder to detect invalid type dict and tuple signatures

2010-06-23  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	refer to ObjectPath fully qualified as there are now two implementations (one in gio-2.0 one in dbus-glib-1)

2010-06-07  Frederik 'playya' Sdun  <Frederik.Sdun@googlemail.com>

	Add config.vapi to EXTRA_DIST Based on a patch by David Wagner

2010-05-29  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	provide support for specifying methods as no-reply

2010-04-19  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	enable generating synchronized versions of dbus interfaces in addition
	synchronized versions will have the name <Interface>Sync, which
	allows for synchronized calls, which may come in handy at times.
	If you do not want to have that, pass the argument --no-synced

2010-04-09  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	post-release-bump

	map 'y' (BYTE) to uint8 instead of uchar; the latter crashed until today.
	For details see https://bugzilla.gnome.org/show_bug.cgi?id=615282

2010-03-28  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	post-release version bump

	support the new [DBus (timeout = %u)] attribute to override the default timeout effective in static dbus client method calls. NOTE that dynamic calls still use the default bus timeout (25 seconds in unpatched dbus daemons...)

2010-03-21  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	improve error output

	indentation fixes

	fix CRITICAL when error domain can not be found count number of errors and warn user if generated files are not usable

	convert stdout.printf into ERROR calls

	add -v option

2010-03-19  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	post-release version bump

2010-03-19  Frederik 'playya' Sdun  <Frederik.Sdun@googlemail.com>

	Add proxy getter generation and respect style of the author

2010-03-18  Frederik 'playya' Sdun  <Frederik.Sdun@googlemail.com>

	Remove unused variable

	Remove proxy class generation

2010-03-15  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	unify indentation; please respect the style of the original author (tabs, no spaces)

2010-02-13  Frederik 'playya' Sdun  <Frederik.Sdun@googlemail.com>

	Fix generation of nested complex types Fix Ctors of explicit structs

2010-01-12  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	post-release version bump

	fix make distcheck after bootstrapping from git

	cosmetic fix

	add convenience constructor for explicit structs

2010-01-10  Frederik 'playya' Sdun  <Frederik.Sdun@googlemail.com>

	Revert "more debian/ stuff"
	This reverts commit ea6252adc1d7ab5a3953d00f3a38fbcc0151a4d7.

	Revert "Fix name of the .pc file"
	This reverts commit 3320e5a2b6bb0b95eef41e227608e49e9aa44dd1.

	Revert "Fix glib depency"
	This reverts commit 3a3486a592e000ff1030f9cc7084fcb9916a5a3d.

	Add class generation for interface

2009-12-25  Frederik 'playya' Sdun  <Frederik.Sdun@googlemail.com>

	Fix glib depency

	Fix name of the .pc file

	Merge branch 'master' of fso:vala-dbus-binding-tool

	more debian/ stuff

2009-12-25  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	post-release version bump

	grab program version from build system

	add source file header

2009-11-13  Frederik 'playya' Sdun  <Frederik.Sdun@googlemail.com>

	Add debian/

2009-11-05  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	enable silent rules, if available

2009-10-17  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	do not link against vala, but rather gee upstream

2009-09-18  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	post-release version bump

2009-09-17  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	create and install .pc file, so we can easily track the version

	fix make dist

	bump version and vala requirement

2009-09-14  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	fix position of async qualifier

	catch up with new 'async' keyword for methods. replaces 'yields'

2009-08-26  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	typechange: po/Makefile.in.in

2009-07-14  Didier 'Ptitjes  <ptitjes@free.fr>

	Add yields for dbus async methods

2009-07-03  Didier 'Ptitjes  <ptitjes@free.fr>

	Merge parameters and throws iteration loop

2009-05-24  Frederik 'playya' Sdun  <Frederik.Sdun@googlemail.com>

	name unnamed parameters for signals

	Name unnamed parameters

2009-05-22  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	use standard autogen.sh

2009-05-17  Didier 'Ptitjes  <ptitjes@free.fr>

	Fix licence

	Fix intl files

2009-05-16  Didier 'Ptitjes  <ptitjes@free.fr>

	Introduce a temporary hack before type parse enhancements

	Fix errordomain & namespace name clashes
	- Introduce fso:no-container boolean attribute
	    (i.e. errordomain has no proper name)
	- Compute names accordingly
	- Adds error_name_index for the indexing of errordomains

2009-05-11  Didier 'Ptitjes  <ptitjes@free.fr>

	Fix use of GLib.Dir

2009-05-06  Didier 'Ptitjes  <ptitjes@free.fr>

	Fix integer enum values

	Enable parameter structs description

	Fix method names that are registered names

	[#418] Add support for errors in XML specs

2009-04-30  Didier 'Ptitjes  <ptitjes@free.fr>

	[#417 - Part 2] Use fso:type to reference string enumerations

2009-04-29  Didier 'Ptitjes  <ptitjes@free.fr>

	Index Vala names per DBus names prior to generation

	[#417 - Part 1] Generate enumerations

2009-04-28  Didier 'Ptitjes  <ptitjes@free.fr>

	Fix for GLib.Dir API breakout

2009-04-26  Michael 'Mickey' Lauer  <mickey@vanille-media.de>

	add .gitignore

2009-04-15  Didier Villevalois  <didier@didier.local>

	Fix non-propagated generator error

	Fix indentation on empty lines for better diff behavior

	Remove silly debug messages

	Fix missing closing brace from commit de5398704c072d942663c71502fc043c292fcf54

2009-04-06  Frederik 'playya' Sdun  <Frederik.Sdun@googlemail.com>

	add null check for void returntypes

2009-04-05  Frederik 'playya' Sdun  <Frederik.Sdun@googlemail.com>

	Revert "add null check for void returntypes"
	This reverts commit e35b4711a9a2010a007b9ae3f0ba85f5b902a126.

2009-04-02  Frederik 'playya' Sdun  <Frederik.Sdun@googlemail.com>

	add null check for void returntypes

2009-02-17  Didier 'Ptitjes  <ptitjes@free.fr>

	Enable concatenation of inner interfaces names Signed-off-by: Didier 'Ptitjes <ptitjes@free.fr>

2009-02-12  Didier 'Ptitjes  <ptitjes@free.fr>

	Handle get_type registered name. Signed-off-by: Didier 'Ptitjes <ptitjes@free.fr>

	Added GLib.Object prerequisite to generated interfaces. Manage registered C and Vala names. Signed-off-by: Didier 'Ptitjes <ptitjes@free.fr>

2009-02-04  Didier 'Ptitjes  <ptitjes@free.fr>

	Initial commit Signed-off-by: Didier 'Ptitjes <ptitjes@free.fr>
