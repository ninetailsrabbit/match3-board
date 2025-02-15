@tool
extends EditorPlugin

const UpdateNotifyToolScene = preload("updater/update_notify_tool.tscn")

var update_notify_tool_instance: Node

func _enter_tree() -> void:
	MyPluginSettings.set_update_notification()
	_setup_updater()
	
	if not DirAccess.dir_exists_absolute(MyPluginSettings.PluginTemporaryReleaseUpdateDirectoryPath):
		DirAccess.make_dir_recursive_absolute(MyPluginSettings.PluginTemporaryReleaseUpdateDirectoryPath)
	
	add_custom_type("Match3Board", "Node2D", preload("res://addons/ninetailsrabbit.match3_board/src/match3_board.gd"), preload("assets/board.svg"))
	add_custom_type("Match3BoardPreview", "Node2D", preload("res://addons/ninetailsrabbit.match3_board/src/tools/match3_preview.gd"), preload("assets/board_preview.svg"))
	add_custom_type("Match3Animator", "Node2D", preload("res://addons/ninetailsrabbit.match3_board/src/ui/match3_animator.gd"), preload("assets/animator.svg"))
	add_custom_type("Match3Highlighter", "Node2D", preload("res://addons/ninetailsrabbit.match3_board/src/ui/match3_highlighter.gd"), preload("assets/light.svg"))
	

func _exit_tree() -> void:
	MyPluginSettings.remove_settings()
	
	if update_notify_tool_instance:
		update_notify_tool_instance.free()
		update_notify_tool_instance = null

	remove_custom_type("Match3Highlighter")
	remove_custom_type("Match3Animator")
	remove_custom_type("Match3BoardPreview")
	remove_custom_type("Match3Board")

## Update tool referenced from https://github.com/MikeSchulze/gdUnit4/blob/master/addons/gdUnit4
func _setup_updater() -> void:
	if MyPluginSettings.is_update_notification_enabled():
		update_notify_tool_instance = UpdateNotifyToolScene.instantiate()
		Engine.get_main_loop().root.add_child.call_deferred(update_notify_tool_instance)
