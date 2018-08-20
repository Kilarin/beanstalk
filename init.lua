--

---
--- constants
---

--local bnst_pos={x=100,y=0,z=100}

--local bnst_rotradius=6    --the radius the vines rotate around
--local bnst_rotdirection=1   --direction of rotation of the inner spiral
--local bnst_vineradius=4   --radius of each vine
--local bnst_vtot=3         --total number of vines
--local bnst_yper360=48     --y units per one 360 degree rotation of a vine
--local bnst_rot2radius=6   --radius of the secondary spiral
--local bnst_rot2yper360=80 --y units per one 365 degree rotation of secondary spiral
--local bnst_rot2direction=1  --direction of rotation of the outer spiral

local bnst_per_level=16
bnst_per_row=math.floor(math.sqrt(bnst_per_level))  --beanstalks per row are the sqrt of beanstalks per level
local bsnt_levels=1
local bnst_count=bnst_per_row*bnst_per_row
local bnst_max=bnst_count-1  --for use in array
bnst_area=62000/bnst_per_row


--returns a pos that is rounded special case.  round 0 digits for X and Z,
--round 1 digit for Y
--function beanstalk.round_pos(pos)
--  pos.x=beanstalk.round_digits(pos.x,0)
--  pos.y=beanstalk.round_digits(pos.y,1)
--  pos.z=beanstalk.round_digits(pos.z,0)
--  return pos
--end --round_pos
--
--function beanstalk.round_digits(num,digits)
--	if num >= 0 then return math.floor(num*(10^digits)+0.5)/(10^digits)
--  else return math.ceil(num*(10^digits)-0.5)/(10^digits)
--  end
--end --round_digits
--
--function beanstalk.pos_to_string(pos)
--	if pos==nil then return "(nil)"
--	else
--    pos=beanstalk.round_pos(pos)
--    return "("..pos.x.." "..pos.y.." "..pos.z..")"
--	end --pos==nill
--end --pos_to_string


local bnst={ }

--math.randomseed
for b=0, bnst_max do
  bnst[b]={pos,rotradius,rotdirection,vineradius,vtot,yper360,rot2radius,rot2yper360,rot2direction,totradius,minp,maxp}
  bnst[b].pos={x,y,z}
  bnst[b].pos.x=-31000+(bnst_area/2)+(bnst_area* (b % bnst_per_row) ) --temporary
  bnst[b].pos.z=-31000+(bnst_area/2)+(bnst_area* (math.floor(b/bnst_per_row) % bnst_per_row) ) --temporary
  --minetest.log("-31000+(bnst_area/2)+(bnst_area* ((b/bnst_per_row) % bnst_per_row) )")
  --minetest.log("-31000+("..(bnst_area/2)..")+("..bnst_area.."* (("..(b/bnst_per_row)..") %"..bnst_per_row..") )   >"..(b/bnst_per_row) % bnst_per_row) 
  
  bnst[b].pos.y=0                                  --temporary  
  bnst[b].rotradius=6           --the radius the vines rotate around
  bnst[b].rotdirection=1        --direction of rotation of the inner spiral
  bnst[b].vineradius=4          --radius of each vine
  bnst[b].vtot=3                --total number of vines
  bnst[b].yper360=48            --y units per one 360 degree rotation of a vine
  bnst[b].rot2radius=6          --radius of the secondary spiral
  bnst[b].rot2yper360=80        --y units per one 365 degree rotation of secondary spiral
  bnst[b].rot2direction=1       --direction of rotation of the outer spiral
  -- total radius = rotradius (radius vines circle around) + vine radius + 2 more for a space around the beanstalk (will be air)
  bnst[b].totradius=bnst[b].rotradius+bnst[b].vineradius+2
  bnst[b].minp={x=bnst[b].pos.x-bnst[b].totradius, y=bnst[b].pos.y, z=bnst[b].pos.z-bnst[b].totradius}
  bnst[b].maxp={x=bnst[b].pos.x+bnst[b].totradius, y=5000, z=bnst[b].pos.z+bnst[b].totradius}  --y=5000 is temp  
  minetest.log("bnst["..b.."] "..pos_to_string(bnst[b].pos).." minp="..pos_to_string(bnst[b].minp).." maxp="..pos_to_string(bnst[b].maxp))
  end --for
