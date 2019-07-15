
local offsets = {
	-- north america
	AKST = -9,
	AKDT = -8,
	PST  = -8,
	PDT  = -7,
	MST  = -7,
	MDT  = -6,
	CST  = -6,
	CDT  = -5,
	EST  = -5,
	EDT  = -4,
	AST  = -4,
	ADT  = -3,

	-- europe
	GMT  = 0,
	UTC  = 0,
	WET  = 0,
	WEST = 1,
	BST  = 1,
	CET  = 1,
	CEST = 2,
	EET  = 2,
	EEST = 3,
}

local lpeg = require 'lpeg'
local lpeg_num = lpeg.R('09')

local lpeg_hour = lpeg.C(lpeg_num * lpeg_num ^ 0) / tonumber
local lpeg_min = lpeg.C(lpeg_num * lpeg_num) / tonumber

local lpeg_tz_mult = lpeg.C(lpeg.S('+-')) / function(x) return x == '+' and 1 or -1 end
local lpeg_tz_name = lpeg.C(lpeg.R('az', 'AZ') ^ 0) / string.upper

local lpeg_tz_offset = lpeg.Ct(lpeg.Cg(lpeg_hour, 'hour') * ':' * lpeg.Cg(lpeg_min, 'min') + lpeg.Cg(lpeg_hour, 'hour') * lpeg.Cg(lpeg.Cc(0), 'min'))

local full_tz = lpeg.Ct(lpeg.Cg(lpeg_tz_name, 'name') * lpeg.Cg(lpeg_tz_mult, 'mult') * lpeg.Cg(lpeg_tz_offset, 'offset')) * -1

return {
	parse = function(x)
		return full_tz:match(x)
	end,
	offsets = offsets
}