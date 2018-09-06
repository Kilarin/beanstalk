--beanstalk

beanstalk = { } --will be used to hold functions.
--putting the functions into a lua table like this is, I believe, generally considered good form
--because it makes it easy for any other mod to access them if needed

--this runs nodes.lua, I put all the node definitions in there in instead of in init.lua
--it helps to keep the code cleaner and more organized.  I run nodes.lua near the top of init.lua
--because we use those node definitions in some of the code below
dofile(minetest.get_modpath("beanstalk").."/nodes.lua")

--These are the constants that need to be modified based on your game needs
--we store all the important variables in a single table, bnst, this makes it easy to
--write to a file and read from a file
local bnst={["level_max"]=0}   --(counting up from 0, what is the highest "level" of beanstalks?)

--define by level  (each beanstalk level must have these values defined.  might add "weirdness" and specialized nodes?)
bnst[0]={"count","bot","height","per_row","area","top","max" }
bnst[0].count=16
bnst[0].bot=-10
bnst[0].height=6000
--once you create a beanstalk file, these values will be ignored! They only make a difference the FIRST time this
--code runs when the first beanstalk file is created.  I might need to change that in the future


--this is the perlin noise that will be used for "crazy" beanstalks
--I don't really understand how these parms work, but this link has
--a nice attempt at explaining: https://forum.minetest.net/viewtopic.php?f=47&t=13278#p194281
local np_crazy =
  {
   offset = 0,
   scale = 1,
   spread = {x=15, y=8, z=8},
   seed = 0, --this will be overriden
   octaves = 1,
   persist = 0.67
   }
--since I'm using this perlin noise one dimensionally, I would have assumed a spread of
--{x=15, y=1, z=1} would have been right, but that reduces the variation too much.
--I really do NOT understand perlin noise well enough.


-- ----- below here you shouldnt need to customize -----

--grab content IDs -- You need these to efficiently access and set node data.  get_node() works, but is far slower
local bnst_stalk=minetest.get_content_id("beanstalk:beanstalk")
local bnst_vines=minetest.get_content_id("beanstalk:vine")
local c_air = minetest.get_content_id("air")


--this function calculates (very approximately) the circumference of a circle of radius r in voxels
--this could be made much more accurate
--this function has to be way up here because it has to be defined before it is used
--********************************
function beanstalk.voxel_circum(r)
  if r==1 then return 4
  elseif r==2 then return 8
  else return 2*math.pi*r*0.88 --not perfect, but a pretty good estimate
  end --if
end --voxel_circum

--this function generates the calculated constants that apply to each beanstalk level.
--we do not store these values in the beanstalk file because if the user changes any of the
--basic values (such as count) in the beanstalk file, we want all of THESE values to be recalculated
--correctly after the beanstalk file is read.
--this function is run TWICE in create_beanstalks.  That is because it has to be run
--BEFORE create_beanstalks, in order to set up the constants used in that function.  But
--create_beanstalks also runs write_beanstalks, which wipes these values out (because we dont want to write
--them to the beanstalk file) so it is run again after the call to write_beanstalks to reset the values again
--when reading from the beanstalk file this function only runs once
--********************************
function beanstalk.calculated_constants_bylevel()
  --calculated constants by level
  minetest.log("beanstalk-> calculated constants by level")
  for lv=0,bnst.level_max do
    bnst[lv].per_row=math.floor(math.sqrt(bnst[lv].count))  --beanstalks per row are the sqrt of beanstalks per level
    bnst[lv].count=bnst[lv].per_row*bnst[lv].per_row  --recalculate to a perfect square
    bnst[lv].max=bnst[lv].count-1  --for use in array
    bnst[lv].area=62000/bnst[lv].per_row
    bnst[lv].top=bnst[lv].bot+bnst[lv].height-1
  end --for
end --calculated_constants_bylevel


