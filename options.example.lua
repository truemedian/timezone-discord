
local fs = require 'fs'

local dir = module.dir
local function log_file(path)
	fs.appendFileSync(path, '\n')
	return path
end

return {
	client = {
		routeDelay      = 100,

		maxRetries      = 5,
		shardCount      = 0,
		firstShard      = 0,
		-- lastShard       = -1,

		largeThreshold  = 100,
		bitrate         = 64000,

		logLevel        = 3,
		logFile         = log_file(dir .. '/logs/discordia.log'),
		dateTime        = '%F %T',

		cacheAllMembers = true,
		autoReconnect   = true,
		compress        = true
	},

	rethink = {
		address   = '127.0.0.1',
		port      = 28015,

		user      = 'admin',
		password  = '',
		db        = 'lua_timezones',

		reconnect = true,
		reusable  = false,

		debug     = false,
		file      = log_file(dir .. '/logs/reql.log')
	},

	prefix = '!',
	token = assert(fs.readFileSync('.token'))
}