--2018-08-19 13:30:17: [Main]: bnst[0] (-23250,0,-23250) min=(-23262,0,-23262) max=(-23238,5000,-23238)  


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


--grab content IDs -- You need these to efficiently access and set node data.  get_node() works, but is far slower
local bnst_stalk=minetest.get_content_id("beanstalk:beanstalk")
local bnst_vines=minetest.get_content_id("beanstalk:vine")
local c_air = minetest.get_content_id("air")


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
  --minetest.log("-xbnstx- minp="..pos_to_string(minp).." maxp="..pos_to_string(maxp))
  local i=-1
  local b=-1
  repeat  
    i=i+1
    minetest.log("-xbnstx- bnst["..i.."] "..pos_to_string(bnst[i].pos).." min="..pos_to_string(bnst[i].minp).." max="..pos_to_string(bnst[i].maxp))
    --this checks to see if the chunk is within the beanstalk area     
    if minp.x<=bnst[i].maxp.x and maxp.x>=bnst[i].minp.x and
       minp.y<=bnst[i].maxp.y and maxp.y>=bnst[i].minp.y and
       minp.z<=bnst[i].maxp.z and maxp.z>=bnst[i].minp.z then        
         b=i  --we are in the beanstalk!
    end --if    
  until i==bnst_max or b>-1
  if b<0 then return end--quit; otherwise, you'd have wasted resources  
  --minetest.log("bnst["..b.."] accepted: min=("..minp.x..","..minp.y..","..minp.z..") max=("..maxp.x..","..maxp.y..","..maxp.z..")")

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

  --minetest.log("bs [beanstalk_gen] chunk minp ("..x0.." "..y0.." "..z0..")") --tell people you are generating a chunk

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
  if y<bnst[b].minp.y then
    y=bnst[b].minp.y  --no need to start below the beanstalk
  end


--cx=center point x
--cz=center point z
  local cx
  local cz

  repeat
    --lets get the beanstalk center based on 2ndary spiral
    a=(360/bnst[b].rot2yper360)*(y % bnst[b].rot2yper360)*bnst[b].rot2direction
    cx=bnst[b].pos.x+bnst[b].rot2radius*math.cos(a*math.pi/180)
    cz=bnst[b].pos.z+bnst[b].rot2radius*math.sin(a*math.pi/180)
    --minetest.log("bs a="..a.." cx="..cx.." cz="..cz)
    --now cx and cz are the new center of the beanstalk
    for v=0, bnst[b].vtot-1 do --calculate centers for each vine
      a=(360/bnst[b].vtot)*v+(360/bnst[b].yper360)*(y % bnst[b].yper360)*bnst[b].rotdirection
      vinex[v]=cx+bnst[b].rotradius*math.cos(a*math.pi/180)
      vinez[v]=cz+bnst[b].rotradius*math.sin(a*math.pi/180)
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
          if dist <= bnst[b].vineradius then  --inside stalk
            minetest.log("bs makevine  v="..v.." vinex[v]="..vinex[v].." vinez[v]="..vinez[v].." x="..x.." y="..y.." z="..z)
            data[vi]=bnst_stalk
            changedany=true
            changedthis=true
          elseif dist<=(bnst[b].vineradius+1) then --one node outside stalk
            checkvines(x,y,z, vinex[v],vinez[v], area,data)
            changedany=true
            changedthis=true
          end  --if dist
          --check vine
          v=v+1
        until v > bnst[b].vtot-1 or changedthis==true
        --local dist=math.sqrt((x-cx)^2+(z-cz)^2)
        --if changedthis==false and (dist>

        if changedthis==false and (math.sqrt((x-cx)^2+(z-cz)^2) < bnst[b].totradius) and (y > bnst[b].pos.y+30) then
          --minetest.log("bs makeair cx="..cx.." cz="..cz.." dist="..math.sqrt((x-cx)^2+(z-cz)^2.." bnst[b].pos.y="..bsnt_pos.y.." x="..x.." y="..y.." z="..z)
          --data[vi]=c_air
          changedany=true
        end --if changedthis=false
      end --for z
    end --for x
    y=y+1
  until y>bnst[b].maxp.y or y>y1


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
  minetest.log("bnst["..b.." [beanstalk_gen] "..chugent.." ms") --tell people how long
end -- beanstalk


minetest.register_on_generated(beanstalk)

