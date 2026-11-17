extends SceneTree
# Schreibt für jedes Zeichen aus Glyphen.G zwei Masken (Gold, Ritzung) als PNG, 512 Pixel, für tools/symbole.py.
# Aufruf: godot --headless --path . --script res://tools/symbole/masken.gd -- <Zielordner>
func _init() -> void:
	var ziel: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(ziel)
	var liste := []
	for id in Glyphen.G:
		for teil in ["gold", "ritz"]:
			var img := Image.new()
			img.load_svg_from_string(Glyphen.maske(id, teil), 512.0 / 56.0)
			img.save_png("%s/%s_%s.png" % [ziel, id, teil])
		liste.append("%s %s" % [id, Glyphen.cls_of(id)])
	var f := FileAccess.open(ziel + "/liste.txt", FileAccess.WRITE)
	f.store_string("\n".join(liste))
	quit()
