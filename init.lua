--beanstalk

beanstalk = { } --will be used to hold functions.

--These are the constants that need to be modified based on your game needs
--we store all the important variables in a single table, bnst, this makes it easy to
--write to a file and read from a file

local bnst={["level_max"]=0}   --(counting up from 0, what is the highest "level" of beanstalks?)

--define by level  (each beanstalk level must have these values defined.  might add "weirdness" and specialized nodes?)
bnst[0]={"count","bot","height","per_row","area","top","max" }
bnst[0].count=16
bnst[0].bot=-10
bnst[0].height=6000
--once you create a beanstalk file, these values will be ignored!  that seems problematic!


--this is the perlin noise that will be used for "crazy" beanstalks
--I don't really understand how these parms work, but this link has
--a nice attempt at explaining: https://forum.minetest.net/viewtopic.php?f=47&t=13278#p194281
local np_crazy =
  {
   offset = 0,
   scale = 1,
   --spread = {x=192, y=512, z=512}, -- squashed 2:1
   --spread = {x=200, y=80, z=80},
	spread = {x=15, y=8, z=8},
   seed = 0, --this will be overriden
   octaves = 1,
   persist = 0.67
   }

-- ----- below here you shouldnt need to customize -----



--this function calculates (very approximately) the circumference of a circle of radius r in voxels
--this could be made much more accurate
--this function has to be way up here because it has to be defined before it is used
function beanstalk.voxel_circum(r)
  if r==1 then return 4
  elseif r==2 then return 8
  else return 2*math.pi*r*0.88 --not perfect, but a pretty good estimate
  end --if
end --voxel_circum


--this runs BEFORE create_beanstalks_rnd (but after read from file)
function beanstalk.calculated_constants_1()
  --calculated constants by level  
  minetest.log("beanstalk-> calculated constants by level")
  for lv=0,bnst.level_max do
    bnst[lv].per_row=math.floor(math.sqrt(bnst[lv].count))  --beanstalks per row are the sqrt of beanstalks per level
    bnst[lv].count=bnst[lv].per_row*bnst[lv].per_row  --recalculate to a perfect square
    bnst[lv].max=bnst[lv].count-1  --for use in array
    bnst[lv].area=62000/bnst[lv].per_row
    bnst[lv].top=bnst[lv].bot+bnst[lv].height-1
  end --for
end --calculated_constants_1


