/*
 * vala-dbus-binding-tool.vala
 *
 * (C) 2009 by Didier "Ptitjes" <ptitjes@free.fr>
 * (C) 2009-2015 the freesmartphone.org team <fso@openphoenux.org>
 *
 * GPLv3
 */
using GLib;
using Xml;
using Gee;

public errordomain GeneratorError {
	FILE_NOT_FOUND,
	CANT_CREATE_FILE,
	UNKNOWN_DBUS_TYPE
}

public enum Synchrony {
	AUTO,
	FORCE_SYNC,
	FORCE_ASYNC
}

internal class GeneratedNamespace {
	public GeneratedNamespace parent;
	public string name;
	public Gee.Map<string, Xml.Node*> members = new Gee.HashMap<string, Xml.Node*>();
	public Gee.Map<string, GeneratedNamespace> namespaces = new Gee.HashMap<string, GeneratedNamespace>();
}

public class BindingGenerator : Object {

	private static Set<string> registered_names = new HashSet<string>();
	private static int verbosity;
	private static int errors;
	private static bool synced;

	static construct {
		registered_names.add("using");
		registered_names.add("namespace");
		registered_names.add("public");
		registered_names.add("private");
		registered_names.add("register");
		registered_names.add("internal");
		registered_names.add("errordomain");
		registered_names.add("class");
		registered_names.add("struct");
		registered_names.add("new");
		registered_names.add("for");
		registered_names.add("while");
		registered_names.add("foreach");
		registered_names.add("switch");
		registered_names.add("catch");
		registered_names.add("case");
		registered_names.add("static");
		registered_names.add("unowned");
		registered_names.add("weak");
		registered_names.add("message");
		registered_names.add("get_type");
		registered_names.add("dispose");
		registered_names.add("result");
	}

	public static void INFO(string msg) {
		if (verbosity >= 1)
			stdout.printf(@"[INFO]  $msg\n");
	}

	public static void DEBUG(string msg) {
		if (verbosity >= 2)
			stdout.printf(@"[DEBUG] $msg\n");
	}

	public static void WARN(string msg) {
		stderr.printf(@"[WARN]  $msg\n");
	}

	public static void ERROR(string msg) {
		stderr.printf(@"[ERROR] $msg\n");
		errors++;
	}

	public static int main(string[] args) {
		//FIXME: Convert to OptionEntry
		string[] split_name = args[0].split("/");
		string program_name = split_name[split_name.length - 1];
		string command = string.joinv(" ", args);

		string api_path = null;
		string output_directory = null;
		uint dbus_timeout = 120000;
		synced = true;

		Map<string,string> namespace_renaming = new HashMap<string,string>();

		for (int i = 1; i < args.length; i++) {
			string arg = args[i];

			string[] split_arg = arg.split("=");
			switch (split_arg[0]) {
			case "-h":
			case "--help":
				show_usage(program_name);
				return 0;
			case "-v":
				verbosity++;
				break;
			case "--version":
				show_version();
				return 0;
			case "--api-path":
				api_path = split_arg[1];
				break;
			case "-d":
			case "--directory":
				output_directory = split_arg[1];
				break;
			case "--strip-namespace":
				namespace_renaming.set(split_arg[1], "");
				break;
			case "--rename-namespace":
				string[] ns_split = split_arg[1].split(":");
				namespace_renaming.set(ns_split[0], ns_split[1]);
				break;
			case "--dbus-timeout":
				dbus_timeout = int.parse( split_arg[1] );
				break;
			case "--no-synced":
				synced = false;
				break;
			default:
				stdout.printf("%s: Unknown option %s\n", program_name, arg);
				show_usage(program_name);
				return 1;
			}
		}

		if (api_path == null)
			api_path = "./";
		if (output_directory == null)
			output_directory = ".";

		try {
			generate(api_path, output_directory, namespace_renaming, command, dbus_timeout);
		} catch (GLib.FileError ex) {
			ERROR(ex.message);
			return 1;
		} catch (GeneratorError ex) {
			ERROR(ex.message);
			return 1;
		}

		if (errors > 0) {
			stdout.printf( @"\n$errors errors detected in API files. The generated files will not be usable.\n" );
			return 1;
		}
		return 0;
	}

	private static void show_version() {
		stdout.printf(@"Vala D-Bus Binding Tool $(Config.PACKAGE_VERSION)\n");
		stdout.printf("Written by Didier \"Ptitjes\" and the freesmartphone.org team\n");
		stdout.printf("This is free software; see the source for copying conditions.\n");
		stdout.printf("There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\n");
	}

	private static void show_usage(string program_name) {
		stdout.printf("Usage:\n");
		stdout.printf("  %s [-v] [--version] [--help]\n", program_name);
		stdout.printf("  %s [--api-path=PATH] [--no-synced] [--dbus-timeout=TIMEOUT] [--directory=DIR] [--strip-namespace=NS]* [--rename-namespace=OLD_NS:NEW_NS]*\n", program_name);
	}

