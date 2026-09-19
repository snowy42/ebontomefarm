-- EbonTomeFarm: original implementation, GPL-3.0-or-later.
-- All mutable collection state is character-scoped. Imported builds are account-scoped.
EbonTomeFarm = { VERSION = "1.0.0", SCHEMA = 1 }
local A = EbonTomeFarm
A.util, A.runtime = {}, { manual = {}, owned = {}, bags = {}, route = {}, skipped = {} }
local U = A.util
function U.trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
function U.clean(s)
    s = tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    s = s:gsub("|H.-|h(.-)|h", "%1"):gsub("|T.-|t", "")
    return s:gsub("[%z\1-\8\11\12\14-\31]", "")
end
function U.name(s)
    s = U.clean(s):gsub("’", "'"):gsub("‘", "'"):gsub("–", "-"):gsub("—", "-")
    s = s:gsub("|%d+$", ""):gsub("%s+%-%s+[Cc]ommon$", ""):gsub("%s+%-%s+[Uu]ncommon$", "")
    s = s:gsub("%s+%-%s+[Rr]are$", ""):gsub("%s+%-%s+[Ee]pic$", ""):gsub("%s+%-%s+[Ll]egendary$", "")
    s = s:gsub("^[Tt]ome of [Ee]cho[%s:]+", ""):gsub("^[Tt]ome of [Ee]choes[%s:]+", "")
    return U.trim(s:gsub("^%[", ""):gsub("%]$", ""):gsub("%s+", " "))
end
function U.key(s) return U.name(s):lower():gsub("[^%w]", "") end
function U.copy(v, seen)
    if type(v) ~= "table" then return v end
    seen = seen or {}; if seen[v] then return seen[v] end
    local n = {}; seen[v] = n; for k,x in pairs(v) do n[k] = U.copy(x, seen) end; return n
end
function U.sortedKeys(t)
    local r = {}; for k in pairs(t or {}) do r[#r+1] = k end
    table.sort(r, function(a,b) return tostring(a)<tostring(b) end); return r
end
function U.clamp(v,lo,hi) return math.max(lo, math.min(hi,v)) end
function A:Print(s)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffd6b36aEbonTomeFarm|r: " .. tostring(s)) end
end
function A:InitStorage()
    if type(EbonTomeFarmDB) ~= "table" then EbonTomeFarmDB = {} end
    if type(EbonTomeFarmCharDB) ~= "table" then EbonTomeFarmCharDB = {} end
    self.db, self.char = EbonTomeFarmDB, EbonTomeFarmCharDB
    self.db.schema = self.SCHEMA; self.db.builds = self.db.builds or {}
    self.db.nextID = tonumber(self.db.nextID) or 1
    self.char.manual = self.char.manual or {}; self.char.locations = self.char.locations or {}
    self.char.settings = self.char.settings or {}
    local defaults = { show = true, locked = false, hideDone = true, raids = true, dungeons = true,
        tomtom = true, autoAdvance = true, scale = 1, width = 354, height = 500,
        minimumTier = "C", minimap = true }
    for k,v in pairs(defaults) do if self.char.settings[k] == nil then self.char.settings[k] = v end end
    self.char.settings.scale = U.clamp(tonumber(self.char.settings.scale) or 1, .7, 1.6)
    self.runtime.manual = self.char.manual
end
function A:GetBuild()
    for _,b in ipairs(self.db and self.db.builds or {}) do if b.id == self.char.activeBuild then return b end end
end
function A:SaveBuild(build)
    if not build or type(build.targets) ~= "table" or #build.targets == 0 then return nil, "The import contains no wanted echoes." end
    if #self.db.builds >= 30 then return nil, "30 saved builds reached. Delete an unused build first." end
    local b = U.copy(build); b.id = self.db.nextID; self.db.nextID = self.db.nextID+1
    self.db.builds[#self.db.builds+1] = b; self.char.activeBuild = b.id
    self.runtime.skipped = {}; self.runtime.active = nil; self.runtime.selected = nil
    self:Refresh(); return b
end
function A:SelectBuild(id)
    self.char.activeBuild = id; self.runtime.skipped = {}; self.runtime.active = nil
    self.runtime.selected = nil; self:Refresh()
end
function A:DeleteBuild(id)
    for i,b in ipairs(self.db.builds) do if b.id == id then table.remove(self.db.builds,i); break end end
    if self.char.activeBuild == id then self.char.activeBuild = self.db.builds[1] and self.db.builds[1].id end
    self.runtime.active = nil; self:Refresh()
end
function A:Status(target)
    local key = target.key
    if self.char.manual[key] == "done" then return "manual", "Marked collected" end
    if self.char.manual[key] == "need" then return "needed", "Manually marked needed" end
    if self.runtime.owned[key] then return "learned", "Permanently unlocked" end
    if self.runtime.bags[key] then return "bag", "In bags - use the tome" end
    if target.innate then return "innate", "No tome required" end
    if not target.tomeID then return "unknown", "No matching tome in the bundled data" end
    return "needed", "Not yet collected"
end
function A:IsDone(target)
    local s = self:Status(target); return s == "manual" or s == "learned" or s == "bag" or s == "innate"
end
function A:SetManual(key, state)
    if state ~= "done" and state ~= "need" then state = nil end
    self.char.manual[key] = state; self:Refresh()
end
function A:Refresh()
    if not self.db then return end
    if self.IndexTargets then self:IndexTargets() end
    if self.RebuildRoute then self:RebuildRoute() end
    if self.Render then self:Render() end
end