--this runs AFTER create_beanstalks_rnd
function beanstalk.calculated_constants_2()
  --calculated constants by beanstalk
  minetest.log("beanstalk-> calculated constants by beanstalk")
  minetest.log("beanstalk-> list --------------------------------------")
  for lv=0,bnst.level_max do  --loop through the levels
    minetest.log("***beanstalk-> level="..lv.." ***")
    for b=0,bnst[lv].max do   --loop through the beanstalks        
      bnst[lv][b].rot1min=bnst[lv][b].rot1radius --default if we dont set crazy 
      bnst[lv][b].rot1max=bnst[lv][b].rot1radius --default if we dont set crazy 
      bnst[lv][b].rot2min=bnst[lv][b].rot2radius --default if we dont set crazy *!*
      bnst[lv][b].rot2max=bnst[lv][b].rot2radius --default if we dont set crazy *!*  
      if bnst[lv][b].crazy1>0 then
        --determine the min and max we will move the rot1radius through
        bnst[lv][b].rot1max=bnst[lv][b].rot1radius+bnst[lv][b].crazy1
        bnst[lv][b].rot1min=bnst[lv][b].rot1radius-bnst[lv][b].crazy1
        if bnst[lv][b].rot1min<bnst[lv][b].vineradius then --we dont want min to be too small
          bnst[lv][b].rot1max=bnst[lv][b].rot1max+(bnst[lv][b].vineradius-bnst[lv][b].rot1min) --add what we take off the min to the max
          bnst[lv][b].rot1min=bnst[lv][b].vineradius
        end --if rot1min<vineradius
      end --if crazy1>0
      
      --now, right here would be a GREAT place to create and store the perlin noise.
      --BUT, you can do that at this point, because the map isn't generated.  and for some odd reason, the perlin noise function
      --exits as nil if you use it before map generation.  so we will do it in the generation loop
      --perlin noise is random, but SMOOTH, so it makes interesting looking vine changes.
      --we need to play with the perlin noise values and see if we can get results we like better  
      
      if bnst[lv][b].crazy2>0 then
        --determine the min and max we will move the rot2radius through
        bnst[lv][b].rot2max=bnst[lv][b].rot2radius+bnst[lv][b].crazy2
        bnst[lv][b].rot2min=bnst[lv][b].rot2radius-bnst[lv][b].crazy2
        if bnst[lv][b].rot2min<0 then --we dont want min to be too small
          bnst[lv][b].rot2max=bnst[lv][b].rot2max+math.abs(bnst[lv][b].rot2min) --add what we take off the min to the max
          bnst[lv][b].rot2min=0
        end --if rot2min<0
      end --if crazy2>0    
      
      -- total radius = rot1radius (radius vines circle around) + vine radius + 2 more for a space around the beanstalk (will be air)
      -- so this is the total radius around the current center
      bnst[lv][b].totradius=bnst[lv][b].rot1max+bnst[lv][b].vineradius+2
      -- but totradius can not be used for determining min and maxp, because the current center moves! for that we need
      -- full radius = max diameter of entire beanstalk including outer spiral (rot2radius)
      bnst[lv][b].fullradius=bnst[lv][b].totradius+bnst[lv][b].rot2max
      bnst[lv][b].minp={x=bnst[lv][b].pos.x-bnst[lv][b].fullradius, y=bnst[lv][b].pos.y, z=bnst[lv][b].pos.z-bnst[lv][b].fullradius}
      bnst[lv][b].maxp={x=bnst[lv][b].pos.x+bnst[lv][b].fullradius, y=bnst[lv].top, z=bnst[lv][b].pos.z+bnst[lv][b].fullradius}

      --display it
      logstr="bnst["..lv.."]["..b.."] "..minetest.pos_to_string(bnst[lv][b].pos).." vtot="..bnst[lv][b].vtot
      logstr=logstr.." vrad="..bnst[lv][b].vineradius.." rotrad="..bnst[lv][b].rot1radius
      logstr=logstr.." dir="..bnst[lv][b].rot1dir.." yper="..bnst[lv][b].rot1yper360
      logstr=logstr.." rot2rad="..bnst[lv][b].rot2radius.." rot2yper="..bnst[lv][b].rot2yper360.." rot2dir="..bnst[lv][b].rot2dir
      logstr=logstr.." crazy1="..bnst[lv][b].crazy1.." crazy2="..bnst[lv][b].crazy2
      bnst[lv][b].desc=logstr
      minetest.log(logstr)       
    end --for b
  end --for lv  
  minetest.log("beanstalk-> list --------------------------------------")  
end --calculated_constants_2


--saves the bnst list in minetest/words/<worldname>/beanstalks
function beanstalk.write_beanstalks()
  minetest.log("beanstalk-> write_beanstalks")
	local file = io.open(minetest.get_worldpath().."/beanstalks", "w")
	if file then
    --wipe out variables that we will recalculate
    for lv=0,bnst.level_max do  --loop through the levels
      bnst[lv].per_row=nil
      bnst[lv].area=nil
      bnst[lv].top=nil
      for b=0,bnst[lv].max do   --loop through the beanstalks      
        bnst[lv][b].rot1min=nil
        bnst[lv][b].rot1max=nil
        bnst[lv][b].rot2min=nil
        bnst[lv][b].rot2max=nil
        bnst[lv][b].totradius=nil
        bnst[lv][b].fullradius=nil
        bnst[lv][b].minp=nil
        bnst[lv][b].maxp=nil
        bnst[lv][b].desc=nil
      end --for b
      bnst[lv].max=nil      
    end --for lv       
    
		file:write(minetest.serialize(bnst))
		file:close()
	end
end --write_beanstalks



