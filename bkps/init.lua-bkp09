--

---
--- constants
---
local bnst_count = { }
local bnst_per_row = { }
local bnst_max = { }  --count minus 1, for loops
local bnst_area = { }
local bnst_height = { }
local bnst_bot = { }
local bnst_top = { }

--
local bnst_level_max=0  --(counting up from 0, what is the highest "level" of beanstalks?)

--define by level  (each beanstalk level must have these values defined.  might add "weirdness" and specialized nodes?)
bnst_count[0]=16
bnst_bot[0]=-10
bnst_height[0]=6000

--calculated constants by level
for lv=0,bnst_level_max do
  bnst_per_row[lv]=math.floor(math.sqrt(bnst_count[lv]))  --beanstalks per row are the sqrt of beanstalks per level
  bnst_count[lv]=bnst_per_row[lv]*bnst_per_row[lv]  --recalculate to a perfect square
  bnst_max[lv]=bnst_count[lv]-1  --for use in array
  bnst_area[lv]=62000/bnst_per_row[lv]
  bnst_top[lv]=bnst_bot[lv]+bnst_height[lv]-1
end --for

--this function calculates (very approximately) the circumference of a circle of radius r in voxels
--this could be made much more accurate
function voxel_circum(r)
  if r==1 then return 4
  elseif r==2 then return 8
  else return 2*math.pi*r*0.88 --not perfect, but a pretty good estimate
  end --if
end --voxel_circum

