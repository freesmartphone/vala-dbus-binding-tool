using GLib;
using Xml;
using Gee;

public errordomain GeneratorError {
	FILE_NOT_FOUND,
	CANT_CREATE_FILE,
	UNKNOWN_DBUS_TYPE
}

internal class GeneratedNamespace {
	public GeneratedNamespace parent;
	public string name;
	public Gee.Map<string, Xml.Node*> members
		= new Gee.HashMap<string, Xml.Node*>(str_hash, str_equal, direct_equal);
	public Gee.Map<string, GeneratedNamespace> namespaces
		= new Gee.HashMap<string, GeneratedNamespace>(str_hash, str_equal, direct_equal);
}

public class BindingGenerator : Object {

	private static Set<string> registered_names = new HashSet<string>(str_hash, str_equal);

	static construct {
		registered_names.add("using");
		registered_names.add("namespace");
		registered_names.add("public");
		registered_names.add("private");
		registered_names.add("internal");
		registered_names.add("errordomain");
		registered_names.add("class");
		registered_names.add("struct");
		registered_names.add("new");
		registered_names.add("for");
		registered_names.add("while");
		registered_names.add("foreach");
		registered_names.add("switch");
		registered_names.add("case");
		registered_names.add("static");
		registered_names.add("unowned");
		registered_names.add("weak");
		registered_names.add("register");
		registered_names.add("message");
		registered_names.add("get_type");
	}