	public static void generate(string api_path, string output_directory,
			Map<string,string> namespace_renaming, string command, uint dbus_timeout)
			throws GeneratorError, GLib.FileError {

		Parser.init();

		BindingGenerator generator = new BindingGenerator(output_directory, namespace_renaming, command, dbus_timeout);
		generator.generate_bindings(api_path);

		Parser.cleanup();
	}

	private BindingGenerator(string output_directory, Map<string,string> namespace_renaming, string command, uint dbus_timeout) {
		this.output_directory = output_directory;
		this.namespace_renaming = namespace_renaming;
		this.command = command;
		this.dbus_timeout = dbus_timeout;
	}

	private string output_directory;
	private Map<string,string> namespace_renaming;
	private string command;
	private uint dbus_timeout;
	private bool inner_interface_strategy_concat = true;

	private const string FSO_NAMESPACE = "http://www.freesmartphone.org/schemas/DBusSpecExtension";

	private const string INTERFACE_ELTNAME = "interface";
	private const string METHOD_ELTNAME = "method";
	private const string SIGNAL_ELTNAME = "signal";
	private const string PROPERTY_ELTNAME = "property";
	private const string ARG_ELTNAME = "arg";
	private const string NAME_ATTRNAME = "name";
	private const string TYPE_ATTRNAME = "type";
	private const string DIRECTION_ATTRNAME = "direction";
	private const string REPLACED_BY_ATTRNAME = "replaced-by";
	private const string IN_ATTRVALUE = "in";
	private const string OUT_ATTRVALUE = "out";
	private const string ENUMERATION_ELTNAME = "enumeration";
	private const string MEMBER_ELTNAME = "member";
	private const string VALUE_ATTRNAME = "value";
	private const string ERRORDOMAIN_ELTNAME = "errordomain";
	private const string ERROR_ELTNAME = "error";
	private const string NO_CONTAINER_ATTRNAME = "no-container";
	private const string THROWS_ELTNAME = "throws";
	private const string STRUCT_ELTNAME = "struct";
	private const string FIELD_ELTNAME = "field";
	private const string ANNOTATION_ELTNAME = "annotation";
	private const string DEPRECATED_ELTNAME = "deprecated";

	private void generate_bindings(string api_path)
			throws GeneratorError, GLib.FileError {

		if (api_path.has_suffix(".xml")) {
			add_api_file(api_path);
		} else {
			GLib.Dir dir = GLib.Dir.open(api_path);
			string name;
			while ((name = dir.read_name()) != null) {
				if (name.has_suffix(".xml")) {
					add_api_file(Path.build_filename(api_path, name));
				}
			}
		}

		index_names(root_namespace);
		generate_namespace(root_namespace);
	}

	private void add_api_file(string api_file) throws GeneratorError {
		INFO(@"Adding API file $api_file");
		// Parse the API document from path
		Xml.Doc* api_doc = Parser.parse_file(api_file);
		if (api_doc == null) {
			throw new GeneratorError.FILE_NOT_FOUND(api_file);
		}

		api_docs.add(api_doc);

		preprocess_binding_names(api_doc);
	}

	private FileStream output;

	private void create_binding_file(string name) throws GeneratorError {
		output = FileStream.open(name, "w");
		if (output == null) {
			throw new GeneratorError.CANT_CREATE_FILE(name);
		}

		output.printf(@"/* Generated by vala-dbus-binding-tool $(Config.PACKAGE_VERSION). Do not modify! */\n");
		output.printf(@"/* Generated with: $command */\n");
		output.printf("using GLib;\n");
	}

	private Gee.List<Xml.Doc*> api_docs = new Gee.ArrayList<Xml.Doc*>();

