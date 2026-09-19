-- Bounded, non-executing parsers. Imported text is never treated as Lua.
local A = EbonTomeFarm
A.Codec = {}; local C = A.Codec
local LIMIT, DEPTH = 524288, 40
local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local reverse = {}; for i=1,#alphabet do reverse[alphabet:sub(i,i)] = i-1 end
function C.Base64Decode(text)
    if type(text) ~= "string" or #text > LIMIT then return nil, "Export is too large (512 KiB maximum)." end
    text = text:gsub("%s", ""):gsub("-", "+"):gsub("_", "/")
    if text == "" or text:find("[^A-Za-z0-9+/=]") then return nil, "Not a valid Base64 export." end
    local first = text:find("=", 1, true)
    if first and (text:sub(first):find("[^=]") or #text-first+1>2 or #text%4~=0) then return nil, "Invalid Base64 padding." end
    if #text%4 == 1 then return nil, "The export appears truncated." end
    if not first then text = text .. string.rep("=", (4-#text%4)%4) end
    local out = {}
    for i=1,#text,4 do
        local a,b,c,d = text:sub(i,i),text:sub(i+1,i+1),text:sub(i+2,i+2),text:sub(i+3,i+3)
        if not reverse[a] or not reverse[b] then return nil, "Invalid Base64 group." end
        local cv, dv = reverse[c] or 0, reverse[d] or 0
        if (c=="=" and (d~="=" or reverse[b]%16~=0)) or (d=="=" and c~="=" and cv%4~=0) then return nil, "Invalid Base64 final group." end
        local n = reverse[a]*262144 + reverse[b]*4096 + cv*64 + dv
        out[#out+1] = string.char(math.floor(n/65536))
        if c~="=" then out[#out+1]=string.char(math.floor(n/256)%256) end
        if d~="=" then out[#out+1]=string.char(n%256) end
    end
    return table.concat(out)
end
function C.Base64Encode(s)
    local out = {}
    for i=1,#s,3 do
        local a,b,c=s:byte(i,i+2); local n=a*65536+(b or 0)*256+(c or 0)
        out[#out+1]=alphabet:sub(math.floor(n/262144)+1,math.floor(n/262144)+1)
        out[#out+1]=alphabet:sub(math.floor(n/4096)%64+1,math.floor(n/4096)%64+1)
        out[#out+1]=b and alphabet:sub(math.floor(n/64)%64+1,math.floor(n/64)%64+1) or "="
        out[#out+1]=c and alphabet:sub(n%64+1,n%64+1) or "="
    end
    return table.concat(out)
end
local function utf8(n)
    if n<128 then return string.char(n) end
    if n<2048 then return string.char(192+math.floor(n/64),128+n%64) end
    if n<65536 then return string.char(224+math.floor(n/4096),128+math.floor(n/64)%64,128+n%64) end
    return string.char(240+math.floor(n/262144),128+math.floor(n/4096)%64,128+math.floor(n/64)%64,128+n%64)
end
function C.JSONDecode(text)
    if type(text)~="string" or #text>LIMIT then return nil,"JSON exceeds the 512 KiB limit." end
    local p,n,nodes=1,#text,0; local null={}; C.NULL=null
    local function fail(msg) error(msg .. " at byte " .. p,0) end
    local function ws() while p<=n and text:sub(p,p):match("%s") do p=p+1 end end
    local function hex4()
        local s=text:sub(p,p+3); if #s~=4 or s:find("[^%x]") then fail("Invalid Unicode escape") end
        p=p+4; return tonumber(s,16)
    end
    local function str()
        p=p+1; local out={}; local start=p
        while p<=n do
            local c=text:byte(p)
            if c==34 then out[#out+1]=text:sub(start,p-1);p=p+1;return table.concat(out) end
            if c<32 then fail("Control character inside JSON string") end
            if c==92 then
                out[#out+1]=text:sub(start,p-1); p=p+1
                local esc=text:sub(p,p); p=p+1
                local simple={['"']='"',["\\"]="\\",["/"]="/",b="\b",f="\f",n="\n",r="\r",t="\t"}
                if simple[esc] then out[#out+1]=simple[esc]
                elseif esc=="u" then
                    local cp=hex4()
                    if cp>=55296 and cp<=56319 then
                        if text:sub(p,p+1)~="\\u" then fail("Missing Unicode low surrogate") end
                        p=p+2;local low=hex4();if low<56320 or low>57343 then fail("Invalid Unicode low surrogate") end
                        cp=65536+(cp-55296)*1024+(low-56320)
                    elseif cp>=56320 and cp<=57343 then fail("Unexpected Unicode low surrogate") end
                    out[#out+1]=utf8(cp)
                else fail("Unknown JSON escape") end
                start=p
            else p=p+1 end
        end
        fail("Unterminated JSON string")
    end
    local value
    value=function(depth)
        if depth>DEPTH then fail("JSON nesting limit reached") end
        nodes=nodes+1;if nodes>30000 then fail("JSON value limit reached") end
        ws(); local c=text:sub(p,p)
        if c=='"' then return str() end
        if c=="{" or c=="[" then
            local obj=c=="{";local close=obj and "}" or "]";local t={};p=p+1;ws()
            if text:sub(p,p)==close then p=p+1;return t end
            local i=1
            while p<=n do
                ws();local key=i
                if obj then
                    if text:sub(p,p)~='"' then fail("Expected an object key") end
                    key=str();ws();if text:sub(p,p)~=":" then fail("Expected ':'") end;p=p+1
                    if t[key]~=nil then fail("Duplicate JSON object key") end
                end
                t[key]=value(depth+1);i=i+1;ws();local sep=text:sub(p,p);p=p+1
                if sep==close then return t end
                if sep~="," then fail("Expected ',' or closing bracket") end
            end
            fail("Unterminated JSON container")
        end
        for _,lit in ipairs({"true","false","null"}) do
            if text:sub(p,p+#lit-1)==lit then p=p+#lit;if lit=="null" then return null else return lit=="true" end end
        end
        local start=p
        if c=="-" then p=p+1 end
        if text:sub(p,p)=="0" then p=p+1
        elseif text:sub(p,p):match("[1-9]") then repeat p=p+1 until not text:sub(p,p):match("%d")
        else fail("Expected a JSON value") end
        if text:sub(p,p)=="." then p=p+1;if not text:sub(p,p):match("%d") then fail("Invalid decimal") end;repeat p=p+1 until not text:sub(p,p):match("%d") end
        if text:sub(p,p):match("[eE]") and p<=n then
            p=p+1;if text:sub(p,p):match("[+-]") then p=p+1 end
            if not text:sub(p,p):match("%d") then fail("Invalid exponent") end;repeat p=p+1 until not text:sub(p,p):match("%d")
        end
        local num=tonumber(text:sub(start,p-1));if not num or num==math.huge or num==-math.huge then fail("Invalid number") end;return num
    end
    local ok,result=pcall(function() local v=value(1);ws();if p<=n then fail("Trailing JSON content") end;return v end)
    if not ok then return nil,result end
    return result
end