--this function generates the calculated constants that apply to each beanstalk.  We dont
--store these in the beanstalk file because if the user changes any of those values in the file
--(such as the beanstalk position) we need these constants to be recalculated correctly
--this function has to run after you create_beanstalks or read_beanstalks
--this function displays the beanstalk list in debug.txt
--********************************
function beanstalk.calculated_constants_bybnst()
  --calculated constants by beanstalk
  minetest.log("beanstalk-> calculated constants by beanstalk")
  minetest.log("beanstalk-> list --------------------------------------")
  for lv=0,bnst.level_max do  --loop through the levels
    minetest.log("***beanstalk-> level="..lv.." ***")
    for b=0,bnst[lv].max do   --loop through the beanstalks
      bnst[lv][b].rot1min=bnst[lv][b].rot1radius --default if we dont set crazy
      bnst[lv][b].rot1max=bnst[lv][b].rot1radius --default if we dont set crazy
      bnst[lv][b].rot2min=bnst[lv][b].rot2radius --default if we dont set crazy
      bnst[lv][b].rot2max=bnst[lv][b].rot2radius --default if we dont set crazy

      if bnst[lv][b].crazy1>0 then
        --determine the min and max we will move the rot1radius through
        bnst[lv][b].rot1max=bnst[lv][b].rot1radius+bnst[lv][b].crazy1
        bnst[lv][b].rot1min=bnst[lv][b].rot1radius-bnst[lv][b].crazy1
        if bnst[lv][b].rot1min<bnst[lv][b].vineradius then --we dont want min to be too small
          --below line says add what we take off the min to the max
          bnst[lv][b].rot1max=bnst[lv][b].rot1max+(bnst[lv][b].vineradius-bnst[lv][b].rot1min)
          bnst[lv][b].rot1min=bnst[lv][b].vineradius
        end --if rot1min<vineradius
      end --if crazy1>0
      bnst[lv][b].noise1=nil
      --now, right here would be a GREAT place to create and store the perlin noise.
      --BUT, you cant do that at this point, because the map isn't generated.  and for some odd reason,
      --the perlin noise function exits as nil if you use it before map generation.  so we will do it
      --in the generation loop
      --perlin noise is random, but SMOOTH, so it makes interesting looking vine changes.
      --we need to play with the perlin noise values and see if we can get results we like better

      if bnst[lv][b].crazy2>0 then
        --determine the min and max we will move the rot2radius through
        bnst[lv][b].rot2max=bnst[lv][b].rot2radius+bnst[lv][b].crazy2
        bnst[lv][b].rot2min=bnst[lv][b].rot2radius-bnst[lv][b].crazy2
        if bnst[lv][b].rot2min<0 then --we dont want min to be too small
          --below line says add what we take off the min to the max
          bnst[lv][b].rot2max=bnst[lv][b].rot2max+math.abs(bnst[lv][b].rot2min)
          bnst[lv][b].rot2min=0
        end --if rot2min<0
      end --if crazy2>0
      bnst[lv][b].noise2=nil

      -- total radius = rot1radius (radius vines circle around) + vine radius + 2 more for a space around the beanstalk (will be air)
      -- so this is the total radius around the current center
      bnst[lv][b].totradius=bnst[lv][b].rot1max+bnst[lv][b].vineradius+2
      -- but totradius can not be used for determining min and maxp, because the current center moves! for that we need
      -- full radius = max diameter of entire beanstalk including outer spiral (rot2radius)
      bnst[lv][b].fullradius=bnst[lv][b].totradius+bnst[lv][b].rot2max
      bnst[lv][b].minp={x=bnst[lv][b].pos.x-bnst[lv][b].fullradius, y=bnst[lv][b].pos.y, z=bnst[lv][b].pos.z-bnst[lv][b].fullradius}
      bnst[lv][b].maxp={x=bnst[lv][b].pos.x+bnst[lv][b].fullradius, y=bnst[lv].top, z=bnst[lv][b].pos.z+bnst[lv][b].fullradius}

      --display it
      local logstr="bnst["..lv.."]["..b.."] "..minetest.pos_to_string(bnst[lv][b].pos).." vtot="..bnst[lv][b].vtot
      logstr=logstr.." vrad="..bnst[lv][b].vineradius.." rot1rad="..bnst[lv][b].rot1radius
      logstr=logstr.." rot1dir="..bnst[lv][b].rot1dir.." rot1yper="..bnst[lv][b].rot1yper360
      logstr=logstr.." rot2rad="..bnst[lv][b].rot2radius.." rot2yper="..bnst[lv][b].rot2yper360.." rot2dir="..bnst[lv][b].rot2dir
      logstr=logstr.." crazy1="..bnst[lv][b].crazy1.." crazy2="..bnst[lv][b].crazy2
      bnst[lv][b].desc=logstr
      minetest.log(logstr)
    end --for b
  end --for lv
  minetest.log("beanstalk-> list --------------------------------------")
end --calculated_constants_bybnst


--saves the bnst list in minetest/words/<worldname>/beanstalks
--we could just recalculate the beanstalks from scratch each time, but writing them to a file
--gives the server admin the option of moving a beanstalk closer to spawn or further away
--or letting them play with the numbers if they want.  It also means that updates that
--change the way beanstalks are generated should not cause an existing games beanstalks
--to change positions or anything else disruptive like that.
--********************************
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