	private void preprocess_binding_names(Xml.Doc* api_doc) {
		for (Xml.Node* iter = api_doc->get_root_element()->children; iter != null; iter = iter->next) {
			//FIXME: Use $(iter->type) when enum to_string works
			DEBUG(@"   Processing $(iter->name) as type %d".printf(iter->type));
			if (iter->type != ElementType.ELEMENT_NODE) {
				DEBUG(@"      not a node; continuing");
				continue;
			}

			if (iter->name != INTERFACE_ELTNAME
				&& iter->name != ENUMERATION_ELTNAME
				&& iter->name != ERRORDOMAIN_ELTNAME
				&& iter->name != STRUCT_ELTNAME) {
				DEBUG(@"      not interface or enumeration or errordomain or struct; continuing");
				continue;
			}

			string no_error_container_string = iter->get_ns_prop(NO_CONTAINER_ATTRNAME, FSO_NAMESPACE);
			bool no_error_container = (no_error_container_string != null && no_error_container_string == "true");

			string dbus_interface_name = iter->get_prop(NAME_ATTRNAME);
			string[] split_name = dbus_interface_name.split(".");
			string short_name;
			int last_part;
			if (iter->name == ERRORDOMAIN_ELTNAME && no_error_container) {
				short_name = "Error";
				last_part = split_name.length;
			} else {
				short_name = split_name[split_name.length - 1];
				last_part = split_name.length - 1;
			}

			// Removing stripped root namespaces
			int i = 0;
			for (; i < last_part; i++) {
				string part = split_name[i];
				if (namespace_renaming.get(part) != "") break;
			}

			// Traversing inner namespaces
			GeneratedNamespace ns = root_namespace;
			for (; i < last_part; i++) {
				string part = split_name[i];

				if (namespace_renaming.has_key(part) && namespace_renaming.get(part) != "") {
					part = namespace_renaming.get(part);
				}

				if (ns.members.has_key(part) && inner_interface_strategy_concat) {
					if (ns.namespaces.has_key(part)) {
						GeneratedNamespace child = ns.namespaces.get(part);
						foreach (string interf_name in child.members.keys) {
							Xml.Node* interf = child.members.get(interf_name);
							ns.members.set(part + interf_name, interf);
						}
						ns.namespaces.unset(part);
						child.parent = null;
					}

					break;
				}

				GeneratedNamespace child = null;
				if (ns.namespaces.has_key(part)) {
					child = ns.namespaces.get(part);
				} else {
					child = new GeneratedNamespace();
					child.parent = ns;
					child.name = part;
					ns.namespaces.set(part, child);
				}

				if (ns.members.has_key(part)) {
						child.members.set(part, ns.members.get(part));
						ns.members.unset(part);
				}

				ns = child;
			}

			string interface_name = null;
			if (inner_interface_strategy_concat) {
				StringBuilder name_builder = new StringBuilder();
				// Concatenating last inner namespaces
				for (; i < last_part; i++) {
					name_builder.append(split_name[i]);
				}
				name_builder.append(short_name);
				interface_name = name_builder.str;

				if (ns.namespaces.has_key(short_name)) {
					GeneratedNamespace child = ns.namespaces.get(short_name);
					foreach (string interf_name in child.members.keys) {
						Xml.Node* interf = child.members.get(interf_name);
						ns.members.set(short_name + interf_name, interf);
					}
					ns.namespaces.unset(short_name);
					child.parent = null;
				}
			} else {
				if (ns.namespaces.has_key(short_name)) {
					ns = ns.namespaces.get(short_name);
				}
				interface_name = short_name;
			}

			if (!ns.members.has_key(interface_name)) {
				ns.members.set(interface_name, iter);
			} else {
				Xml.Node* iter2 = ns.members.get(interface_name);
				var name = iter2->get_prop(NAME_ATTRNAME);
				ERROR(@"$interface_name has been added already as namespace $name");
			}
		}
	}

	private void index_names(GeneratedNamespace ns) {
		if (ns.members.size > 0) {
			string namespace_name = string.joinv(".", get_namespace_path(ns));

			foreach (string name in ns.members.keys) {
				Xml.Node* api = ns.members.get(name);
				string dbus_name = api->get_prop(NAME_ATTRNAME);
				if (api->name == ERRORDOMAIN_ELTNAME) {
					INFO(@"Registering new errordomain $dbus_name");
					error_name_index.set(dbus_name, namespace_name + "." + name);
				} else {
					name_index.set(dbus_name, namespace_name + "." + name);
				}
			}
		}

		foreach (string name in ns.namespaces.keys) {
			GeneratedNamespace child = ns.namespaces.get(name);

			index_names(child);
		}
	}

	private string[] get_namespace_path(GeneratedNamespace ns) {
		string[] reversed_namespace_names = new string[0];
		GeneratedNamespace a_namespace = ns;
		while (a_namespace.name != null) {
			reversed_namespace_names += a_namespace.name;
			a_namespace = a_namespace.parent;
		}

		string[] namespace_names = new string[0];
		for (int i = reversed_namespace_names.length - 1; i >= 0; i--) {
			namespace_names += reversed_namespace_names[i];
		}

		return namespace_names;
	}

	private GeneratedNamespace root_namespace = new GeneratedNamespace();

	private Map<string, string> name_index = new HashMap<string, string>();
	private Map<string, string> error_name_index = new HashMap<string, string>();

