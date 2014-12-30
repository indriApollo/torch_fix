torch_fix = {}

torch_fix.fix = function(old_node1,old_node2,new_node,radius,playerpos)
	local old_id1 = minetest.get_content_id(old_node1)
	local old_id2 = minetest.get_content_id(old_node2)

	local count = 0

	playerpos = vector.round(playerpos) -- to avoid weird area behavior
	local pos1 = vector.subtract(playerpos,radius) -- low left
	local pos2 = vector.add(playerpos,radius) -- top right

	local manip = minetest.get_voxel_manip()
	local emerged_pos1, emerged_pos2 = manip:read_from_map(pos1,pos2)
	local area = VoxelArea:new({MinEdge=emerged_pos1, MaxEdge=emerged_pos2})
	local nodes = manip:get_data()
	for i in area:iterp(pos1,pos2) do
		if nodes[i] == old_id1 or nodes[i] == old_id2 then
			local cur_pos = area:position(i)
			local cur_node = minetest.get_node(cur_pos)
			local wdir = cur_node.param2
			minetest.remove_node(cur_pos)
			print("wdir "..wdir)
			if wdir == 0 then -- warning : wdir=0 is the same as default param2=1 AND param2=4 !
				-- This dude's mod isn't following the standards :(
				-- we now have to correct the conflicting wdir=0
				local adjacent_node = minetest.get_node({x=cur_pos.x,y=cur_pos.y,z=cur_pos.z+1})
				print("adjacent_node "..adjacent_node.name)
				if adjacent_node.name == "air" then
					minetest.set_node(cur_pos, {name=new_node,param2=1}) -- torch isn't on a wall
				else
					minetest.set_node(cur_pos, {name=new_node,param2=4})
				end
			elseif wdir == 1 then
				minetest.set_node(cur_pos, {name=new_node,param2=2})
			elseif wdir == 2 then
				minetest.set_node(cur_pos, {name=new_node,param2=5})
			elseif wdir == 3 then
				minetest.set_node(cur_pos, {name=new_node,param2=3})
			end
			count = count + 1
		end
	end

	return count
end

minetest.register_privilege("fix")

minetest.register_chatcommand("fix", {
	params = "<radius>",
	description = "Fix nodes",
	privs = {fix = true},
	func = function(name,param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found"
		end
		local radius = tonumber(param)
		if radius and radius > 0 then
			local count = torch_fix.fix("torches:floor","torches:wand","default:torch",radius,player:getpos())
			minetest.chat_send_player(name, count.." node(s) replaced !")
		else
			minetest.chat_send_player(name,"Missing or invalid radius !")
		end
		return true
	end,
})
