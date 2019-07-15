return {
	name = "truemedian/timezone-discord",
	version = "1.0.0",
	description = "A simple discord bot to store and retrieve the current time for users in your server",
	tags = { "lua", "discord", "timezone" },
	license = "MIT",
	author = { name = "Nameless", email = "truemedian@gmail.com" },
	homepage = "https://github.com/truemedian/timezone-discord",
	dependencies = {
		'SinisterRectus/discordia',
		'DannehSC/luvit-reql'
	},
	files = {
		"**.lua",
		"!test*"
	}
}