--this is the function that randomly generates the beanstalks based on the map seed, level,
--and beanstalk.  It should usually only run once per game
--then the results are written to the beanstalk file.  But if you deleted the beanstalk
--file so this would run again, you should get identical results.
--********************************
function beanstalk.create_beanstalks()
  minetest.log("beanstalk-> create beanstalks")
  local logstr
  local lv=0

  --we need these values calculated before we do some of the things below:
  beanstalk.calculated_constants_bylevel()

  --get_mapgen_params is deprecated; use get_mapgen_setting
  local mapseed = minetest.get_mapgen_setting("seed") --this is how we get the mapgen seed
  --lua numbers are double-precision floating-point which can only handle numbers up to 100,000,000,000,000
  --but the seed we got back is 20 characters!  We dont really need that much randomness anyway, so we are
  --going to just take the first 14 chars, and turn it into a number, so we can do multiplication and addition to it
  mapseed=tonumber(string.sub(mapseed,1,14))

  for lv=0,bnst.level_max do  --loop through the levels
    for b=0,bnst[lv].max do   --loop through the beanstalks
      bnst[lv][b]={ }
      bnst[lv][b].seed=mapseed+lv*10000+b  --this gives us a unique seed for each beanstalk
      math.randomseed(bnst[lv][b].seed)
      --important note: since we have seeded the random function with our beanstalks seed here,
      --all of the random numbers it generates will be the exact SAME numbers if this function is run again.

      --note that our random position is always at least 500 from the border, so that beanstalks can NEVER be right next to each other
      bnst[lv][b].pos={ }
      bnst[lv][b].pos.x=-31000 + (bnst[lv].area * (b % bnst[lv].per_row) + 500+math.random(0,bnst[lv].area-1000) )
      bnst[lv][b].pos.y=bnst[lv].bot
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
      --and vine radius +1 looks better in my opinion
      if bnst[lv][b].rot1radius<bnst[lv][b].vineradius then bnst[lv][b].rot1radius=bnst[lv][b].vineradius+1
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
      --crazy gives us a number from 0 to 6 (may expand that in the future, and we manipulate it below)
      --the biger the number, the bigger the range of change in the crazy vine rot1radius value
      --note that this is the number we change each way, so crazy=3 means from radius-3 to radius+3
      --and crazy=6 is a whopping TWELVE change in radius, that should be VERY noticible
      --in calculated_constants_bybnst we use crazy1 to set rot1min and rot1max
       bnst[lv][b].crazy1=math.random(1,12)-6
      if bnst[lv][b].crazy1<0 then bnst[lv][b].crazy1=0 end
      if bnst[lv][b].crazy1>0 then
        --very low values for crazy are just not visible enough of an effect, so we increase so min is 3
        bnst[lv][b].crazy1=bnst[lv][b].crazy1+2
      end --if crazy1>0

      --crazy2 like crazy1, but this is for the outer spiral
      --in calculated_constants_bybnst we use crazy2 to set rot2min and rot2max
      bnst[lv][b].crazy2=math.random(1,12)-6
      if bnst[lv][b].crazy2<0 then bnst[lv][b].crazy2=0 end
      if bnst[lv][b].crazy2>0 then
        --small cazy values for crazy2 just don't have a big enough effect, so we multiply by 2
        bnst[lv][b].crazy2=(bnst[lv][b].crazy2*2)+math.random(3,5) -- now we have 5 to 17
      end --if crazy2>0
    end --for b
  end --for lv

  --now that we have created all the values, we need to write them to the file.
  --in the future, create_beanstalks will not be run again, instead, values will be read from the beanstalk file.
  beanstalk.write_beanstalks()
  --but that wiped out some of our calculated constants bylevel, so lets redo them
  beanstalk.calculated_constants_bylevel()
  --and also get the beanstalk level calculated constants
  beanstalk.calculated_constants_bybnst()
end --create_beanstalks



--get beanstalks, from file if exists, otherwise generate
--********************************
function beanstalk.read_beanstalks()
  minetest.log("beanstalk-> reading beanstalks file")
  local file = io.open(minetest.get_worldpath().."/beanstalks", "r")
  if file then
    bnst = minetest.deserialize(file:read("*all"))
    -- check if it was an empty file because empty files can crash server
    if bnst == nil then
      minetest.log("beanstalk-> ERROR: beanstalk file exists but is empty, will recreate")
      beanstalk.create_beanstalks()
    else  --file exists and was loaded
      beanstalk.calculated_constants_bylevel()
      beanstalk.calculated_constants_bybnst()
    end  --if bnst==nil
    file:close()
  else --file does not exist
    minetest.log("beanstalk-> beanstalk file does not exist, creating it")
    beanstalk.create_beanstalks()
  end --if file