-- document
function beanstalk.create_beanstalks()
  minetest.log("beanstalk-> create beanstalks")

  --here we calculate the beanstalks based on the map seed, level, and beanstalk.
  --so this should be consistent for any game with the same seed.
  --this will run once every time minetest loads the game.
  --however, we should probably eventually write these to a file once and read it
  --after that instead of recalculating.  That would allow the server admin to set
  --values as they wish.  (such as moving a beanstalk near spawn if they want)
  local logstr
  local lv=0
  
  --we need these values calculated before we do some of the things below:
  beanstalk.calculated_constants_1()
  
  --get_mapgen_params is deprecated; use get_mapgen_setting 
  --local mg_params = minetest.get_mapgent_setting()
  local mg_params = minetest.get_mapgen_params()  --this is how we get the mapgen seed

  for lv=0,bnst.level_max do  --loop through the levels
    for b=0,bnst[lv].max do   --loop through the beanstalks

      --this defines the variable, I THINK I've finally got this part formatted correctly, mostly anyway.
      bnst[lv][b]={["pos"]={["x"]=0,["y"]=0,["z"]=0},["rot1radius"]=0,["rot1dir"]=0,["vineradius"]=0,["vtot"]=0,
                   ["yper360"]=0,["rot2radius"]=0,["rot2yper360"]=0,["rot2dir"]=0,["totradius"]=0,["fullradius"]=0,
                   ["minp"]=0,["maxp"]=0,["desc"]=0,["seed"]=0,["crazy1"]=0,["crazy2"]=0,["rot1min"]=0,["rot1max"]=0,
                   ["rot2min"]=0,["rot2max"]=0,["noise1"]=0,["noise2"]=0}

      --the seed looses digits near the end, probably I'm not storing it in the right kind of number var?
      --anyway, unless we multiply the lv and b up high like this, adding them to the seed makes no difference
      bnst[lv][b].seed=mg_params.seed+lv*10000000+b*100000
      math.randomseed(bnst[lv][b].seed)

      --note that our random position is always at least 500 from the border, so that beanstalks can NEVER be right next to each other
      bnst[lv][b].pos.x=-31000 + (bnst[lv].area * (b % bnst[lv].per_row) + 500+math.random(0,bnst[lv].area-1000) )
      --minetest.log("bnstx 2: lv="..lv.." bnst[lv].bot="..bnst[lv].bot)
      bnst[lv][b].pos.y=bnst[lv].bot
      --minetest.log("bnstx 3: b="..b.." bnst[lv][b].pos.y="..bnst[lv][b].pos.y)
      bnst[lv][b].pos.z=-31000 + (bnst[lv].area * (math.floor(b/bnst[lv].per_row) % bnst[lv].per_row) + 500 + math.random(0,bnst[lv].area-1000) )

      --total number of vines
      if math.random(1,4)<4 then bnst[lv][b].vtot=3
      else bnst[lv][b].vtot=math.random(2,5)
      end

      --direction of rotation of the inner spiral
      if math.random(1,2)==1 then bnst[lv][b].rot1dir=1
      else bnst[lv][b].rot1dir=-1
      end

      --radius of each vine
      if math.random(1,4)<4 then bnst[lv][b].vineradius=math.random(2,6)
      else bnst[lv][b].vineradius=math.random(3,9)
      end

      --the radius the vines rotate around
      if math.random(1,4)<4 then bnst[lv][b].rot1radius=math.random(5,8)
      else bnst[lv][b].rot1radius=math.random(3,10)
      end
      --vines merge too much if the rotation radius isn't at least vineradius
      if bnst[lv][b].rot1radius<bnst[lv][b].vineradius then bnst[lv][b].rot1radius=bnst[lv][b].vineradius
      end

      --y units per one 360 degree rotation of a vine
      local c=beanstalk.voxel_circum(bnst[lv][b].rot1radius)
      if math.random(1,4)<4 then bnst[lv][b].rot1yper360=math.floor(math.random(c,80))
      else bnst[lv][b].rot1yper360=math.floor(math.random(c*0.75,100))
      end

      --radius of the secondary spiral
      if math.random(1,4)<4 then bnst[lv][b].rot2radius=math.floor(math.random(3,bnst[lv][b].rot1radius+5))
      else bnst[lv][b].rot2radius=math.floor(math.random(0,16))
      end

      --y units per one 365 degree rotation of secondary spiral
      local c=beanstalk.voxel_circum(bnst[lv][b].rot2radius)
      if math.random(1,4)<4 then bnst[lv][b].rot2yper360=math.floor(math.random(c,100))
      else bnst[lv][b].rot2yper360=math.floor(math.random(c*0.75,500))
      end

      --direction of rotation of the outer spiral
      if math.random(1,4)<4 then bnst[lv][b].rot2dir=bnst[lv][b].rot1dir
      else bnst[lv][b].rot2dir=-bnst[lv][b].rot1dir
      end

      --crazy1
      --crazy gives us a number from 0 to 6 (may expand that in the future)
      --the biger the number, the bigger the range of change in the crazy vine
      --note that this is the number we change each way, so crazy=3 means from radius-3 to radius+3
      --and crazy=6 is a whopping TWELVE change in radius, that should be VERY noticible
      --once we have the crazy value, we establish the rot1min and max
      bnst[lv][b].noise1=nil
      bnst[lv][b].crazy1=math.random(1,12)-6
      if bnst[lv][b].crazy1<0 then bnst[lv][b].crazy1=0 end
      if bnst[lv][b].crazy1>0 then
        --very low values for crazy are just not visible enough of an effect, so we increase so min is 3
        bnst[lv][b].crazy1=bnst[lv][b].crazy1+2        
      end --if crazy1>0

      --crazy2 like crazy1, but this is for the outer spiral
      bnst[lv][b].noise2=nil
      bnst[lv][b].crazy2=math.random(1,12)-6
      if bnst[lv][b].crazy2<0 then bnst[lv][b].crazy2=0 end
      if bnst[lv][b].crazy2>0 then
        --small cazy values for crazy2 just don't have a big enough effect, so we multiply by 2
        bnst[lv][b].crazy2=(bnst[lv][b].crazy2*2)+math.random(3,5) -- now we have 5 to 17
      end --if crazy2>0
    end --for b
  end --for lv

  --now that we have created all the values, we need to write them to the file.
  beanstalk.write_beanstalks()
  --but that wiped out some of our calculated constants 1, so lets redo them 
  beanstalk.calculated_constants_1()
  --and also get the beanstalk level calculated constants
  beanstalk.calculated_constants_2()  