--here we calculate the beanstalks based on the map seed, level, and beanstalk.
--so this should be consistent for any game with the same seed.
--this will run once every time minetest loads the game.
--however, we should probably eventually write these to a file once and read it
--after that instead of recalculating.  That would allow the server admin to set
--values as they wish.  (such as moving a beanstalk near spawn if they want)
local logstr
bnst={ }
local lv=0
bnst[lv]={ }  --this must be up here or scope will make it dissapear after the for loop
local mg_params = minetest.get_mapgen_params()  --this is how we get the mapgen seed
minetest.log("bnst list --------------------------------------")
for lv=0,bnst_level_max do  --loop through the levels
  minetest.log("***bnst level="..lv.." ***")
  for b=0,bnst_max[lv] do   --loop through the beanstalks
    --the seed looses digits near the end, probably I'm not storing it in the right kind of number var?
    --anyway, unless we multiply the lv and b up high like this, adding them to the seed makes no difference
    math.randomseed(mg_params.seed+ lv*10000000+b*100000)

    --this defines the variable, but I must be doing it wrong because I'm getting warnings about globals
    bnst[lv][b]={pos,rotradius,rotdirection,vineradius,vtot,yper360,rot2radius,rot2yper360,rot2direction,totradius,fullradius,minp,maxp,desc}

    bnst[lv][b].pos={x,y,z}
    --note that our random position is always at least 500 from the border, so that beanstalks can NEVER be right next to each other
    bnst[lv][b].pos.x=-31000 + (bnst_area[lv] * (b % bnst_per_row[lv]) + 500+math.random(0,bnst_area[lv]-1000) )
    bnst[lv][b].pos.y=bnst_bot[lv]
    bnst[lv][b].pos.z=-31000 + (bnst_area[lv] * (math.floor(b/bnst_per_row[lv]) % bnst_per_row[lv]) + 500 + math.random(0,bnst_area[lv]-1000) )

    --total number of vines
    if math.random(1,4)<4 then bnst[lv][b].vtot=3
    else bnst[lv][b].vtot=math.random(2,5)
    end

    --the radius the vines rotate around
    if math.random(1,4)<4 then bnst[lv][b].rotradius=math.random(5,7)
    else bnst[lv][b].rotradius=math.random(3,10)
    end

    --direction of rotation of the inner spiral
    if math.random(1,2)==1 then bnst[lv][b].rotdirection=1
    else bnst[lv][b].rotdirection=-1
    end

    --radius of each vine
    if math.random(1,4)<4 then bnst[lv][b].vineradius=math.random(2,6)
    else bnst[lv][b].vineradius=math.random(3,9)
    end

    --y units per one 360 degree rotation of a vine
    local c=voxel_circum(bnst[lv][b].rotradius)
    if math.random(1,4)<4 then bnst[lv][b].yper360=math.floor(math.random(c,80))
    else bnst[lv][b].yper360=math.floor(math.random(c*0.75,500))
    end

    --radius of the secondary spiral
    if math.random(1,4)<4 then bnst[lv][b].rot2radius=math.floor(math.random(bnst[lv][b].rotradius,bnst[lv][b].rotradius+5))
    else bnst[lv][b].rot2radius=math.floor(math.random(5,20))
    end

    --y units per one 365 degree rotation of secondary spiral
    local c=voxel_circum(bnst[lv][b].rot2radius)
    if math.random(1,4)<4 then bnst[lv][b].rot2yper360=math.floor(math.random(c,100))
    else bnst[lv][b].rot2yper360=math.floor(math.random(c*0.75,500))
    end

    --direction of rotation of the outer spiral
    if math.random(1,4)<4 then bnst[lv][b].rot2direction=bnst[lv][b].rotdirection
    else bnst[lv][b].rot2direction=-bnst[lv][b].rotdirection
    end

    -- total radius = rotradius (radius vines circle around) + vine radius + 2 more for a space around the beanstalk (will be air)    
    -- so this is the total radius around the current center
    bnst[lv][b].totradius=bnst[lv][b].rotradius+bnst[lv][b].vineradius+2
    -- but totradius can not be used for determining min and maxp, because the current center moves! for that we need     
    -- full radius = max diameter of entire beanstalk including outer spiral (rot2radius)
    bnst[lv][b].fullradius=bnst[lv][b].totradius+bnst[lv][b].rot2radius
    bnst[lv][b].minp={x=bnst[lv][b].pos.x-bnst[lv][b].fullradius, y=bnst[lv][b].pos.y, z=bnst[lv][b].pos.z-bnst[lv][b].fullradius}
    bnst[lv][b].maxp={x=bnst[lv][b].pos.x+bnst[lv][b].fullradius, y=bnst_top[lv], z=bnst[lv][b].pos.z+bnst[lv][b].fullradius}
    minetest.log("bnstz["..lv.."]["..b.."]: rotradius="..bnst[lv][b].rotradius.." vineradius="..bnst[lv][b].vineradius..
        " totradius="..bnst[lv][b].totradius.." fullradius="..bnst[lv][b].fullradius..
        " minp="..minetest.pos_to_string(bnst[lv][b].minp).." maxp="..minetest.pos_to_string(bnst[lv][b].maxp))

    --display it
    --minetest.log("bnst["..lv.."]["..b.."] "..minetest.pos_to_string(bnst[lv][b].pos).." vtot="..bnst[lv][b].vtot..
    --  " rotradius="..bnst[lv][b].rotradius.." rotdirection="..bnst[lv][b].rotdirection.." vineradius="..bnst[lv][b].vineradius..
    --  " yper360="..bnst[lv][b].yper360)
    --minetest.log("-------- rot2radius="..bnst[lv][b].rot2radius.." rot2yper360="..bnst[lv][b].rot2yper360.." rot2direction="..bnst[lv][b].rot2direction..
    --  " minp="..minetest.pos_to_string(bnst[lv][b].minp).." maxp="..minetest.pos_to_string(bnst[lv][b].maxp))
    --(-17680,-10000,-30122) vtot=3 vrad=5 rotrad=5 dir=-1 yper=53 rot2rad=10 rot2yper=78 rot2dir=-1
    logstr="bnst["..lv.."]["..b.."] "..minetest.pos_to_string(bnst[lv][b].pos).." vtot="..bnst[lv][b].vtot
    logstr=logstr.." vrad="..bnst[lv][b].vineradius.." rotrad="..bnst[lv][b].rotradius
    logstr=logstr.." dir="..bnst[lv][b].rotdirection.." yper="..bnst[lv][b].yper360
    logstr=logstr.." rot2rad="..bnst[lv][b].rot2radius.." rot2yper="..bnst[lv][b].rot2yper360.." rot2dir="..bnst[lv][b].rot2direction
    bnst[lv][b].desc=logstr
    minetest.log(logstr)
  end --for b
end --for lv
minetest.log("bnst list --------------------------------------")





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



--grab content IDs -- You need these to efficiently access and set node data.  get_node() works, but is far slower
local bnst_stalk=minetest.get_content_id("beanstalk:beanstalk")
local bnst_vines=minetest.get_content_id("beanstalk:vine")
local c_air = minetest.get_content_id("air")


