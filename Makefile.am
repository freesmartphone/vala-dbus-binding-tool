AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	po \
	src

pkgconfigdir = $(libdir)/pkgconfig
dist_pkgconfig_DATA = vala-dbus-binding-tool-1.0.pc

EXTRA_DIST = \
	intltool-extract.in \
	intltool-update.in \
	intltool-merge.in \
	AUTHORS \
	MAINTAINERS \
	vapi

DISTCLEANFILES = \
	intltool-extract \
	intltool-update \
	intltool-merge \
	po/.intltool-merge-cache
