class_name Console
extends CanvasLayer

var sync := true:
	set(s):
		sync = s
		if sync:
			var label := %Label as Label
			label.text = text
var text := "Hello world!"

func _ready() -> void:
	Config.console = self

func print_line(t: String) -> void:
	print(t)
	text = t + "\n" + text
	if sync:
		var label := %Label as Label
		label.text = text

func clear() -> void:
	text = ""
	if sync:
		var label := %Label as Label
		label.text = text