end --create_beanstalks




--get beanstalks, from file if exists, otherwise generate
function beanstalk.read_beanstalks()  
  minetest.log("beanstalk-> reading beanstalks file")
  local file = io.open(minetest.get_worldpath().."/beanstalks", "r")
  if file then
  	bnst = minetest.deserialize(file:read("*all"))
    -- check if it was an empty file because empty files can crash server
  	if bnst == nil then
  	  print("beanstalk: ERROR: beanstalk file exists but is empty, will recreate")
  	  beanstalk.create_beanstalks()
    else  --file exists and was loaded 
      beanstalk.calculated_constants_1()
      beanstalk.calculated_constants_2() 
  	end  --if bnst==nil    
  	file:close() 
  else --file does not exist
    beanstalk.create_beanstalks()
  end --if file
end --read_beanstalks


--this registers the beanstalk node
--in future, we might want different nodes with different colors/patterns
--to be used on different levels?
--also, may want to make this NOT flamable and hard to chop?
minetest.register_node("beanstalk:beanstalk", {
  description = "Beanstalk Stalk",
  tiles = {"beanstalk_top_32.png", "beanstalk_top_32.png", "beanstalk_side_32.png"},
  paramtype2 = "facedir",
  is_ground_content = false,
  --climbable = true,
  groups = {snappy=1,choppy=3,flammable=2},
  sounds = default.node_sound_wood_defaults(),
  on_place = minetest.rotate_node,

  --after_dig_node = function(pos, node, metadata, digger)
  --  default.dig_up(pos, node, digger)
  --end,
})

--this registers the vine node.  later we might want to make this so
--that it only registers a new node if you are not using a mod that
--already has vines.
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




--https://forum.minetest.net/viewtopic.php?f=9&t=2333&hilit=node+box
minetest.register_node("beanstalk:leaf", {
	description = "beanstalk:leaf",
  drawtype = "nodebox",
  tiles = {"beanstalk-leaf-top.png","beanstalk-leaf-top.png","beanstalk-leaf-top.png",
           "beanstalk-leaf-top.png","beanstalk-leaf-top.png","beanstalk-leaf-top.png"},
  paramtype = "light",
  paramtype2 = "facedir",
	inventory_image = "beanstalk-leaf-top.png",
	wield_image = "beanstalk-leaf-top.png",
  groups = {snappy=1,choppy=3,flammable=2},
  sounds = default.node_sound_wood_defaults(),
  walkable = true,
  climbable= false,
  is_ground_content = false,
    node_box = {
      type = "fixed",
      --fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5}, --makes half block
      --fixed = {-0.5, -0.5, -0.5, 0.5,-0.25, 0.5},--makes quarter block
      --fixed = {-0.5, -0.5, -0.5, 0.5,-0.25, 0.25}, --quarter height, 3/4 length
      --fixed = {-0.5, -0.5, -0.5, -0.25,-0.25, 0.5},  --this makes a 1/4 x 1/4 rectangle!
      --fixed = {-0.5, -0.5, -0.5, -0.25,-0.25, 0.5},
			fixed = {-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5}, -- NodeBox1
    }
})


