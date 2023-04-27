project('vala-dbus-binding-tool', ['c', 'vala'],
    version: '1.0.0',
    meson_version:'>=0.49.0',
)

valac = meson.get_compiler('vala')

if valac.version().version_compare('<0.30')
    error('Missing required dependency: valac >= 0.30')
endif

libxml_min_version = '2.9.4'
glib_min_version = '2.18'
gee_min_version = '0.8.0'

libxml_dep = dependency('libxml-2.0', version: '>=@0@'.format(libxml_min_version))
glib_dep = dependency('glib-2.0', version: '>=@0@'.format(glib_min_version))
gobject_dep = dependency('gobject-2.0', version: '>=@0@'.format(glib_min_version))
gee_dep = dependency('gee-0.8', version: '>=@0@'.format(gee_min_version))

config_vapi = valac.find_library('config', dirs: meson.current_source_dir() / 'vapi')

config_data = configuration_data()
config_data.set_quoted('PACKAGE_VERSION', meson.project_version())

config_header = configure_file(
    configuration: config_data,
    output: 'config.h'
)

config_dep = declare_dependency(
    dependencies: config_vapi,
    include_directories: include_directories('.'),
    sources: config_header,
)

executable('vala-dbus-binding-tool',
    'src/vala-dbus-binding-tool.vala',
    dependencies: [
        config_dep,
        libxml_dep,
        glib_dep,
        gobject_dep,
        gee_dep,
    ],
    install: true,
)

pkg = import('pkgconfig')

pkg.generate(
    filebase: 'vala-dbus-binding-tool-1.0',
    name: 'Vala-DBus-Binding-Tool',
    description: 'The Vala DBus Binding Tool',
    version: meson.project_version(),
)

install_man('man/vala-dbus-binding-tool.1')
