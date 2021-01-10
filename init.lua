--[[
Description: A mod to store/retrieve locations aka. a location bookmark manager.
Feature: This tool is purely command line  (chat command) based, and will be actively maintained by Charles Zhang.
Author: Charles Zhang
]]

-- Keep a reference to the storage during mod load time
local storage = minetest.get_mod_storage()

local function PrintHelp()
  print([[
/lc: print this help message;
/lc all: print all named locations;
/lc add <name> (<description>): add/update a new named location;
/lc get <name>: get information (including coordinates and description if any) of a named location;
/lc goto <name>: teleport caller to the named location;
/lc teleport <player> <name>: teleport a player to a named location;
/lc delete <name>: delete a named location.
]])
end

local function FormatBookmark(bookmark)
  return bookmark.name.." ".."("..bookmark.location.x..", "..bookmark.location.y..", "..bookmark.location.z..") "..bookmark.description
end

local function PrintAllLocations()
  local fields = storage:to_table().fields
  -- Enumerate
  for k,v in pairs(fields) do
    print(FormatBookmark(minetest.deserialize(v)))
  end
end

local function round(num)
  return math.floor(num+0.5)
end

local function UpdateLocation(pos, name, desc)
  local bookmark = {name=name, location={x=round(pos.x),y=round(pos.y),z=round(pos.z)}, description=desc}
  local serialization = minetest.serialize(bookmark)
  storage:set_string(name, serialization)
  print(FormatBookmark(bookmark))
end

local function PrintLocation(name)
  local serialization = storage:get_string(name)
  if serialization and serialization ~='' then
    local bookmark = minetest.deserialize(serialization)
    print(FormatBookmark(bookmark))
  else
    print("Location "..name.." doesn't exist.")
  end
end

local function TeleportToLocation(playerName, locationName)
  local serialization = storage:get_string(locationName)
  if serialization and serialization ~= '' then
    local bookmark = minetest.deserialize(serialization)
    minetest.get_player_by_name(playerName):set_pos(bookmark.location)
  else
    print("Location "..locationName.." doesn't exist.")
  end
end

local function DeleteLocation(locationName)
  --[[Since there is no function like remove_string(), and using 
  set_string(key, nil) is not clean, we need to reconstruct the whole thing.]]
  
  -- Nil target
  storage:set_string(locationName, nil)
  -- Get a copy of existing bookmarks
  local fields = storage:to_table().fields
  -- Clear current table
  storage:from_table(nil)
  -- Reconstruct table
  for k,v in pairs(fields) do
    storage:set_string(k, v)
  end
end

minetest.register_chatcommand("lc", {
    description = "Location bookmark management utility.",
    privs = {server = true},
    func = function(playerName, params)
      -- Handle missing parameter: output help
      if params == nil or params:len() == 0 then
        PrintHelp()
      elseif params == "all" then
        PrintAllLocations()
      elseif params:sub(0,3) == "add" and params:len() > 4 then
        -- Get player location
        local pos = minetest.get_player_by_name(playerName):get_pos()
        -- Parse parameters
        local _,_,locationName,description = params:find("^add (%S+)%s*\"?([^\"]*)\"?$")
        -- Update location
        UpdateLocation(pos, locationName, description)
      elseif params:sub(0,3) == "get" and params:len() > 4 then
        -- Parse parameter
        local _,_,locationName = params:find("^get (%S+)%s*$")
        -- Try find and print location
        PrintLocation(locationName)
      elseif params:sub(0,4) == "goto" and params:len() > 5 then
        -- Parse parameter
        local _,_,locationName = params:find("^goto (%S+)%s*$")
        -- Try find and goto location
        TeleportToLocation(playerName, locationName)
      elseif params:sub(0,8) == "teleport" and params:len() > 9 then
        -- Parse parameters
        local _,_,otherPlayerName, locationName = params:find("^teleport (%S+)%s*(%S*)$")
        TeleportToLocation(otherPlayerName, locationName)
      elseif params:sub(0,6) == "delete" and params:len() > 7 then
        -- Parse parameters
        local _,_,locationName = params:find("^delete (%S+)%s*$")
        -- Try find and delete location
        DeleteLocation(locationName)
      end
    end
})