minetest.register_node("beanstalk:leaf_edge", {
	description = "beanstalk:leaf edge",
  drawtype = "nodebox",
  tiles = {"beanstalk-leaf-top.png","beanstalk-leaf-top.png","beanstalk-leaf-top.png",
           "beanstalk-leaf-top.png","beanstalk-leaf-top.png","beanstalk-leaf-top.png"},
  paramtype = "light",
  paramtype2 = "facedir",
	inventory_image = "beanstalk-leaf-edge.png",
	wield_image = "beanstalk-leaf-edge.png",
  groups = {snappy=1,choppy=3,flammable=2},
  sounds = default.node_sound_wood_defaults(),
  walkable = true,
  climbable= false,
  is_ground_content = false,
    node_box = {
      type = "fixed",
			fixed={
      {-0.5, -0.5, -0.5, -0.4375, -0.4375, 0.5}, -- NodeBox1
			{-0.4375, -0.5, -0.5, -0.375, -0.4375, 0.4375}, -- NodeBox2
			{-0.375, -0.5, -0.5, -0.3125, -0.4375, 0.375}, -- NodeBox3
			{-0.3125, -0.5, -0.5, -0.25, -0.4375, 0.3125}, -- NodeBox4
			{-0.25, -0.5, -0.5, -0.1875, -0.4375, 0.25}, -- NodeBox5
			{-0.1875, -0.5, -0.5, -0.125, -0.4375, 0.1875}, -- NodeBox6
			{-0.125, -0.5, -0.5, -0.0625, -0.4375, 0.125}, -- NodeBox7
			{-0.0625, -0.5, -0.5, 0, -0.4375, 0.0625}, -- NodeBox8
			{0, -0.5, -0.5, 0.0625, -0.4375, 0}, -- NodeBox9
			{0.0625, -0.5, -0.5, 0.125, -0.4375, -0.0625}, -- NodeBox10
			{0.125, -0.5, -0.5, 0.1875, -0.4375, -0.125}, -- NodeBox11
			{0.1875, -0.5, -0.5, 0.25, -0.4375, -0.1875}, -- NodeBox12
			{0.25, -0.5, -0.5, 0.3125, -0.4375, -0.25}, -- NodeBox13
			{0.3125, -0.5, -0.5, 0.375, -0.4375, -0.3125}, -- NodeBox14
			{0.375, -0.5, -0.5, 0.4375, -0.4375, -0.375}, -- NodeBox15
			{0.4375, -0.5, -0.5, 0.5, -0.4375, -0.4375}, -- NodeBox16
      }
    }
})





minetest.register_node("beanstalk:leaf_point_short", {
	description = "beanstalk:leaf point short",
  drawtype = "nodebox",
  tiles = {"beanstalk-leaf-top.png"},
  paramtype = "light",
  paramtype2 = "facedir",
	inventory_image = "beanstalk-leaf-point-short.png",
	wield_image = "beanstalk-leaf-point-short.png",
  groups = {snappy=1,choppy=3,flammable=2},
  sounds = default.node_sound_wood_defaults(),
  walkable = true,
  climbable= false,
  is_ground_content = false,
    node_box = {
      type = "fixed",
			fixed={
      {-0.5, -0.5, -0.5, -0.4375, -0.4375, -0.4375}, -- NodeBox1
			{-0.4375, -0.5, -0.5, -0.375, -0.4375, -0.375}, -- NodeBox2
			{-0.375, -0.5, -0.5, -0.3125, -0.4375, -0.3125}, -- NodeBox3
			{-0.3125, -0.5, -0.5, -0.25, -0.4375, -0.25}, -- NodeBox4
			{-0.25, -0.5, -0.5, -0.1875, -0.4375, -0.1875}, -- NodeBox5
			{-0.1875, -0.5, -0.5, -0.125, -0.4375, -0.125}, -- NodeBox6
			{-0.125, -0.5, -0.5, -0.0625, -0.4375, -0.0625}, -- NodeBox7
			{-0.0625, -0.5, -0.5, 0, -0.4375, 0}, -- NodeBox8
			{0, -0.5, -0.5, 0.0625, -0.4375, 0}, -- NodeBox9
			{0.0625, -0.5, -0.5, 0.125, -0.4375, -0.0625}, -- NodeBox10
			{0.125, -0.5, -0.5, 0.1875, -0.4375, -0.125}, -- NodeBox11
			{0.1875, -0.5, -0.5, 0.25, -0.4375, -0.1875}, -- NodeBox12
			{0.25, -0.5, -0.5, 0.3125, -0.4375, -0.25}, -- NodeBox13
			{0.3125, -0.5, -0.5, 0.375, -0.4375, -0.3125}, -- NodeBox14
			{0.375, -0.5, -0.5, 0.4375, -0.4375, -0.375}, -- NodeBox15
			{0.4375, -0.5, -0.5, 0.5, -0.4375, -0.4375}, -- NodeBox16
      }
    }
})