end --read_beanstalks



--this function checks to see if a node should have vines.  it is only called for positions
--that are vine radius +1.  The rules for adding a vine are pretty simple:
--if this location is not itself a vine or beanstalk, AND, the position directly below
--this position IS a beanstalk, then we add a vine.  That way vines appear on vertical
--surfaces, but not where you have nice climbable stair steps.
--parms: x,y,z pos of this node, vcx vcz center of this vine, also pass area and data so we can check below
--********************************
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
--********************************
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

    --lets get the beanstalk center based on secondary spiral
    a2=(360/bnst[lv][b].rot2yper360)*(y % bnst[lv][b].rot2yper360)*bnst[lv][b].rot2dir
    cx=bnst[lv][b].pos.x+rot2radius*math.cos(a2*math.pi/180)
    cz=bnst[lv][b].pos.z+rot2radius*math.sin(a2*math.pi/180)
    --now cx and cz are the new center of the beanstalk

    for v=0, bnst[lv][b].vtot-1 do --calculate centers for each vine
      -- an attempt to explain this rather complicated looking formula:
      -- (360/bnst[lv][b].vtot)*v       gives me starting angle for this vine
      -- +(360/bnst[lv][b].rot1yper360) the change in angle for each y up
      --   (y-bnst[lv][b].pos.y)        the y pos in this beanstalk
      --                         % bnst[lv][b].rot1yper360)  get mod of yper360, together this gives us how many y up we are (for this section)
      -- *((y-bnst[lv][b].pos.y) % bnst[lv][b].rot1yper360)  multiply change in angle for each y, by how many y up we are in this section
      -- *bnst[lv][b].rot1dir  makes us rotate clockwise or counter clockwise
      a1=(360/bnst[lv][b].vtot)*v+(360/bnst[lv][b].rot1yper360)*((y-bnst[lv][b].pos.y) % bnst[lv][b].rot1yper360)*bnst[lv][b].rot1dir
      --now that we have the rot2 center cx,cz, and the offset angle, we can calculate the center of this vine
      vinex[v]=cx+rot1radius*math.cos(a1*math.pi/180)
      vinez[v]=cz+rot1radius*math.sin(a1*math.pi/180)
    end --for v

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
          --this else says to check for adding climbing vines if we are 1 node outside stalk of a beanstalk vine
          --(it is confusing that I call them both vine.  I should have called it stalks and vines)
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


--list_beanstalks is mainly here for testing.  It may be removed (or at least restricted)
--once this mod is complete
--********************************
function beanstalk.list_beanstalks(playername)
  local player = minetest.get_player_by_name(playername)
  local lv=0
  local b
  for lv=0,bnst.level_max do  --loop through the levels
    minetest.chat_send_player(playername,"***bnst level="..lv.." ***")
    for b=0,bnst[lv].max do   --loop through the beanstalks
       minetest.chat_send_player(playername, bnst[lv][b].desc)
    end --for b
  end --for lv
end --list_beanstalks


--teleports you to a specific beanstalk, this is mainly here for testing
--and will probably be removed (or at least restricted) once this mod is complete
--********************************
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
    --player:set_look_yaw(100)  this is depricated, but set_look_horizontal uses radians
    player:set_look_horizontal(1.75)
  end --if
end --go_beanstalk


--note that the below stuff is NOT in a function and will run at the start of every game

--register the list_beanstalk chat command
minetest.register_chatcommand("list_beanstalks", {
  params = "",
  description = "list_beanstalks: list the beanstalk locations",
  func = function (name, param)
    beanstalk.list_beanstalks(name)
  end,
})

--register the go_beanstalk chat command
minetest.register_chatcommand("go_beanstalk", {
  params = "<lv> <b>",
  description = "go_beanstalk <lv>,<b>: teleport to beanstalk location",
  func = function (name,param)
    beanstalk.go_beanstalk(name,param)
  end,
})


--this is what makes us create the beanstalk list
beanstalk.read_beanstalks()

--this is what makes the beanstalk function run every time a chunk is generated
minetest.register_on_generated(beanstalk.gen_beanstalk)


