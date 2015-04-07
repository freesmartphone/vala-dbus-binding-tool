m4_define([vala-dbus-binding-tool_released], [0])
m4_define([vala-dbus-binding-tool_base_version], [1.0])
m4_define([vala-dbus-binding-tool_maybe_gitrev], m4_if(vala-dbus-binding-tool_released, [1], [], [m4_esyscmd([git show-ref --hash=5 HEAD | tr -d '\n\r'])]))
m4_define([vala-dbus-binding-tool_version], m4_if(vala-dbus-binding-tool_released, [1], [vala-dbus-binding-tool_base_version], [vala-dbus-binding-tool_base_version-vala-dbus-binding-tool_maybe_gitrev]))

AC_INIT([vala-dbus-binding-tool], [vala-dbus-binding-tool_version], [fso@openphoenux.org], [vala-dbus-binding-tool])
AC_CONFIG_SRCDIR([src/Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PROG_CC
AM_PROG_CC_C_O
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

#########################################################################################
# Vala building options -- allows tarball builds without installing vala
#########################################################################################

VALA_REQUIRED=0.16.0

AC_ARG_ENABLE([vala], AS_HELP_STRING([--enable-vala],[Enable building from Vala sources]),
              [enable_vala=$enableval], [enable_vala=no])

# Force Vala for non-release builds
m4_if(mdbus_released, [1], [],
      [
        enable_vala=yes
        echo "Vala compiler required for non-release builds; requiring Vala..."
      ])

if test "x$enable_vala" = "xyes" ; then
    AM_PROG_VALAC([$VALA_REQUIRED])
    if test "x$VALAC" = "x" ; then
        AC_MSG_ERROR([Vala requested but valac is not installed])
    fi
fi

AM_CONDITIONAL([HAVE_VALA], [test "x$enable_vala" = "xyes"])

#########################################################################################
# Check for various dependencies
#########################################################################################

AH_TEMPLATE([GETTEXT_PACKAGE], [Package name for gettext])
GETTEXT_PACKAGE=vala-dbus-binding-tool
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE")
AC_SUBST(GETTEXT_PACKAGE)
AM_GLIB_GNU_GETTEXT

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

GEE_REQUIRED=0.8.0
GLIB_REQUIRED=2.18

PKG_CHECK_MODULES(DEPS,
	libxml-2.0
	glib-2.0 >= $GLIB_REQUIRED
	gobject-2.0 >= $GLIB_REQUIRED
	gee-0.8 >= $GEE_REQUIRED)
AC_SUBST(DEPS_CFLAGS)
AC_SUBST(DEPS_LIBS)

AC_CONFIG_FILES([
	Makefile
	vala-dbus-binding-tool-1.0.pc
	man/Makefile
	src/Makefile
])
AC_OUTPUT
