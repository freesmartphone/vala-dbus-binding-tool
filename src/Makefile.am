AUTOMAKE_OPTIONS = 

AM_CFLAGS = \
	$(DEPS_CFLAGS) \
	-include $(CONFIG_HEADER)
	
VALACFLAGS = \
	--vapidir $(top_srcdir)/vapi \
	--pkg config \
	--pkg glib-2.0 \
	--pkg gee-1.0 \
	--pkg libxml-2.0 \
	--pkg vala-1.0

LDADD = \
	$(DEPS_LIBS)

BUILT_SOURCES = vala_dbus_binding_tool.vala.stamp

bin_PROGRAMS = vala-dbus-binding-tool

vala_dbus_binding_tool_VALASOURCES = \
	vala-dbus-binding-tool.vala

vala_dbus_binding_tool_SOURCES = \
	$(vala_dbus_binding_tool_VALASOURCES:.vala=.c)

vala_dbus_binding_tool.vala.stamp: $(vala_dbus_binding_tool_VALASOURCES)
	$(VALAC) -C ${VALACFLAGS} --basedir . $^
	touch $@

vala_dbus_binding_tool_LDADD = \
	$(DEPS_LIBS)

EXTRA_DIST = \
	$(vala_dbus_binding_tool_VALASOURCES) \
	vala_dbus_binding_tool.vala.stamp

CLEANFILES = \
	*.c \
	*.h \
	vala_dbus_binding_tool.vala.stamp