--this function checks to see if a node should have vines.
--parms: x,y,z pos of this node, vcx vcz center of this vine, also pass area and data so we can check below
function checkvines(x,y,z, vcx,vcz, area,data)
  local vn = area:index(x, y, z)  --we get the node we are checking
  local vndown = area:index(x, y-1, z)  --and the node right below the one we are checking
  --if vn is not beanstalk or vines, and vndown is not beanstalk, then we will place a vine
  if data[vn]~=bnst_stalk and data[vn]~=bnst_vines and data[vndown]~=bnst_stalk then
    data[vn]=bnst_vines
    local pos={x=x,y=y,z=z}
    local node=minetest.get_node(pos)
    --we have the vine in place, but we need to rotate it with the vines
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
    node.param2=facedir --setting param2 on the node changes where it faces.
    minetest.swap_node(pos,node)
    --and for some reason I do not understand, you can't set it before you place it.
    --you have to set it afterwards and then swap it for it to take effect
  end --if
end --checkvines


--this is the function that will run EVERY time a chunk is generated.
--see at the bottom of this program where it is registered with:
--minetest.register_on_generated(beanstalk)
--minp is the min point of the chunk, maxp is the max point of the chunk
function beanstalk(minp, maxp, seed)
  --we dont want to waste any time in this function if the chunk doesnt have
  --a beanstalk in it.
  --so first we loop through the levels, if our chunk is not on a level where beanstalks
  --exist, we just do a return
  local chklv=-1
  local lv=-1
  repeat
    chklv=chklv+1
    if bnst_bot[chklv]<=maxp.y and bnst_top[chklv]>=minp.y then lv=chklv end
  until chklv==bnst_level_max or lv>-1
  if lv<0 then return end  --quit, we didn't match any level

  --now we know we are on a level with beanstalks, so we now need to check each beanstalk to
  --see if they intersect this chunk, if not, we return and waste no more cpu.
  --I think this could be made more efficent, seems we should be able to zero in on which
  --beanstalk to check better than just looping through them.
  local chkb=-1
  local b=-1
  repeat
    chkb=chkb+1
    --this checks to see if the chunk is within the beanstalk area
    if minp.x<=bnst[lv][chkb].maxp.x and maxp.x>=bnst[lv][chkb].minp.x and
       minp.y<=bnst[lv][chkb].maxp.y and maxp.y>=bnst[lv][chkb].minp.y and
       minp.z<=bnst[lv][chkb].maxp.z and maxp.z>=bnst[lv][chkb].minp.z then
         b=chkb  --we are in the beanstalk!
    end --if
  until chkb==bnst_max[lv] or b>-1
  if b<0 then return end --quit; otherwise, you'd have wasted resources

  --ok, now we know we are in a chunk that has beanstalk in it, so we need to do the work
  --required to generate the beanstalk

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
  local vinex={ } --initializing the variable so we can use it for an array later
  local vinez={ }

  local y
  local a1
  local a2

  --y0 is the bottom of the chunk, but if y0<the bottom of the beanstalk, then we
  --will reset y to the bottom of the beanstalk to avoid wasting cpu
  y=y0
  if y<bnst[lv][b].minp.y then
    y=bnst[lv][b].minp.y  --no need to start below the beanstalk
  end

  local cx   --cx=center point x
  local cz   --cz=center point z

  --this top repeat is where we loop through the chunk based on y
  repeat
    --lets get the beanstalk center based on 2ndary spiral
    a2=(360/bnst[lv][b].rot2yper360)*(y % bnst[lv][b].rot2yper360)*bnst[lv][b].rot2direction
    cx=bnst[lv][b].pos.x+bnst[lv][b].rot2radius*math.cos(a2*math.pi/180)
    cz=bnst[lv][b].pos.z+bnst[lv][b].rot2radius*math.sin(a2*math.pi/180)
    
    --now cx and cz are the new center of the beanstalk
    for v=0, bnst[lv][b].vtot-1 do --calculate centers for each vine
      a1=(360/bnst[lv][b].vtot)*v+(360/bnst[lv][b].yper360)*(y % bnst[lv][b].yper360)*bnst[lv][b].rotdirection
      vinex[v]=cx+bnst[lv][b].rotradius*math.cos(a1*math.pi/180)
      vinez[v]=cz+bnst[lv][b].rotradius*math.sin(a1*math.pi/180)
    end --for v

    --these two for loops loop through the chunk based x and z
    for x=x0, x1 do
      for z=z0, z1 do
        local vi = area:index(x, y, z) -- This accesses the node at a given position
        local changedthis=false
        local v=0
        repeat
          --minetest.log("bs     vloop v="..v)
          local dist=math.sqrt((x-vinex[v])^2+(z-vinez[v])^2)
          if dist <= bnst[lv][b].vineradius then  --inside stalk
            --minetest.log("bs makevine  v="..v.." vinex[v]="..vinex[v].." vinez[v]="..vinez[v].." x="..x.." y="..y.." z="..z)
            data[vi]=bnst_stalk
            changedany=true
            changedthis=true
          elseif dist<=(bnst[lv][b].vineradius+1) then --one node outside stalk
            checkvines(x,y,z, vinex[v],vinez[v], area,data)
            changedany=true
            changedthis=true
          end  --if dist
          --check vine
          v=v+1
        until v > bnst[lv][b].vtot-1 or changedthis==true
        if changedthis==false and (math.sqrt((x-cx)^2+(z-cz)^2) < bnst[lv][b].totradius) and (y > bnst[lv][b].pos.y+30) then
          changedany=true
        end --if changedthis=false
      end --for z
    end --for x
    y=y+1
  until y>bnst[lv][b].maxp.y or y>y1


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
  minetest.log("bnst[lv]["..b.."] [beanstalk_gen] "..chugent.." ms") --tell people how long
