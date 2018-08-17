--

---
--- constants
---
local bnst_pos={x=100,y=0,z=100}

local bnst_rotradius=6    --the radius the vines rotate around
local bnst_rotdirection=1   --direction of rotation of the inner spiral
local bnst_vineradius=4   --radius of each vine
local bnst_vtot=3         --total number of vines
local bnst_yper360=48     --y units per one 360 degree rotation of a vine
local bnst_rot2radius=6   --radius of the secondary spiral
local bnst_rot2yper360=80 --y units per one 365 degree rotation of secondary spiral
local bnst_rot2direction=1  --direction of rotation of the outer spiral



-- one vine straight up
--local bnst_rotradius=0     --the radius the vines rotate around
--local bnst_rotdirection=1  --direction of rotation of the inner spiral
--local bnst_vineradius=4    --radius of each vine
--local bnst_vtot=1          --total number of vines
--local bnst_yper360=1       --y units per one 360 degree rotation of a vine
--local bnst_rot2radius=0    --radius of the secondary spiral
--local bnst_rot2yper360=1   --y units per one 365 degree rotation of secondary spiral
--local bnst_rot2direction=1 --direction of rotation of the outer spiral

--like below but with more space in middle
--local bnst_rotradius=6    --the radius the vines rotate around
--local bnst_rotdirection=1   --direction of rotation of the inner spiral
--local bnst_vineradius=4   --radius of each vine
--local bnst_vtot=3         --total number of vines
--local bnst_yper360=48     --y units per one 360 degree rotation of a vine
--local bnst_rot2radius=9   --radius of the secondary spiral
--local bnst_rot2yper360=80 --y units per one 365 degree rotation of secondary spiral
--local bnst_rot2direction=1  --direction of rotation of the outer spiral


--good result, try vineradius of 3 as well.
--local bnst_rotradius=6    --the radius the vines rotate around
--local bnst_rotdirection=1   --direction of rotation of the inner spiral
--local bnst_vineradius=4   --radius of each vine
--local bnst_vtot=3         --total number of vines
--local bnst_yper360=48     --y units per one 360 degree rotation of a vine
--local bnst_rot2radius=6   --radius of the secondary spiral
--local bnst_rot2yper360=80 --y units per one 365 degree rotation of secondary spiral
--local bnst_rot2direction=1  --direction of rotation of the outer spiral