minetest.register_node("beanstalk:leaf_stem_join", {
	description = "beanstalk:leaf stem join",
  drawtype = "nodebox",
  tiles = {"beanstalk-leaf-top.png"},
  paramtype = "light",
  paramtype2 = "facedir",
	inventory_image = "beanstalk-leaf-stem-join.png",
	wield_image = "beanstalk-leaf-stem-join.png",
  groups = {snappy=1,choppy=3,flammable=2},
  sounds = default.node_sound_wood_defaults(),
  walkable = true,
  climbable= false,
  is_ground_content = false,
    node_box = {
      type = "fixed",
			fixed={
			{-0.5, -0.5, -0.5, -0.375, -0.4375, -0.4375}, -- NodeBox1
			{-0.5, -0.5, -0.4375, -0.3125, -0.4375, -0.375}, -- NodeBox2
			{-0.5, -0.5, -0.375, -0.1875, -0.4375, -0.3125}, -- NodeBox3
			{-0.0625, -0.5, -0.5, 0.0625, -0.4375, -0.25}, -- NodeBox4
			{0.375, -0.5, -0.5, 0.5, -0.4375, -0.4375}, -- NodeBox5
			{0.3125, -0.5, -0.4375, 0.5, -0.4375, -0.375}, -- NodeBox6
			{0.1875, -0.5, -0.375, 0.5, -0.4375, -0.3125}, -- NodeBox7
			{0.125, -0.5, -0.3125, 0.5, -0.4375, -0.25}, -- NodeBox8
			{-0.5, -0.5, -0.3125, -0.125, -0.4375, -0.25}, -- NodeBox9
			{-0.5, -0.5, -0.25, 0.5, -0.4375, 0.5}, -- NodeBox10
      }
    }
})

minetest.register_node("beanstalk:leaf_stem", {
	description = "beanstalk:leaf stem",
  drawtype = "nodebox",
  tiles = {"beanstalk-leaf-top.png"},
  paramtype = "light",
  paramtype2 = "facedir",
	inventory_image = "beanstalk-leaf-stem.png",
	wield_image = "beanstalk-leaf-stem.png",
  groups = {snappy=1,choppy=3,flammable=2},
  sounds = default.node_sound_wood_defaults(),
  walkable = true,
  climbable= false,
  is_ground_content = false,
    node_box = {
      type = "fixed",
      fixed={-0.0625, -0.5, -0.5, 0.0625, -0.4375, 0.5}, -- NodeBox1
    }
})


--grab content IDs -- You need these to efficiently access and set node data.  get_node() works, but is far slower
local bnst_stalk=minetest.get_content_id("beanstalk:beanstalk")
local bnst_vines=minetest.get_content_id("beanstalk:vine")
local c_air = minetest.get_content_id("air")



--this function checks to see if a node should have vines.
--parms: x,y,z pos of this node, vcx vcz center of this vine, also pass area and data so we can check below
function beanstalk.checkvines(x,y,z, vcx,vcz, area,data)
  local changed=false
  local vn = area:index(x, y, z)  --we get the node we are checking
  local vndown = area:index(x, y-1, z)  --and the node right below the one we are checking
  --if vn is not beanstalk or vines, and vndown is not beanstalk, then we will place a vine
  if data[vn]~=bnst_stalk and data[vn]~=bnst_vines and data[vndown]~=bnst_stalk then
    data[vn]=bnst_vines
    changed=true
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
return changed
end --checkvines


