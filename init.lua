
local main_env = getfenv()

local discordia = require 'discordia'
local luvit_reql = require 'luvit-reql'
local fs = require 'fs'

local function run_file(name, env)
	if not env then
		env = main_env
	else
		setmetatable(env, { __index = main_env })
	end

	local content = assert(fs.readFileSync(name))

	local fn = assert(load(content, name, 't', env))

	local returns = { pcall(fn) }
	local success = table.remove(returns, 1)

	if not success then error(returns[1]) end

	return unpack(returns)
end

local options = run_file 'libs/options.lua'

discordia.extensions()
local client = discordia.Client(options.client)
options.client = nil

main_env.discordia = discordia
main_env.client    = client
main_env.config    = options

coroutine.wrap(function()
	local rethink_conn = luvit_reql.connect(options.rethink)
	main_env.rethink_conn = rethink_conn
	options.rethink = nil

	local token = options.token
	options.token = nil

	print('Starting Discord Bot...')
	run_file 'libs/main.lua'

	client:run(token)
end)()