end -- beanstalk


--this is what makes the beanstalk function run every time a chunk is generated
minetest.register_on_generated(beanstalk)


--list_beanstalks and go_beanstalk are mainly here for testing
--neither one will probably stay once this is complete
function list_beanstalks(playername)
  local player = minetest.get_player_by_name(playername)
  local lv=0
  local b
  for lv=0,bnst_level_max do  --loop through the levels
    minetest.chat_send_player(playername,"***bnst level="..lv.." ***")
    for b=0,bnst_max[lv] do   --loop through the beanstalks
       minetest.chat_send_player(playername, bnst[lv][b].desc.." "..minetest.pos_to_string(bnst[lv][b].pos))
    end --for b
  end --for lv
end --list_beanstalks

function go_beanstalk(playername,param)
  local player = minetest.get_player_by_name(playername)
  if param=="" then minetest.chat_send_player(playername,"format is go_beanstalk <lv>,<b>") 
  else
		--local lv, b = param:find("^(-?%d+)[, ](-?%d+)$")  --splits param on comma or space
    local slv,sb = string.match(param,"([^,]+),([^,]+)")
    local lv=tonumber(slv)
    local b=tonumber(sb)
    local p={x=bnst[lv][b].pos.x,y=bnst[lv][b].pos.y,z=bnst[lv][b].pos.z}
    --NEVER do local p=bnst[lv][b].pos passes by reference not value and you will change the original bnst pos!
    p.x=p.x+bnst[lv][b].fullradius+2
    p.y=p.y+13
    player:setpos(p)
  end --if  
end --go_beanstalk

minetest.register_chatcommand("go_beanstalk", {
	params = "<lv> <b>",
	description = "go_beanstalk <lv>,<b>: teleport to beanstalk location",
	func = function (name,param)
		go_beanstalk(name,param)
	end,
})

minetest.register_chatcommand("list_beanstalks", {
	params = "",
	description = "list_beanstalks: list the beanstalk locations",
	func = function (name, param)
		list_beanstalks(name)
	end,
})



--saving these because we MIGHT later have an array of some really good/interesting looking beanstalks
--and make them about 1/4th of the beanstalks?

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

--      minetest.log("---bnstc["..lv.."]["..b.."]: v="..v.." y="..y.." a2="..a2.." a1="..a1.." rot2yper360="..bnst[lv][b].rot2yper360..
--          " rot2direction="..bnst[lv][b].rot2direction.." rot2radius="..bnst[lv][b].rot2radius.." yper360="..bnst[lv][b].yper360)
--      minetest.log("bnstC["..lv.."]["..b.."] rotdirection="..bnst[lv][b].rotdirection.." rotradius="..bnst[lv][b].rotradius..
--          " pos="..minetest.pos_to_string(bnst[lv][b].pos).." cos="..math.cos(a2*math.pi/180))
--      minetest.log("bnstC["..lv.."]["..b.."]: cx="..cx.." cz="..cz.." vinex="..vinex[v].." vinez="..vinez[v])
--      minetest.log("bnstc["..lv.."]["..b.."]: y % rot2yper360="..(y % bnst[lv][b].rot2yper360).." y % yper360="..y % bnst[lv][b].yper360)