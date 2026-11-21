extends Node

enum Category {
	GAMEPLAY,
	VIDEO,
	AUDIO,
	CONTROLS,
}

const SETTINGS_SAVE_FILE = "user://settings.cfg"


func load_settings() -> bool:
	var config := ConfigFile.new()
	var err: Error = config.load(SETTINGS_SAVE_FILE)
	if err != OK:
		return false

	for category: String in config.get_sections():
		for option: String in config.get_section_keys(category):
			OptionsManager.set_option(option, config.get_value(category, option))

	return true


func save_settings() -> void:
	var config := ConfigFile.new()
	var index: int = 0
	for option_category: Dictionary in OptionsManager.options:
		for option: String in option_category.keys():
			var category := str(OptionsManager.Category.find_key(index)).capitalize()
			config.set_value(category, option, option_category[option])
		index += 1
	config.save(SETTINGS_SAVE_FILE)