minetest.register_node("beanstalk:beanstalk", {
	description = "Beanstalk Big Vine",
	tiles = {"beanstalk_top_32.png", "beanstalk_top_32.png", "beanstalk_side_32.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
  --climbable = true,
	groups = {snappy=1,choppy=3,flammable=2},
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node,

	--after_dig_node = function(pos, node, metadata, digger)
	--	default.dig_up(pos, node, digger)
	--end,
})

--copied from ethereal
minetest.register_node("beanstalk:vine", {
	description = "BeanstalkVine",
	drawtype = "signlike",
	tiles = {"vine.png"},
	inventory_image = "vine.png",
	wield_image = "vine.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	walkable = false,
	climbable = true,
	is_ground_content = false,
	selection_box = {
		type = "wallmounted",
	},
	groups = {choppy = 3, oddly_breakable_by_hand = 1, flammable = 2},
	legacy_wallmounted = true,
	sounds = default.node_sound_leaves_defaults(),
})


--copied from ethereal
minetest.register_node("beanstalk:vine0", {
	description = "BeanstalkVine0",
	drawtype = "signlike",
	tiles = {"vine0.png"},
	inventory_image = "vine0.png",
	wield_image = "vine0.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	walkable = false,
	climbable = true,
	is_ground_content = false,
	selection_box = {
		type = "wallmounted",
	},
	groups = {choppy = 3, oddly_breakable_by_hand = 1, flammable = 2},
	legacy_wallmounted = true,
	sounds = default.node_sound_leaves_defaults(),
})



local bnst_stalk=minetest.get_content_id("beanstalk:beanstalk")
local bnst_vines=minetest.get_content_id("beanstalk:vine")


--calculated constants
bnst_totradius=bnst_rotradius+bnst_vineradius+2 -- total radius = rotradius (radius vines circle around) + vine radius + 2 more for a space around the beanstalk (will be air)
bnst_min={x=bnst_pos.x-bnst_totradius, y=0, z=bnst_pos.z-bnst_totradius}
bnst_max={x=bnst_pos.x+bnst_totradius, y=5000, z=bnst_pos.z+bnst_totradius}
--minetest.log("bs totradius="..bnst_totradius)

--grab content IDs -- You need these to efficiently access and set node data.  get_node() works, but is far slower
local c_air = minetest.get_content_id("air")

minetest.log("bnst_stalk="..bnst_stalk.." bnst_vines="..bnst_vines.." c_air="..c_air)
--
-- Aliases for map generator outputs
--

--x,y,z pos of this node, vcx vcz center of this vine
function checkvines(x,y,z, vcx,vcz, area,data)
  local logstr="  checkvines vcx="..vcx.." vcz="..vcz.." x="..x.." y="..y.." z="..z
  local vn = area:index(x, y, z)
  local vndown = area:index(x, y-1, z)
  logstr=logstr.. " vn="..data[vn].." vndown="..data[vndown]
  if data[vndown]==bnst_stalk then logstr=logstr.." : vndown=stalk" end
  if data[vn]~=bnst_stalk and data[vn]~=bnst_vines and data[vndown]~=bnst_stalk then    
    logstr=logstr.." : found air placing vine"
    data[vn]=bnst_vines
    local pos={x=x,y=y,z=z}
    local node=minetest.get_node(pos)
    --we have the vine in place, but we need to get it with the vines
    --against the big beanstalk node.
    --if diff x is bigger than diff z we put against the x face, otherwize z
    --if diff is negative we put against plus face, otherwise minus face
    --facedir 0=top 1=bot 2=+x 3=-x 4=+z 5=-z
    local facedir=2
    local diffx=math.abs(x-vcx)
    local diffz=math.abs(z-vcz)
    if diffx>=diffz then
      if (x-vcx)<0 then facedir=2 else facedir=3 end
    else
      if (z-vcz)<0 then facedir=4 else facedir=5 end
    end

    node.param2=facedir
    minetest.swap_node(pos,node)
  end --if
  minetest.log(logstr)
end --checkvines



--minp is the min point of the chunk, maxp is the max point of the chunk
function beanstalk(minp, maxp, seed)
  --dont bother if we are not near the bean stalk
  if minp.x > bnst_max.x or maxp.x < bnst_min.x and
     minp.z > bnst_max.z or maxp.z < bnst_min.z  and
     minp.y > bnst_max.y or maxp.y < bnst_min.y then
    --minetest.log("bs rejected: min=("..minp.x..","..minp.y..","..minp.z..") max=("..maxp.x..","..maxp.y..","..maxp.z..")")
    return --quit; otherwise, you'd have wasted resources
  end
  --minetest.log("bs accepted: min=("..minp.x..","..minp.y..","..minp.z..") max=("..maxp.x..","..maxp.y..","..maxp.z..")")

  --easy reference to commonly used values
  local t1 = os.clock()
  local x1 = maxp.x
  local y1 = maxp.y
  local ymax=maxp.y
  local z1 = maxp.z
  local x0 = minp.x
  local y0 = minp.y
  local ymin=minp.y
  local z0 = minp.z

  --print ("bs [beanstalk_gen] chunk minp ("..x0.." "..y0.." "..z0..")") --tell people you are generating a chunk

  --This actually initializes the LVM
  local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
  local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
  local data = vm:get_data()

  local changedany=false
  local vinex={ } --just creates the variable for our array
  local vinez={ }


  local y
  local a
  y=y0
  if y<bnst_min.y then
    y=bnst_min.y  --no need to start below the beanstalk
  end


--cx=center point x
--cz=center point z
  local cx
  local cz

  repeat
    --minetest.log("bs y="..y.." bnst_vtot="..bnst_vtot)
    --lets get the beanstalk center based on 2ndary spiral
    a=(360/bnst_rot2yper360)*(y % bnst_rot2yper360)*bnst_rot2direction
    cx=bnst_pos.x+bnst_rot2radius*math.cos(a*math.pi/180)
    cz=bnst_pos.z+bnst_rot2radius*math.sin(a*math.pi/180)
    --minetest.log("bs a="..a.." cx="..cx.." cz="..cz)
    --now cx and cz are the new center of the beanstalk
    for v=0, bnst_vtot-1 do --calculate centers for each vine
      a=(360/bnst_vtot)*v+(360/bnst_yper360)*(y % bnst_yper360)*bnst_rotdirection
      vinex[v]=cx+bnst_rotradius*math.cos(a*math.pi/180)
      vinez[v]=cz+bnst_rotradius*math.sin(a*math.pi/180)
      --minetest.log("  bs v="..v.." a="..a.." vinex[v]="..vinex[v].." vinez[v]="..vinez[v])
    end --for v
    for x=x0, x1 do
      --minetest.log("bs xloop x="..x)
      for z=z0, z1 do
        local vi = area:index(x, y, z) -- This accesses the node at a given position
        --minetest.log("bs   zloop z="..z)
        local changedthis=false
        local v=0
        repeat
          --minetest.log("bs     vloop v="..v)
          local dist=math.sqrt((x-vinex[v])^2+(z-vinez[v])^2)
          if dist <= bnst_vineradius then  --inside stalk
            minetest.log("bs makevine  v="..v.." vinex[v]="..vinex[v].." vinez[v]="..vinez[v].." x="..x.." y="..y.." z="..z)
            data[vi]=bnst_stalk
            changedany=true
            changedthis=true
          elseif dist<=(bnst_vineradius+1) then --one node outside stalk
            checkvines(x,y,z, vinex[v],vinez[v], area,data)
            changedany=true
            changedthis=true
          end  --if dist
          --check vine
          v=v+1
        until v > bnst_vtot-1 or changedthis==true
        --local dist=math.sqrt((x-cx)^2+(z-cz)^2)
        --if changedthis==false and (dist>

        if changedthis==false and (math.sqrt((x-cx)^2+(z-cz)^2) < bnst_totradius) and (y > bnst_pos.y+30) then
          --minetest.log("bs makeair cx="..cx.." cz="..cz.." dist="..math.sqrt((x-cx)^2+(z-cz)^2.." bnst_pos.y="..bsnt_pos.y.." x="..x.." y="..y.." z="..z)
          --data[vi]=c_air
          changedany=true
        end --if changedthis=false
      end --for z
    end --for x
    y=y+1
  until y>bnst_max.y or y>y1


  if changedany==true then
    -- Wrap things up and write back to map
    --send data back to voxelmanip
    vm:set_data(data)
    --calc lighting
    vm:set_lighting({day=0, night=0})
    vm:calc_lighting()
    --write it to world
    vm:write_to_map(data)
    --minetest.log(">>>saved")
  end --if changed write to map

  local chugent = math.ceil((os.clock() - t1) * 1000) --grab how long it took
  minetest.log("bs [beanstalk_gen] "..chugent.." ms") --tell people how long
end -- beanstalk


minetest.register_on_generated(beanstalk)