	public static int main(string[] args) {
		string[] split_name = args[0].split("/");
		string program_name = split_name[split_name.length - 1];
		string command = string.joinv(" ", args);

		string api_path = null;
		string output_directory = null;
		Map<string,string> namespace_renaming = new HashMap<string,string>(str_hash, str_equal, str_equal);

		for (int i = 1; i < args.length; i++) {
			string arg = args[i];

			string[] split_arg = arg.split("=");
			switch (split_arg[0]) {
			case "-h":
			case "--help":
				show_usage(program_name);
				return 0;
			case "-v":
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
			generate(api_path, output_directory, namespace_renaming, command);
		} catch (GLib.FileError ex) {
			stderr.printf("%s: Error: %s\n", program_name, ex.message);
			return 1;
		} catch (GeneratorError ex) {
			stderr.printf("%s: Error: %s\n", program_name, ex.message);
			return 1;
		}
		return 0;
	}

	private static void show_version() {
		stdout.printf("Vala D-Bus Binding Tool 0.1\n");
		stdout.printf("Copyright (C) 2009 SHR <shr-project.org>\n");
		stdout.printf("This is free software; see the source for copying conditions.\n");
		stdout.printf("There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\n");
	}

	private static void show_usage(string program_name) {
		stdout.printf("Usage:\n");
		stdout.printf("  %s [--version] [--help]\n", program_name);
		stdout.printf("  %s [--api-path=PATH] [--directory=DIR] [--strip-namespace=NS]* [--rename-namespace=OLD_NS:NEW_NS]*\n", program_name);
	}

	public static void generate(string api_path, string output_directory,
			Map<string,string> namespace_renaming, string command)
			throws GeneratorError, GLib.FileError {

		Parser.init();

		BindingGenerator generator = new BindingGenerator(output_directory, namespace_renaming, command);
		generator.generate_bindings(api_path);

		Parser.cleanup();
	}

	private BindingGenerator(string output_directory, Map<string,string> namespace_renaming, string command) {
		this.output_directory = output_directory;
		this.namespace_renaming = namespace_renaming;
		this.command = command;
	}

	private string output_directory;
	private Map<string,string> namespace_renaming;
	private string command;
	private bool inner_interface_strategy_concat = true;
	
	private static const string FSO_NAMESPACE = "http://www.freesmartphone.org/schemas/DBusSpecExtension";

	private static const string INTERFACE_ELTNAME = "interface";
	private static const string METHOD_ELTNAME = "method";
	private static const string SIGNAL_ELTNAME = "signal";
	private static const string ERROR_ELTNAME = "error";
	private static const string ARG_ELTNAME = "arg";
	private static const string NAME_ATTRNAME = "name";
	private static const string TYPE_ATTRNAME = "type";
	private static const string DIRECTION_ATTRNAME = "direction";
	private static const string IN_ATTRVALUE = "in";
	private static const string OUT_ATTRVALUE = "out";
	private static const string ENUMERATION_ELTNAME = "enumeration";
	private static const string MEMBER_ELTNAME = "member";
	private static const string VALUE_ATTRNAME = "value";

	private void generate_bindings(string api_path)
			throws GeneratorError, GLib.FileError {

		if (api_path.has_suffix(".xml")) {
			add_api_file(api_path);
		} else {
			GLib.Dir dir = new GLib.Dir(api_path);
			string name;
			while ((name = dir.read_name()) != null) {
				if (name.has_suffix(".xml")) {
					add_api_file(api_path + name);
				}
			}
		}

		index_names(root_namespace);
		generate_namespace(root_namespace);
	}

	private void add_api_file(string api_file) throws GeneratorError {
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

		output.printf("/* Generated by vala-dbus-binding-tool. Do not modify! */\n");
		output.printf("/* Generated with: %s */\n", command);
		output.printf("using DBus;\n");
		output.printf("using GLib;\n");
	}

	private Gee.List<Xml.Doc*> api_docs = new Gee.ArrayList<Xml.Doc*>();

	private void preprocess_binding_names(Xml.Doc* api_doc) {
		for (Xml.Node* iter = api_doc->get_root_element()->children; iter != null; iter = iter->next) {
            if (iter->type != ElementType.ELEMENT_NODE)
                continue;

			if (iter->name != INTERFACE_ELTNAME
				&& iter->name != ENUMERATION_ELTNAME)
				continue;

			string dbus_interface_name = iter->get_prop(NAME_ATTRNAME);
			string[] split_name = dbus_interface_name.split(".");
			string short_name = split_name[split_name.length - 1];

			// Removing stripped root namespaces
			int i = 0;
			for (; i < split_name.length - 1; i++) {
				string part = split_name[i];
				if (namespace_renaming.get(part) != "") break;
			}

			// Traversing inner namespaces
			GeneratedNamespace ns = root_namespace;
			for (; i < split_name.length - 1; i++) {
				string part = split_name[i];

				if (namespace_renaming.contains(part) && namespace_renaming.get(part) != "") {
					part = namespace_renaming.get(part);
				}

				if (ns.members.contains(part) && inner_interface_strategy_concat) {
					if (ns.namespaces.contains(part)) {
						GeneratedNamespace child = ns.namespaces.get(part);
						foreach (string interf_name in child.members.get_keys()) {
							Xml.Node* interf = child.members.get(interf_name);
							ns.members.set(part + interf_name, interf);
						}
						ns.namespaces.remove(part);
						child.parent = null;
					}

					break;
				}

				GeneratedNamespace child = null;
				if (ns.namespaces.contains(part)) {
					child = ns.namespaces.get(part);
				} else {
					child = new GeneratedNamespace();
					child.parent = ns;
					child.name = part;
					ns.namespaces.set(part, child);
				}

				if (ns.members.contains(part)) {
						child.members.set(part, ns.members.get(part));
						ns.members.remove(part);
				}

				ns = child;
			}

			string interface_name = null;
			if (inner_interface_strategy_concat) {
				StringBuilder name_builder = new StringBuilder();
				// Concatenating last inner namespaces
				for (; i < split_name.length - 1; i++) {
					name_builder.append(split_name[i]);
				}
				name_builder.append(short_name);
				interface_name = name_builder.str;

				if (ns.namespaces.contains(short_name)) {
					GeneratedNamespace child = ns.namespaces.get(short_name);
					foreach (string interf_name in child.members.get_keys()) {
						Xml.Node* interf = child.members.get(interf_name);
						ns.members.set(short_name + interf_name, interf);
					}
					ns.namespaces.remove(short_name);
					child.parent = null;
				}
			} else {
				if (ns.namespaces.contains(short_name)) {
					ns = ns.namespaces.get(short_name);
				}
				interface_name = short_name;
			}

			if (!ns.members.contains(interface_name)) {
				ns.members.set(interface_name, iter);
			} else {
				//TODO Error already existing interface
			}
		}
	}

	private void index_names(GeneratedNamespace ns) {
		if (ns.members.size > 0) {
			string namespace_name = string.joinv(".", get_namespace_path(ns));

			foreach (string name in ns.members.get_keys()) {
				Xml.Node* api = ns.members.get(name);
				string dbus_name = api->get_prop(NAME_ATTRNAME);
				name_index.set(dbus_name, namespace_name + "." + name);
			}
		}

		foreach (string name in ns.namespaces.get_keys()) {
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

	private Map<string, string> name_index = new HashMap<string, string>(str_hash, str_equal, str_equal);

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

			foreach (string name in ns.members.get_keys()) {
				Xml.Node* api = ns.members.get(name);

				switch (api->name) {
				case INTERFACE_ELTNAME:
					generate_interface(name, api);
					break;
				case ENUMERATION_ELTNAME:
					generate_enumeration(name, api);
					break;
				}
			}

			foreach (string name in namespace_names) {
				update_indent(-1);
				output.printf("%s}\n", get_indent());
			}

			output = null;
		}

		foreach (string name in ns.namespaces.get_keys()) {
			GeneratedNamespace child = ns.namespaces.get(name);

			generate_namespace(child);
		}
	}

	private Gee.Map<string, string> structs_to_generate
		= new Gee.HashMap<string, string>(str_hash, str_equal, str_equal);

	private void generate_interface(string interface_name, Xml.Node* node)
			throws GeneratorError {
		string dbus_name = node->get_prop(NAME_ATTRNAME);

		output.printf("\n");
		output.printf("%s[DBus (name = \"%s\")]\n", get_indent(), dbus_name);
		output.printf("%spublic interface %s : GLib.Object {\n", get_indent(), interface_name);
		update_indent(+1);

		generate_members(node, interface_name);

		update_indent(-1);
		output.printf("%s}\n", get_indent());

		if (structs_to_generate.size != 0) {
			string namespace_name = get_namespace_name(interface_name);
			foreach (string name in structs_to_generate.get_keys()) {
				generate_struct(name, structs_to_generate.get(name), namespace_name);
			}
			structs_to_generate.clear();
		}
	}

	private void generate_enumeration(string enumeration_name, Xml.Node* node)
			throws GeneratorError {
		string type = node->get_prop(TYPE_ATTRNAME);
		bool string_enum = type == "s";

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
				output.printf("%s%s%s%s\n", get_indent(), member_name, string_enum ? "" : " = member_value", iter->next == null ? "" : ",");
				break;
			}
		}