--this is the function that will run EVERY time a chunk is generated.
--see at the bottom of this program where it is registered with:
--minetest.register_on_generated(gen_beanstalk)
--minp is the min point of the chunk, maxp is the max point of the chunk
function beanstalk.gen_beanstalk(minp, maxp, seed)
  --we dont want to waste any time in this function if the chunk doesnt have
  --a beanstalk in it.
  --so first we loop through the levels, if our chunk is not on a level where beanstalks
  --exist, we just do a return   
  local chklv=-1
  local lv=-1
  repeat
    chklv=chklv+1
    if bnst[chklv].bot<=maxp.y and bnst[chklv].top>=minp.y then lv=chklv end
  until chklv==bnst.level_max or lv>-1
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
  until chkb==bnst[lv].max or b>-1
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

  --minetest.log("bnst [beanstalk_gen] BEGIN chunk minp ("..x0..","..y0..","..z0..") maxp ("..x1..","..y1..","..z1..")") --tell people you are generating a chunk


  --This actually initializes the LVM
  local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
  local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
  local data = vm:get_data()

  local changedany=false
  local vinex={ } --initializing the variable so we can use it for an array later
  local vinez={ }
  local rot1radius
  local rot2radius
  local y
  local a1
  local a2
  local cx   --cx=center point x
  local cz   --cz=center point z
  local ylvl

  --y0 is the bottom of the chunk, but if y0<the bottom of the beanstalk, then we
  --will reset y to the bottom of the beanstalk to avoid wasting cpu
  y=y0
  if y<bnst[lv][b].minp.y then
    y=bnst[lv][b].minp.y  --no need to start below the beanstalk
  end

  repeat  --this top repeat is where we loop through the chunk based on y
    --calculate crazy1
    rot1radius=bnst[lv][b].rot1radius
    if bnst[lv][b].crazy1>0 then
      if bnst[lv][b].noise1==nil then
        --couldnt create the noise before mapgen, so doing it now (and only once per beanstalk)
        --I really only need 1d noise.  chulens defines the area of noise generated
        --I am defining the x axis only
        local chulens = {x=bnst[lv].height, y=1, z=1}
        local minposxz = {x=0, y=0}
        np_crazy.seed=bnst[lv][b].seed
        --really might want to change some of the other values based on how big the crazy number is?
        bnst[lv][b].noise1 = minetest.get_perlin_map(np_crazy, chulens):get2dMap_flat(minposxz)
        --now noise1 is an array indexed from 1 to height and
        --with each value in the range from -1 to 1 with fairly smooth changes
      end --if noise==nil
      --so I've got a noise number from -1 to 1, I need to turn it into a radius in the range min to max
      local midrange=(bnst[lv][b].rot1max-bnst[lv][b].rot1min)/2 --middle of our range
      ylvl=y-bnst[lv][b].pos.y+1 --the array goes from 1 up, so we add 1
      rot1radius=math.floor(bnst[lv][b].rot1min+(midrange+(midrange*bnst[lv][b].noise1[ylvl])))
    end --if crazy1>0

    --calculate crazy2
    rot2radius=bnst[lv][b].rot2radius
    if bnst[lv][b].crazy2>0 then
      if bnst[lv][b].noise2==nil then
        --couldnt create the noise before mapgen, so doing it now
        local chulens = {x=bnst[lv].height, y=1, z=1}
        local minposxz = {x=0, y=0}
        np_crazy.seed=bnst[lv][b].seed*2  --times 2 so it will be different than noise1
        bnst[lv][b].noise2 = minetest.get_perlin_map(np_crazy, chulens):get2dMap_flat(minposxz)
        local midrange=(bnst[lv][b].rot2max-bnst[lv][b].rot2min)/2
      end --if noise2==nil
      --so I've got a number from -1 to 1, I need to turn it into a radius in the range min to max
      local midrange=(bnst[lv][b].rot2max-bnst[lv][b].rot2min)/2
      ylvl=y-bnst[lv][b].pos.y+1 --the array goes from 1 up, so we add 1
      rot2radius=math.floor(bnst[lv][b].rot2min+(midrange+(midrange*bnst[lv][b].noise2[ylvl])))
     end --if crazy2>0

     --now, if we had "crazy" we set local rot1radius and rot2radius above.  if we didnt
     --the same locals were set to the beanstalk values.  we use the local values below

    --lets get the beanstalk center based on 2ndary spiral
    a2=(360/bnst[lv][b].rot2yper360)*(y % bnst[lv][b].rot2yper360)*bnst[lv][b].rot2dir
    cx=bnst[lv][b].pos.x+rot2radius*math.cos(a2*math.pi/180)
    cz=bnst[lv][b].pos.z+rot2radius*math.sin(a2*math.pi/180)
    --now cx and cz are the new center of the beanstalk

    local vstr="" --for debuging purposes only
    for v=0, bnst[lv][b].vtot-1 do --calculate centers for each vine
      -- an attempt to explain this rather complicated looking formula:
      -- (360/bnst[lv][b].vtot)*v       gives me starting angle for this vine
      -- +(360/bnst[lv][b].rot1yper360) add the change in angle for each y up
      --   (y-bnst[lv][b].pos.y)        the y pos in this beanstalk
      --                         % bnst[lv][b].rot1yper360)  get mod of yper360, together this gives us how many y up we are (for this section)
      -- *((y-bnst[lv][b].pos.y) % bnst[lv][b].rot1yper360)  multiply change in angle for each y, by how many y up we are in this section
      -- *bnst[lv][b].rot1dir  makes us rotate clockwise or counter clockwise
      a1=(360/bnst[lv][b].vtot)*v+(360/bnst[lv][b].rot1yper360)*((y-bnst[lv][b].pos.y) % bnst[lv][b].rot1yper360)*bnst[lv][b].rot1dir
      --now that we have the rot2 center cx,cz, and the offset angle, we can calculate the center of this vine
      vinex[v]=cx+rot1radius*math.cos(a1*math.pi/180)
      vinez[v]=cz+rot1radius*math.sin(a1*math.pi/180)
      vstr="vinex["..v.."]="..vinex[v].." vinez["..v.."]="..vinez[v] --debug only
    end --for v
    --minetest.log("--- cx="..cx.." cz="..cz.." "..vstr)

    --we are inside the repeat loop that loops through the chunc based on y (from bottom up)
    --these two for loops loop through the chunk based x and z
    --changedthis says if there was a change in the z loop.  changedany says if there was a change in the whole chunk
    for x=x0, x1 do
      for z=z0, z1 do
        local vi = area:index(x, y, z) -- This accesses the node at a given position
        local changedthis=false
        local v=0
        repeat  --loops through the vines until we set the node or run out of vines
          local dist=math.sqrt((x-vinex[v])^2+(z-vinez[v])^2)
          if dist <= bnst[lv][b].vineradius then  --inside stalk
            data[vi]=bnst_stalk
            changedany=true
            changedthis=true
            --minetest.log("--- -- stalk placed at x="..x.." y="..y.." z="..z.." (v="..v..")")
          --this else says to check for adding vines if we are 1 node outside stalk of vine
          elseif dist<=(bnst[lv][b].vineradius+1) then --one node outside stalk
            if beanstalk.checkvines(x,y,z, vinex[v],vinez[v], area,data)==true then
              changedany=true
              changedthis=true
              --minetest.log("--- -- vine placed at x="..x.." y="..y.." z="..z.."(v="..v..")")
            end --changed vines
          end  --if dist
          v=v+1 --next vine
        until v > bnst[lv][b].vtot-1 or changedthis==true
        --add air around the stalk.  (so if we drill through a floating island or another level of land, the beanstalk will have room to climb)
        --not doing this right now, may change my mind later
        --if changedthis==false and (math.sqrt((x-cx)^2+(z-cz)^2) < bnst[lv][b].totradius) and (y > bnst[lv][b].pos.y+30) then
        --  data[v]=c_air
        --  changedany=true
        --end --if changedthis=false
      end --for z
    end --for x
    --minetest.log("bnst: repeat bottom y="..y)
    --minetest.log("bnstb : x0="..x0.." z0="..z0)
    --minetest.log(checkcontent(8573,47,8136,area,data," y="..y))
    --minetest.log(checkcontent(8573,46,8136,area,data," y="..y))

    y=y+1 --next y
  until y>bnst[lv][b].maxp.y or y>y1


  if changedany==true then
    -- Wrap things up and write back to map
    --send data back to voxelmanip
    --minetest.log(checkcontent(8573,47,8136,area,data," before save chunk "..x0..","..y0..","..z0))
    vm:set_data(data)
    --calc lighting
    vm:set_lighting({day=0, night=0})
    vm:calc_lighting()
    --write it to world
    vm:write_to_map(data)
    --minetest.log(">>>saved")
    --minetest.log(checkcontent(8573,47,8136,area,data," after save chunk "..x0..","..y0..","..z0))
  end --if changed write to map

  local chugent = math.ceil((os.clock() - t1) * 1000) --grab how long it took
  minetest.log("bnst["..lv.."]["..b.."] END chunk="..x0..","..y0..","..z0.." - "..x1..","..y1..","..z1.." [beanstalk_gen] "..chugent.." ms") --tell people how long 