	private void generate_namespace(GeneratedNamespace ns)
			throws GeneratorError {
		if (ns.members.size > 0) {
			string[] namespace_names = get_namespace_path(ns);

			create_binding_file(output_directory + "/" + string.joinv("-", namespace_names).down() + ".vala");

			foreach (string name in namespace_names) {
				output.printf("\n");
				output.printf("%snamespace %s {\n", get_indent(), name);
				update_indent(+1);
			}

			foreach (string name in ns.members.keys) {
				Xml.Node* api = ns.members.get(name);

				switch (api->name) {
				case INTERFACE_ELTNAME:
					generate_interface(name, api, Synchrony.AUTO);
					generate_proxy_getter(api, name);
					if ( synced )
						generate_interface(name, api, Synchrony.FORCE_SYNC);
						generate_proxy_getter(api, name, Synchrony.FORCE_SYNC);
					break;
				case ENUMERATION_ELTNAME:
					generate_enumeration(name, api);
					break;
				case ERRORDOMAIN_ELTNAME:
					generate_errordomain(name, api);
					break;
				case STRUCT_ELTNAME:
					generate_explicit_struct(name, api);
					break;
				}
			}

			foreach (string name in namespace_names) {
				update_indent(-1);
				output.printf("%s}\n", get_indent());
			}

			output = null;
		}

		foreach (string name in ns.namespaces.keys) {
			GeneratedNamespace child = ns.namespaces.get(name);

			generate_namespace(child);
		}
	}

	private Gee.Map<string, string> structs_to_generate = new Gee.HashMap<string, string>();

	private void generate_interface(string interface_name, Xml.Node* node, Synchrony synchrony = Synchrony.AUTO)
			throws GeneratorError {
		string dbus_name = node->get_prop(NAME_ATTRNAME);
		string namespace_name = get_namespace_name(interface_name);

		assert( synchrony != Synchrony.FORCE_ASYNC ); // not supported yet, maybe never

		var iface_name = ( synchrony == Synchrony.FORCE_SYNC ) ? interface_name + "Sync" : interface_name;

		INFO(@"Generating interface $dbus_name");

		output.printf("\n");
		output.printf("%s[DBus (name = \"%s\", timeout = %u)]\n", get_indent(), dbus_name, dbus_timeout);
		output.printf("%spublic interface %s : GLib.Object {\n", get_indent(), iface_name);
		update_indent(+1);

		generate_members(node, iface_name, get_namespace_name(dbus_name), synchrony);

		update_indent(-1);
		output.printf("%s}\n", get_indent());

		while (structs_to_generate.size != 0) {
			Gee.Map<string, string> structs_to_generate_now	= new Gee.HashMap<string, string>();
			structs_to_generate_now.set_all(structs_to_generate);
			foreach (var entry in structs_to_generate_now.entries) {
				generate_struct(entry.key, entry.value, namespace_name);
			}
			structs_to_generate.unset_all(structs_to_generate_now);
		}
	}

	private void generate_enumeration(string enumeration_name, Xml.Node* node) throws GeneratorError {
		string dbus_name = node->get_prop(NAME_ATTRNAME);
		string type = node->get_prop(TYPE_ATTRNAME);
		bool string_enum = type == "s";

		INFO(@"Generating enumeration $type for $dbus_name");

		output.printf("\n");
		output.printf("%s[DBus%s]\n", get_indent(), string_enum ? " (use_string_marshalling = true)" : "");
		output.printf("%spublic enum %s {\n", get_indent(), enumeration_name);
		update_indent(+1);

		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE)
				continue;