		update_indent(-1);
		output.printf("%s}\n", get_indent());
	}

	private void generate_struct(string name, string content_signature, string namespace_name)
			throws GeneratorError {
		output.printf("\n");
		output.printf("%spublic struct %s {\n", get_indent(), name);
		update_indent(+1);

		int attribute_number = 1;
		string signature = content_signature;
		string tail = null;
		while (signature != "") {
			string type = parse_type(signature, out tail, "");
			output.printf("%spublic %s attr%d;\n", get_indent(), type, attribute_number);
			attribute_number++;
			signature = tail;
		}

		update_indent(-1);
		output.printf("%s}\n", get_indent());
	}

	private void generate_members(Xml.Node* node, string interface_name)
			throws GeneratorError {
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE)
				continue;

			switch (iter->name) {
			case METHOD_ELTNAME:
				generate_method(iter, interface_name);
				break;
			case SIGNAL_ELTNAME:
				generate_signal(iter, interface_name);
				break;
			case ERROR_ELTNAME:
				generate_error(iter, interface_name);
				break;
			}
		}
	}

	private void generate_method(Xml.Node* node, string interface_name)
			throws GeneratorError {
		string name = uncapitalize(node->get_prop(NAME_ATTRNAME));

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

		bool first_param = true;
		StringBuilder args_builder = new StringBuilder();
		string return_value_type = "void";
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE)
				continue;

			if (iter->name != ARG_ELTNAME)
				continue;

			string param_name = transform_registered_name(iter->get_prop(NAME_ATTRNAME));
			string param_type = "unknown";
			try {
				param_type = translate_type(iter->get_prop(TYPE_ATTRNAME),
					iter->get_ns_prop(TYPE_ATTRNAME, FSO_NAMESPACE),
					get_struct_name(interface_name, param_name));
			} catch (GeneratorError.UNKNOWN_DBUS_TYPE ex) {
				stdout.printf("Error in interface %s method %s : Unknown dbus type %s\n",
					interface_name, name, ex.message);
			}
			string param_dir = iter->get_prop(DIRECTION_ATTRNAME);

			switch (param_dir) {
			case IN_ATTRVALUE:
				if (!first_param) {
					args_builder.append(", ");
				}

				args_builder.append(param_type);
				args_builder.append(" ");
				args_builder.append(param_name);
				first_param = false;
				break;
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
			}
		}

		output.printf("\n");
		output.printf("%spublic abstract %s %s(%s) throws DBus.Error;\n",
			get_indent(), return_value_type, name, args_builder.str);
	}

	private void generate_signal(Xml.Node* node, string interface_name)
			throws GeneratorError {
		string name = uncapitalize(node->get_prop(NAME_ATTRNAME));

		bool first_param = true;
		StringBuilder args_builder = new StringBuilder();
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE)
				continue;

			if (iter->name != ARG_ELTNAME)
				continue;

			string param_name = transform_registered_name(iter->get_prop(NAME_ATTRNAME));
			string param_type = "unknown";
			try {
				param_type = translate_type(iter->get_prop(TYPE_ATTRNAME),
					iter->get_ns_prop(TYPE_ATTRNAME, FSO_NAMESPACE),
					interface_name + capitalize(param_name));
			} catch (GeneratorError.UNKNOWN_DBUS_TYPE ex) {
				stdout.printf("Error in interface %s method %s : Unknown dbus type %s\n",
					interface_name, name, ex.message);
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
		output.printf("%spublic signal void %s(%s);\n",
			get_indent(), name, args_builder.str);
	}

	private void generate_error(Xml.Node* node, string interface_name)
			throws GeneratorError {
	}

	private string translate_type(string type, string? fso_type, string type_name)
			throws GeneratorError {
		if (fso_type != null) {
			return name_index.get(fso_type);
		}
		string tail = null;
		return parse_type(type, out tail, type_name).replace("][", ",");
	}

	private string parse_type(string type, out string tail, string type_name)
			throws GeneratorError {
		tail = type.substring(1);
		if (type.has_prefix("y")) {
			return "uchar";
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
			return "ObjectPath";
		} else if (type.has_prefix("v")) {
			return "GLib.Value";
		} else if (type.has_prefix("a{")) {
			tail = tail.substring(1, tail.length - 2);
			string tail2 = null;
			string tail3 = null;

			StringBuilder vala_type = new StringBuilder();
			vala_type.append("GLib.HashTable<");
			vala_type.append(parse_type(tail, out tail2, plural_to_singular(type_name) + "Key"));
			vala_type.append(", ");

			string value_type = parse_type(tail2, out tail3, plural_to_singular(type_name));
			if (value_type == "GLib.Value") {
				value_type += "?"; 
			}
			vala_type.append(value_type);
			vala_type.append(">");

			tail = tail3;
			return vala_type.str;
		} else if (type.has_prefix("a")) {
			string tail2 = null;
			return parse_type(tail, out tail2, plural_to_singular(type_name)) + "[]";
		} else if (type.has_prefix("(")) {
			tail = tail.substring(0, tail.length - 1);

			int number = 2;
			string unique_type_name = type_name;
			while (structs_to_generate.contains(unique_type_name)) {
				unique_type_name = "%s%d".printf(type_name, number++);
			}

			structs_to_generate.set(unique_type_name, tail);
			return unique_type_name;
		}
		throw new GeneratorError.UNKNOWN_DBUS_TYPE(type);
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

	private string transform_registered_name(string name) {
		if (registered_names.contains(name)) {
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
	private string indent = "";

	private unowned string get_indent() {
		if (indent == null) {
			indent = string.nfill(indentSize, '\t');
		}
		return indent;
	}

	private void update_indent(int increment) {
		indentSize += increment;
		indent = null;
	}
}
