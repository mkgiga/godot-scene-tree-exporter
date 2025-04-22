#
#
#  .d88888b                                         d888888P                             
#  88.    "'                                           88                                
#  `Y88888b. .d8888b. .d8888b. 88d888b. .d8888b.       88    88d888b. .d8888b. .d8888b.  
#        `8b 88'  `"" 88ooood8 88'  `88 88ooood8       88    88'  `88 88ooood8 88ooood8  
#  d8'   .8P 88.  ... 88.  ... 88    88 88.  ...       88    88       88.  ... 88.  ...  
#   Y88888P  `88888P' `88888P' dP    dP `88888P'       dP    dP       `88888P' `88888P'  
# 
#        88888888b                                       dP                     
#        88                                              88                     
#       a88aaaa    dP.  .dP 88d888b. .d8888b. 88d888b. d8888P .d8888b. 88d888b. 
#        88         `8bd8'  88'  `88 88'  `88 88'  `88   88   88ooood8 88'  `88 
#        88         .d88b.  88.  .88 88.  .88 88         88   88.  ... 88       
#        88888888P dP'  `dP 88Y888P' `88888P' dP         dP   `88888P' dP       
#                           88                                                  
#                           dP                                                  
#
# 
# | author mkgiga
# | repo https://github.com/mkgiga/godot-scene-tree-exporter
# | version 1.0
#

@tool
extends EditorPlugin

var export_button: Button

const ICON_PATH = "res://addons/scene-tree-exporter/icon.svg"

func _enter_tree():
    export_button = Button.new()
    export_button.tooltip_text = "Copy Scene Tree as ASCII to Clipboard"
    export_button.flat = true

    var custom_icon = load(ICON_PATH)

    if custom_icon and custom_icon is Texture2D:
        export_button.icon = custom_icon
        export_button.text = ""
        print("Scene Tree Exporter: Loaded custom icon from:", ICON_PATH)
    else:
        push_warning("Could not load custom icon at '%s' or it is not a Texture2D. Using text fallback." % ICON_PATH)
        export_button.icon = null
        export_button.text = "Copy Tree"

    export_button.pressed.connect(_on_export_button_pressed)
    add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, export_button)


func _exit_tree():
    if is_instance_valid(export_button):
        remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, export_button)
        export_button.queue_free()
    print("Scene Tree Exporter: Plugin exited tree.")


func _on_export_button_pressed():
    print("DEBUG: 'Copy Tree' button pressed!")
    var editor_scene_root = EditorInterface.get_edited_scene_root()
    if not is_instance_valid(editor_scene_root):
        print("Scene Tree Exporter: No scene is currently being edited. Nothing copied.")
        OS.alert("No scene is currently being edited to copy.", "Scene Tree Exporter")
        return
    print("DEBUG: Generating ASCII tree for clipboard...")
    var ascii_tree = _generate_ascii_tree(editor_scene_root)

    if ascii_tree.is_empty():
        print("Scene Tree Exporter: Generated tree is empty. Nothing copied.")
        OS.alert("Could not generate tree data (result was empty).", "Scene Tree Exporter")
        return
    DisplayServer.clipboard_set(ascii_tree)
    print()
    print(ascii_tree)
    print()
    print_rich(
        "[center][font_size=24][outline_size=4][outline_color=WHITE][b][color=NAVY_BLUE]Copied scene tree to clipboard![/color][/b][/outline_color][/outline_size][/font_size][/center]"
    )


func _generate_ascii_tree(root_node: Node) -> String:
    var refined_output_lines = []
    var main_scene_path = ProjectSettings.get_setting("application/run/main_scene", "")
    var autoloads: Dictionary = ProjectSettings.get_setting("autoload", {})
    var autoload_keys = autoloads.keys()

    refined_output_lines.append("root: Node/")

    var top_level_nodes_count = autoload_keys.size() + (1 if is_instance_valid(root_node) else 0)
    var current_top_level_index = 0

    for i in range(autoload_keys.size()):
        var autoload_name = autoload_keys[i]
        current_top_level_index += 1
        var is_last = (current_top_level_index == top_level_nodes_count)
        var prefix = "└─ " if is_last else "├─ "

        var autoload_info = autoloads[autoload_name]
        var script_path = ""
        var node_type = "Node"

        if autoload_info.has("path") and typeof(autoload_info["path"]) == TYPE_STRING:
            var path_str : String = autoload_info["path"]
            if path_str.begins_with("*"):
                path_str = path_str.substr(1)
                script_path = path_str.get_file()
                node_type = "Script"
            elif path_str.ends_with(".tscn") or path_str.ends_with(".scn"):
                node_type = "PackedScene"
                script_path = path_str.get_file()
            elif path_str.ends_with(".gd"):
                script_path = path_str.get_file()
                node_type = "Script"

        var script_str = " (%s)" % script_path if not script_path.is_empty() else ""
        var node_info_str = "%s: %s%s (AUTOLOAD)" % [autoload_name, node_type, script_str]
        refined_output_lines.append(prefix + node_info_str)

    if is_instance_valid(root_node):
        current_top_level_index += 1
        var is_last = (current_top_level_index == top_level_nodes_count)
        var root_prefix_str = "└─ " if is_last else "├─ "
        _generate_ascii_tree_recursive(root_node, root_prefix_str, "", is_last, refined_output_lines, main_scene_path)

    return "\n".join(refined_output_lines)


func _generate_ascii_tree_recursive(node: Node, node_prefix: String, children_prefix_base: String, is_last_sibling: bool, output_lines: Array, main_scene_path: String):
    var node_name = _get_formatted_node_name(node.name)
    var node_type = node.get_class()
    var node_script = _get_script_info(node)
    var node_unique = " %" if node.is_unique_name_in_owner() else ""
    var main_scene_marker = ""

    if node_prefix.begins_with("├─ ") or node_prefix.begins_with("└─ "):
        var node_scene_path = node.scene_file_path
        if not node_scene_path.is_empty() and node_scene_path == main_scene_path:
             main_scene_marker = " (main scene)"

    output_lines.append("%s%s: %s%s%s%s" % [
            node_prefix, node_name, node_type, node_unique, node_script, main_scene_marker
    ])

    var children = node.get_children()
    if not children.is_empty():
        var new_children_prefix_base = children_prefix_base + ("  " if is_last_sibling else "│ ")
        for i in range(children.size()):
            var child = children[i]
            var child_is_last = (i == children.size() - 1)
            var child_node_prefix = new_children_prefix_base + ("└─ " if child_is_last else "├─ ")
            _generate_ascii_tree_recursive(child, child_node_prefix, new_children_prefix_base, child_is_last, output_lines, main_scene_path)


func _get_formatted_node_name(node_name: String) -> String:
    if " " in node_name or node_name.begins_with("%") or node_name.begins_with("@"):
        return '"%s"' % node_name
    return node_name


func _get_script_info(node: Node) -> String:
    var script = node.get_script()
    if is_instance_valid(script) and script is Script:
        var script_path = script.resource_path
        if not script_path.is_empty() and script_path.begins_with("res://"):
            return " (%s)" % script_path.get_file()
        elif script_path.is_empty():
            return " (Built-in Script)"
        else:
            return " (Script)"
    return ""