			switch (iter->name) {
			case MEMBER_ELTNAME:
				string member_name = normalized_to_upper_case(iter->get_prop(NAME_ATTRNAME));
				string member_value = iter->get_prop(VALUE_ATTRNAME);
				if (string_enum) {
					output.printf("%s[DBus (value=\"%s\")]\n", get_indent(), member_value);
				}
				output.printf("%s%s%s%s\n", get_indent(), member_name, string_enum ? "" : " = %s".printf(member_value), iter->next == null ? "" : ",");
				break;
			}
		}

		update_indent(-1);
		output.printf("%s}\n", get_indent());
	}

	private void generate_errordomain(string errordomain_name, Xml.Node* node)
			throws GeneratorError {
		string dbus_name = node->get_prop(NAME_ATTRNAME);

		INFO(@"Generating errordomain $errordomain_name for $dbus_name");

		output.printf("\n");
		output.printf("%s[DBus (name = \"%s\")]\n", get_indent(), dbus_name);
		output.printf("%spublic errordomain %s {\n", get_indent(), errordomain_name);
		update_indent(+1);

		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE)
				continue;

			switch (iter->name) {
			case ERROR_ELTNAME:
				string dbus_error_name = iter->get_prop(NAME_ATTRNAME);
				string error_name = camel_case_to_upper_case(dbus_error_name);

				output.printf("%s[DBus (name = \"%s\")]\n", get_indent(), dbus_error_name);
				output.printf("%s%s%s\n", get_indent(), error_name, iter->next == null ? "" : ",");
				break;
			}
		}

		update_indent(-1);
		output.printf("%s}\n", get_indent());
	}

	private void generate_explicit_struct(string struct_name, Xml.Node* node)
			throws GeneratorError {
		string dbus_name = node->get_prop(NAME_ATTRNAME);

		INFO(@"Generating explicit struct $struct_name for $dbus_name");

		output.printf("\n");
		output.printf("%spublic struct %s {\n", get_indent(), struct_name);
		update_indent(+1);

		string ctor_signature = "%spublic %s (".printf(get_indent(), struct_name);
		string ctor_body = "";

		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE)
				continue;

			switch (iter->name) {
			case FIELD_ELTNAME:
				string field_name = transform_registered_name(iter->get_prop(NAME_ATTRNAME));
				string field_type = "unknown";
				try {
					field_type = translate_type(iter->get_prop(TYPE_ATTRNAME),
						iter->get_ns_prop(TYPE_ATTRNAME, FSO_NAMESPACE),
						struct_name, get_namespace_name(dbus_name));
				} catch (GeneratorError.UNKNOWN_DBUS_TYPE ex) {
					ERROR(@"In struct $struct_name field $field_name : Unknown dbus type $(ex.message)");
				}

				output.printf("%spublic %s %s;\n", get_indent(), field_type, field_name);
					ctor_signature += "%s %s, ".printf(field_type, field_name);
					ctor_body += "%sthis.%s = %s;\n".printf(get_indent(+1), field_name, field_name);
					break;
				}
			}
		string constructor = "%s ) {\n%s%s}".printf( ctor_signature.substring( 0, ctor_signature.length-2 ), ctor_body, get_indent() );

		output.printf("\n%s\n", constructor);

		INFO(@"Generating from_variant method for $struct_name");
		output.printf("\n%spublic static %s from_variant (Variant v) {\n", get_indent(), struct_name);
		update_indent(1);
		output.printf("%sreturn v as %s;\n", get_indent(), struct_name);
		update_indent(-1);
		output.printf("%s}\n", get_indent());
		update_indent(-1);
		output.printf("%s}", get_indent());
	}

	private void generate_struct(string name, string content_signature, string dbus_namespace)
					throws GeneratorError {
		INFO(@"Generating struct $name w/ signature $content_signature in dbus namespace $dbus_namespace");

		output.printf("\n");
		output.printf("%spublic struct %s {\n", get_indent(), name);
		update_indent(+1);

		int attribute_number = 1;
		string signature = content_signature;
		string tail = null;
		while (signature != "") {
			string type = parse_type(signature, out tail, "", dbus_namespace);
			output.printf("%spublic %s attr%d;\n", get_indent(), type, attribute_number);
			attribute_number++;
			signature = tail;
		}

		update_indent(-1);
		output.printf("%s}\n", get_indent());
	}

	private void generate_members(Xml.Node* node, string interface_name, string dbus_namespace, Synchrony synchrony)
					throws GeneratorError {
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE)
				continue;

			switch (iter->name) {
			case METHOD_ELTNAME:
				generate_method(iter, interface_name, dbus_namespace, synchrony);
				break;
			case SIGNAL_ELTNAME:
				generate_signal(iter, interface_name, dbus_namespace);
				break;
			case PROPERTY_ELTNAME:
				generate_property(iter, interface_name, dbus_namespace);
				break;
			case ERROR_ELTNAME:
				generate_error(iter, interface_name);
				break;
			}
		}
	}

	private void generate_method(Xml.Node* node, string interface_name, string dbus_namespace, Synchrony synchrony)
					throws GeneratorError {

		string realname = node->get_prop(NAME_ATTRNAME);
		string name = transform_registered_name(uncapitalize(node->get_prop(NAME_ATTRNAME)));

		INFO(@"   Generating method $name (originally $realname) for $interface_name");

		int unknown_param_count = 0;

		int out_param_count = get_out_parameter_count(node);

		bool first_param = true;
		bool first_error = true;
		StringBuilder args_builder = new StringBuilder();
		StringBuilder throws_builder = new StringBuilder();
		string return_value_type = "void";
		bool async_method = false;
		bool noreply_method = false;
		bool deprecated_method = false;
		string deprecated_method_replaced_by = "";

		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE)
				continue;

			switch (iter->name) {
			case ARG_ELTNAME:
				string? param_name = transform_registered_name(iter->get_prop(NAME_ATTRNAME));
				if(param_name == null || param_name == "") {
					param_name = "param%i".printf(unknown_param_count);
					unknown_param_count++;
				}
				string param_type = "unknown";
				try {
					param_type = translate_type(iter->get_prop(TYPE_ATTRNAME),
						iter->get_ns_prop(TYPE_ATTRNAME, FSO_NAMESPACE),
						get_struct_name(interface_name, param_name),
						dbus_namespace);
				} catch (GeneratorError.UNKNOWN_DBUS_TYPE ex) {
					ERROR(@"In interface $interface_name method $name : Unknown dbus type $(ex.message)");
				}
				string? param_dir = iter->get_prop(DIRECTION_ATTRNAME);

				switch (param_dir) {
				case OUT_ATTRVALUE:
					if (param_type == null) {
						param_type = "void";
					}
					if (out_param_count != 1) {
						if (!first_param) {
							args_builder.append(", ");
						}

						args_builder.append("out ");
						args_builder.append(param_type);
						args_builder.append(" ");
						args_builder.append(param_name);
						first_param = false;
					} else {
						return_value_type = param_type;
					}
					break;
				case IN_ATTRVALUE:
				default:
					if (!first_param) {
						args_builder.append(", ");
					}

					args_builder.append(param_type);
					args_builder.append(" ");
					args_builder.append(param_name);
					first_param = false;
					break;
				}
				break;
			case THROWS_ELTNAME:
				string errordomain_name = null;
				string fso_type = iter->get_prop(TYPE_ATTRNAME);
				if (fso_type != null) {
					errordomain_name = error_name_index.get(fso_type);
				}
				if (errordomain_name == null) {
					ERROR(@"In interface $interface_name method $name : Unknown dbus error $(fso_type)");
					errordomain_name = "<unknown>";
				}

				if (!first_error) {
					throws_builder.append(", ");
				}
				throws_builder.append(errordomain_name);
				first_error = false;
				break;
			case ANNOTATION_ELTNAME:
				string annotation_name = iter->get_prop(NAME_ATTRNAME);
				if (annotation_name == "org.freedesktop.DBus.GLib.Async") {
					async_method = true;
				}
				if (annotation_name == "org.freedesktop.DBus.GLib.NoReply") {
					noreply_method = true;
				}
				break;
			case DEPRECATED_ELTNAME:
				deprecated_method = true;
				deprecated_method_replaced_by = iter->get_prop(REPLACED_BY_ATTRNAME);
				break;
			}
		}

		if (async_method && noreply_method) {
			WARN(@"In interface $interface_name method $name : Requested both async and noreply; which is not supported by Vala. Will force sync.");
			async_method = false;
		}

		if (noreply_method && out_param_count > 0) {
			ERROR(@"In interface $interface_name method $name : noreply methods are not allowed to have out parameters!");
		}

		if (!first_error) {
			throws_builder.append(", ");
		}
		throws_builder.append("DBusError, IOError");

		switch ( synchrony )
		{
			case Synchrony.FORCE_SYNC:
				async_method = false;
				break;
			case Synchrony.FORCE_ASYNC:
				async_method = true;
				break;
			default:
				/* AUTO, leave it like it is */
				break;
		}

		output.printf("\n");
		if (noreply_method) {
			output.printf("%s[DBus (name = \"%s\", no_reply = true)]\n", get_indent(), realname);
		} else {
			output.printf("%s[DBus (name = \"%s\")]\n", get_indent(), realname);
		}
		if (deprecated_method) {
			if (deprecated_method_replaced_by.length == 0)
				output.printf("[Version (deprecated = true)]\n");
			else output.printf("[Version (deprecated = true, replacement = \"%s\")]".printf(deprecated_method_replaced_by));
		}
		output.printf("%spublic abstract%s %s %s(%s) throws %s;\n",
			get_indent(), (async_method ? " async" : ""), return_value_type, name, args_builder.str, throws_builder.str);
	}

	private int get_out_parameter_count(Xml.Node* node) {
		int out_param_count = 0;
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE)
				continue;
			if (iter->name != ARG_ELTNAME)
				continue;
			if (iter->get_prop(DIRECTION_ATTRNAME) != OUT_ATTRVALUE)
				continue;

			out_param_count++;
		}
		return out_param_count;
	}

	private void generate_signal(Xml.Node* node, string interface_name, string dbus_namespace)
					throws GeneratorError {
		string realname = node->get_prop(NAME_ATTRNAME);
		string name = transform_registered_name(uncapitalize(node->get_prop(NAME_ATTRNAME)));

		INFO(@"   Generating signal $name (originally $realname) for $interface_name");

		int unknown_param_count = 0;

		bool first_param = true;
		StringBuilder args_builder = new StringBuilder();
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE)
				continue;

			if (iter->name != ARG_ELTNAME)
				continue;

			string param_name = transform_registered_name(iter->get_prop(NAME_ATTRNAME));
			if(param_name == null || param_name == "") {
				param_name = "param%i".printf(unknown_param_count);
				unknown_param_count++;
			}
			string param_type = "unknown";
			try {
				param_type = translate_type(iter->get_prop(TYPE_ATTRNAME),
					iter->get_ns_prop(TYPE_ATTRNAME, FSO_NAMESPACE),
					interface_name + capitalize(param_name),
					dbus_namespace);
			} catch (GeneratorError.UNKNOWN_DBUS_TYPE ex) {
				ERROR(@"In interface $interface_name signal $name : Unknown dbus type $(ex.message)");
			}

			if (!first_param) {
				args_builder.append(", ");
			}

			args_builder.append(param_type);
			args_builder.append(" ");
			args_builder.append(param_name);
			first_param = false;
		}

		output.printf("\n");
		output.printf("%s[DBus (name = \"%s\")]\n", get_indent(), realname);
		output.printf("%spublic signal void %s(%s);\n",
			get_indent(), name, args_builder.str);
	}

	private void generate_property(Xml.Node* node, string interface_name, string dbus_namespace)
	{
		string realname = node->get_prop(NAME_ATTRNAME);
		string name = transform_registered_name(uncapitalize(node->get_prop(NAME_ATTRNAME)));

		string typename = "unknown";
		string rawtype = "";
		try {
			rawtype = node->get_prop(TYPE_ATTRNAME);
			typename = translate_type(rawtype,
				node->get_ns_prop(TYPE_ATTRNAME, FSO_NAMESPACE),
				interface_name + capitalize(name),
				dbus_namespace);
		} catch (GeneratorError ex) {
			if (ex is GeneratorError.UNKNOWN_DBUS_TYPE) {
				ERROR(@"In interface $interface_name property $name : Unknown dbus type $(ex.message)");
			} else {
				ERROR(@"In interface $interface_name property $name : Error $(ex.message)");
			}
		}

		string accesstype = "readwrite";
		if (node->has_prop("access") != null) {
			accesstype = node->get_prop("access");
			if (accesstype != "readwrite" && accesstype != "readonly" && accesstype != "read") {
				ERROR(@"In interface $interface_name property $name : Unknown access type: $accesstype");
			}
		}

		INFO(@"   Generating property $name (originally $realname) of type $typename for $interface_name");

		string owned_specifier = is_simple_type(rawtype) ? "" : "owned";
		string accessimpl = (accesstype == "readonly" || accesstype == "read") ? @"$owned_specifier get;" : @"$owned_specifier get; set;";

		output.printf("\n");
		output.printf("%s[DBus (name = \"%s\")]\n", get_indent(), realname);
		output.printf("%spublic abstract %s %s { %s }\n", get_indent(), typename, name, accessimpl);
	}

	private void generate_error(Xml.Node* node, string interface_name)
					throws GeneratorError {
	}

	private void generate_proxy_getter(Xml.Node* node, owned string interface_name, Synchrony synchrony = Synchrony.AUTO)
					throws GeneratorError {
			bool async_method = true;
			switch ( synchrony )
			{
				case Synchrony.FORCE_SYNC:
					async_method = false;
					break;
				case Synchrony.FORCE_ASYNC:
					async_method = true;
					break;
				default:
					/* AUTO, leave it like it is */
					break;
			}
			if ( !async_method ) {
				interface_name = interface_name + "Sync";
			}
	}

	private string translate_type(string type, string? fso_type, string type_name, string dbus_namespace)
					throws GeneratorError {
		string tail = null;
		if (fso_type != null) {
			var vala_type = name_index.get(fso_type);
			if (vala_type == null) {
				throw new GeneratorError.UNKNOWN_DBUS_TYPE(fso_type);
			}
			return vala_type + (type.has_prefix("a") ? "[]" : "");
		}
		return parse_type(type, out tail, type_name, dbus_namespace).replace("][", ",");
	}

	private bool is_simple_type(string type)
	{
		switch (type) {
			case "b":
			case "i":
			case "n":
			case "q":
			case "t":
			case "u":
			case "x":
			case "d":
				return true;
		}
		return false;
	}

	private string parse_type(string type, out string tail, string type_name, string dbus_namespace)
					throws GeneratorError {
		tail = type.substring(1);
		if (type.has_prefix("y")) {
			return "uint8"; // uchar only works since post-vala 0.8.0 (see c4cf64b6590e5cce21febf98b1f3ff935d921fd5)
		} else if (type.has_prefix("b")) {
			return "bool";
		} else if (type.has_prefix("n") || type.has_prefix("i")) {
			return "int";
		} else if (type.has_prefix("q") || type.has_prefix("u")) {
			return "uint";
		} else if (type.has_prefix("x")) {
			return "int64";
		} else if (type.has_prefix("t")) {
			return "uint64";
		} else if (type.has_prefix("d")) {
			return "double";
		} else if (type.has_prefix("s")) {
			return "string";
		} else if (type.has_prefix("o")) {
			return "GLib.ObjectPath"; // needs to be prefixed post vala 0.9.2 (see 142ca8fe0e5b4b8058d4913e909ccc820b6f7768 and 9a650b7f3bb796c36e31a7c649c7f59e8292631e)
		} else if (type.has_prefix("v")) {
			return "GLib.Variant";
		} else if (type.has_prefix("a{") && type.has_suffix("}")) {
			string tmp_type = get_subsignature(type, '{', '}', out tail);
			string tail2 = null;
			string tail3 = null;

			StringBuilder vala_type = new StringBuilder();
			vala_type.append("GLib.HashTable<");
			string foo = parse_type(tmp_type, out tail2, plural_to_singular(type_name) + "Key", dbus_namespace);
			vala_type.append(foo);
			vala_type.append(", ");

			string value_type = parse_type(tail2, out tail3, plural_to_singular(type_name), dbus_namespace);
			if (value_type == "GLib.Value") {
				value_type += "?";
			}
			vala_type.append(value_type);
			vala_type.append(">");

			return vala_type.str;
		} else if (type.has_prefix("a")) {
			string tail2 = null;
			return parse_type(tail, out tail2, plural_to_singular(type_name), dbus_namespace) + "[]";
		} else if (type.has_prefix("(") && type.has_suffix(")")) {
			string sub_type = get_subsignature(type, '(', ')', out tail);
			int number = 2;
			string unique_type_name = type_name +"Struct";
			while (structs_to_generate.has_key(unique_type_name)) {
				unique_type_name = "%s%d".printf(unique_type_name, number++);
			}

			if (!name_index.has_key(dbus_namespace + "." + unique_type_name)) {
				structs_to_generate.set(unique_type_name, sub_type);
			}
			return unique_type_name;
		}
		throw new GeneratorError.UNKNOWN_DBUS_TYPE(@"dbustype: '$type' unknown");
	}

	private string get_struct_name(string interface_name, string param_name) {
		string striped_interface_name = strip_namespace(interface_name);
		string name = capitalize(param_name);
		return name.has_prefix(striped_interface_name) ? name : striped_interface_name + name;
	}

	private string get_namespace_name(string interface_name) {
		long last_dot = interface_name.length - 1;
		while (last_dot >= 0 && interface_name[last_dot] != '.') {
			last_dot--;
		}
		return interface_name.substring(0, last_dot);
	}

	private string strip_namespace(string interface_name) {
		long last_dot = interface_name.length - 1;
		while (last_dot >= 0 && interface_name[last_dot] != '.') {
			last_dot--;
		}
		return interface_name.substring(last_dot + 1, interface_name.length - last_dot - 1);
	}

	private string capitalize(string type_name) {
		string[] parts = type_name.split("_");
		StringBuilder capitalized_name = new StringBuilder();
		foreach (string part in parts) {
			if (part != "") {
				capitalized_name.append(part.substring(0, 1).up());
				capitalized_name.append(part.substring(1, part.length - 1));
			}
		}
		return capitalized_name.str;
	}

	private string uncapitalize(string name) {
		StringBuilder uncapitalized_name = new StringBuilder();
		for (int i = 0; i < name.length; i++) {
			unichar c = name[i];
			if (c.isupper()) {
				if (i > 0)
					uncapitalized_name.append_unichar('_');
				uncapitalized_name.append_unichar(c.tolower());
			} else {
				uncapitalized_name.append_unichar(c);
			}
		}
		return transform_registered_name(uncapitalized_name.str);
	}

	private string normalized_to_upper_case(string name) {
		return name.replace("-", "_").up();
	}

	private string camel_case_to_upper_case(string name) {
		return uncapitalize(name).up();
	}

	private string transform_registered_name(string? name) {
		if (name != null && registered_names.contains(name)) {
			return name + "_";
		}
		return name;
	}

	private string plural_to_singular(string type_name) {
		if (type_name.has_suffix("ies"))
			return type_name.substring(0, type_name.length - 3) + "y";
		else if (type_name.has_suffix("ses"))
			return type_name.substring(0, type_name.length - 2);
		else if (type_name.has_suffix("us"))
			return type_name;
		else if (type_name.has_suffix("i"))
			return type_name.substring(0, type_name.length - 1) + "o";
		else if (type_name.has_suffix("s"))
			return type_name.substring(0, type_name.length - 1);
		else return type_name;
	}

	private int indentSize = 0;

	private string get_indent(int offset = 0) {
		return string.nfill(indentSize + offset, '\t');
	}

	private void update_indent(int increment) {
		indentSize += increment;
	}

	private string get_subsignature( string s, char start, char end, out string tail ) {
		unowned char[] data = (char[])s;
		int iter = 0;
		int counter = 0;
		int begin = 0;
		char c;

		for(iter = 0; iter < s.length; iter++) {
			c = data[iter];
			if(c == start) {
				if( counter == 0 ) {
					begin = iter;
				}
				counter ++;
			}
			else if(c == end) {
				counter --;
				if(counter == 0) {
					break;
				}
			}
		}
		tail = s.substring( iter + 1, -1 );
		var tmp = s.substring( begin + 1, iter - begin - 1);
		return tmp;
    }
}
