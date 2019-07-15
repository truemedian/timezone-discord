
local function find_userid(str, guild)
	local id = str:find('^<@!?(%d+)>$')

	if id then -- we got a mention, use it
		return id, client:getUser(id)
	else
		local strl = str:lower()
		local matches = { }

		local fulltag = false
		if str:find('#%d%d%d%d$') then -- we have a discriminator, check the full tag
			fulltag = true
			for member in guild.members:iter() do
				if member.tag == str then
					return member.id, member
				elseif member.tag:lower() == strl then
					table.insert(matches, { member, 1 })
				elseif member.tag:sub(1, #str) == str then
					table.insert(matches, { member, 2 })
				elseif member.tag:lower():sub(1, #str) == strl then
					table.insert(matches, { member, 3 })
				elseif member.tag:find(str) then
					table.insert(matches, { member, 4 })
				elseif member.tag:lower():find(strl) then
					table.insert(matches, { member, 5 })
				end
			end
		else -- time to look for matches in names
			for member in guild.members:iter() do
				if member.name == str then
					return member.id, member
				elseif member.name:lower() == strl then
					table.insert(matches, { member, 1 })
				elseif member.name:sub(1, #str) == str then
					table.insert(matches, { member, 2 })
				elseif member.name:lower():sub(1, #str) == strl then
					table.insert(matches, { member, 3 })
				elseif member.name:find(str) then
					table.insert(matches, { member, 4 })
				elseif member.name:lower():find(strl) then
					table.insert(matches, { member, 5 })
				end
			end
		end

		-- there were no matches, return nil
		if #matches == 0 then return nil end

		-- sort matches based on how accurate they are
		table.sort(matches, function(a, b)
			return a[2] < b[2]
		end)

		-- the highest accuracy of match
		local best_matches = matches[1][2]

		local best, distance = nil, math.huge
		for _, match in ipairs(matches) do
			-- discard lower accuracy matches
			if match[2] ~= best_matches then break end

			-- what we compare against depends on how we matched users, then find levenshtein distance between the input
			local this_dist = match[1][(fulltag and 'tag' or 'name')]:levenshtein(str)

			if this_dist < distance then
				-- our new best match
				best, distance = match[1], this_dist
			end
		end

		return best.id, best
	end
end

local tzlib = require 'timezone'
client:on('ready', function()
	print('Waiting to save Timezones.')
end)

local prefix = config.prefix
client:on('messageCreate', function(message)
	if message.author.bot or not message.guild or message.author == client.user then return end
	local content = message.content

	if content:startswith(prefix) then
		content = content:sub(#prefix + 1)

		local args = content:split('%s+')

		if args[1] == 'save' then
			local offset = args[2]
			if not offset  then
				-- :no_entry_sign: expected a +/- number timezone offset.
				return message:reply('\240\159\154\171 expected a +/- number timezone offset.')
			end

			local tzdata = tzlib.parse(offset)

			if tzdata then
				local off = tzdata.offset

				if off.min > 59 then
					-- :no_entry_sign: expected a +/- number timezone offset.
					return message:reply('\240\159\154\171 expected a +/- number timezone offset.')
				end

				if tzdata.name ~= '' then
					local from_name = tzlib.offsets[tzdata.name]

					off.hour = off.hour + from_name

					if not from_name then
						-- :exclamation: expected a +/- number timezone offset.
						return message:reply('\226\157\151 please use a standard timezone, such as EST or UTC.')
					end
				end

				local num = tzdata.mult * (off.hour + off.min / 60)

				if num > 14 then
					-- :exclamation: thats no valid timezone, the farthest is +14.
					return message:reply('\226\157\151 thats no valid timezone, the farthest is +14.')
				elseif num < -12 then
					-- :exclamation: thats no valid timezone, the farthest is -12.
					return message:reply('\226\157\151 thats no valid timezone, the farthest is -12.')
				end

				-- save offset in minutes
				num = num * 60
				local ret = rethink_conn.reql().table('timezones').replace({ id = message.author.id, offset = num }).run()

				if ret and ret[1] then
					if ret[1].replaced > 0 then
						local utc_time = ('UTC%s%02d:%02d'):format(num >= 0 and '+' or '-', math.abs(off.hour), off.min)

						-- :white_check_mark: successfully saved your timezone.
						return message:reply('\226\156\133 successfully saved your timezone as **' .. utc_time .. '**.')
					elseif ret[1].unchanged > 0 then
						-- :white_check_mark: successfully saved your timezone.
						return message:reply('\226\156\133 that is already your timezone!')
					end
				end

				-- :exclamation: a database error occurred.
				return message:reply('\226\157\151 a database error occurred.')
			else
				-- :no_entry_sign: expected a +/- number timezone offset.
				return message:reply('\240\159\154\171 expected a +/- number timezone offset.')
			end
		elseif args[1] == 'time' then
			if not args[2] then
				-- :no_entry_sign: expected an @mention or username.
				return message:reply('\240\159\154\171 expected an @mention or username.')
			end

			local id, member = find_userid(args[2], message.guild)
			if not id then
				-- :no_entry_sign: could not find the user you provided.
				return message:reply('\240\159\154\171 could not find the user you provided.')
			end

			local data = rethink_conn.reql().table('timezones').get(id).run()

			if not data then
				-- :exclamation: could not find the user you provided.
				return message:reply('\226\157\151 **' .. member.name .. '** hasn\'t told me their timezone.')
			end

			-- calculate their time

			local is_dst_me = os.date '*t' .isdst

			local utc_time = os.date '!*t'
			utc_time.min = utc_time.min + data.offset + (is_dst_me and -60 or 0)

			local their_time = os.time(os.date('*t', os.time(utc_time)))

			-- :clock2: for **{ member_name }**
			-- { day_name }, { short_month } { day }
			-- { hr }:{ min }:{ sec }
			return message:reply('\240\159\149\145 for **' .. member.name .. '**\n**' .. os.date('%A, %b %d', their_time) .. '**\n**' .. os.date('%H:%M:%S', their_time) .. '**')
		end
	end
end)