end -- beanstalk


--list_beanstalks and go_beanstalk are mainly here for testing
--neither one will probably stay once this is complete
function beanstalk.list_beanstalks(playername)
  local player = minetest.get_player_by_name(playername)
  local lv=0
  local b
  for lv=0,bnst.level_max do  --loop through the levels
    minetest.chat_send_player(playername,"***bnst level="..lv.." ***")
    for b=0,bnst[lv].max do   --loop through the beanstalks
       minetest.chat_send_player(playername, bnst[lv][b].desc.." "..minetest.pos_to_string(bnst[lv][b].pos))
    end --for b
  end --for lv
end --list_beanstalks

function beanstalk.go_beanstalk(playername,param)
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
    player:set_look_yaw(100)
  end --if
end --go_beanstalk

minetest.register_chatcommand("go_beanstalk", {
  params = "<lv> <b>",
  description = "go_beanstalk <lv>,<b>: teleport to beanstalk location",
  func = function (name,param)
    beanstalk.go_beanstalk(name,param)
  end,
})

minetest.register_chatcommand("list_beanstalks", {
  params = "",
  description = "list_beanstalks: list the beanstalk locations",
  func = function (name, param)
    beanstalk.list_beanstalks(name)
  end,
})


--this is what makes us create the beanstalk list
beanstalk.read_beanstalks()

--this is what makes the beanstalk function run every time a chunk is generated
minetest.register_on_generated(beanstalk.gen_beanstalk)


