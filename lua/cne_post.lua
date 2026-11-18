-- Cause And Effect HUD: reads the cne_* dvars written by zm_cne.gsc.
--   cne_hud  current combo (top left)
--   cne_c / cne_e / cne_ca  rolling cause and effect (top center), shown while cne_ca is 1
--   cne_os 1 = options screen, cne_view = cursor*8 + effects stack + illegal*2 + no repeat*4
local C=rawget(_G,"CLUA")
local H=rawget(_G,"xhash") or rawget(_G,"PushXHash") or (type(C)=="table" and C.PushXHash)
local HD=rawget(_G,"xhashdvar") or rawget(_G,"PushXHashDvar") or (type(C)=="table" and C.PushXHashDvar)
if type(H)~="function" or type(HD)~="function" then return end
local hcache,hdcache={},{}
local function h(n) local v=hcache[n];if v==nil then v=H(n);hcache[n]=v end;return v end
local function hd(n) local v=hdcache[n];if v==nil then v=HD(n);hdcache[n]=v end;return v end

local old=rawget(_G,"CneView")
if old then old.enabled=false;if old.clear then pcall(old.clear) end end
local S={enabled=true,cache={}}
rawset(_G,"CneView",S)

local WHITE,YELLOW,GREY=0xffffff,0xffd700,0xb4b4b4
local CHARW=0.5   -- average letter width (x font size), used to right-align the cause

local function get(object,key)
    if object==nil then return nil end
    local plain,value=pcall(function()return object[key]end)
    if plain and value~=nil then return value end
    local ok,hashed=pcall(function()return object[h(key)]end)
    if ok then return hashed end
end
local function invoke(object,key,...) local f=get(object,key);if type(f)=="function" then return f(...) end end
local function call(object,key,...) local f=get(object,key);if type(f)=="function" then return f(object,...) end end
local function read(name)
    local value=invoke(rawget(_G,"Dvar"),"GetDvarString",hd(name))
    if value~=nil then return tostring(value) end
    return ""
end
local function inMatch() return invoke(rawget(_G,"Engine"),"InFrontend")==false end
local function newElement(kind)
    local f=get(get(rawget(_G,"LUI"),kind),"new")
    if type(f)~="function" then error("Native "..kind.." constructor unavailable",0) end
    return f()
end
local function passive(e) call(e,"SetHandleMouse",false);call(e,"setFocusable",false) end
local function place(e,x,y,w,hh) call(e,"SetAnchorsAndPosition",0,1,0,1,x,x+w,y,y+hh) end

-- text with a black shadow copy behind it
local function label(parent,x,y,w,hh,size)
    local fonts=rawget(_G,"FONT_HANDLE")
    local font=get(fonts,"PrimaryBold") or get(fonts,"PrimaryRegular")
    local pair={}
    for i,rgb in ipairs({0x000000,WHITE}) do
        local e=newElement("UIStyledText")
        local o=(i==1) and 1.5 or 0
        place(e,x+o,y+o,w,hh)
        if font then call(e,"SetFont",font) end
        call(e,"SetFontSize",size*(tonumber(rawget(_G,"_PT")) or 1))
        call(e,"SetRGB",rgb);call(e,"SetAlignment",0)
        passive(e);call(parent,"addElement",e)
        pair[i]=e
    end
    return {shadow=pair[1],text=pair[2],x=x,y=y,w=w,h=hh,size=size}
end
local function setLabel(l,text,rgb,alpha)
    local c=S.cache[l] or {};S.cache[l]=c
    if c.text~=text then call(l.text,"setText",text);call(l.shadow,"setText",text);c.text=text end
    if rgb and c.rgb~=rgb then call(l.text,"SetRGB",rgb);c.rgb=rgb end
    alpha=alpha or 1
    if c.alpha~=alpha then call(l.text,"SetAlpha",alpha);call(l.shadow,"SetAlpha",alpha);c.alpha=alpha end
end
-- right edge of the text stays at l.x + l.w
local function setRight(l,text,alpha)
    local width=math.min(l.w,#text*l.size*CHARW)
    local x=l.x+l.w-width
    local c=S.cache[l] or {};S.cache[l]=c
    if c.rx~=x then place(l.text,x,l.y,width+20,l.h);place(l.shadow,x+1.5,l.y+1.5,width+20,l.h);c.rx=x end
    setLabel(l,text,WHITE,alpha)
end

local function displayParent()
    local root=invoke(get(rawget(_G,"LUI"),"UIRoot"),"GetRootForControllerIndex",0)
    if type(get(root,"addElement"))~="function" then return nil end
    for _=1,16 do
        local p=call(root,"getParent")
        if not p or p==root then break end
        root=p
    end
    return root
end

local function clear()
    if S.frame then pcall(call,S.frame,"closeTree") end
    if S.left then pcall(call,S.left,"closeTree") end
    S.frame=nil;S.left=nil;S.parent=nil;S.cache={}
end

local function build(parent)
    clear()
    -- top left: current combo
    local left=newElement("UIElement")
    passive(left);call(parent,"addElement",left);call(left,"setPriority",1000)
    call(left,"SetAnchorsAndPosition",0,1,0,1,10,1210,15,115)
    S.hud=label(left,0,0,1200,26,22)
    -- top center: roll + options screen
    local frame=newElement("UIElement")
    passive(frame);call(parent,"addElement",frame);call(frame,"setPriority",1000)
    call(frame,"SetAnchorsAndPosition",0.5,0.5,0,1,-700,700,0,700)
    S.cause=label(frame,0,30,690,32,28)
    S.effect=label(frame,710,30,690,32,28)
    S.opts={}
    for i=0,3 do S.opts[i]=label(frame,560,250+i*30,800,28,24) end
    S.desc=label(frame,300,380,1100,26,20)
    S.help=label(frame,330,410,1100,26,20)
    S.left=left;S.frame=frame;S.parent=parent
end

local OPTS={"EFFECTS STACK: ","ALLOW ILLEGAL COMBOS: ","NO REPEAT COMBOS: ","CONFIRM CHOICES"}
local DESCS={"Effects will not be removed when new ones are added, can eventually lead to game breaking combos",
    "Illegal combos are ones that contradict each other, such as 'killing zombies spawn zombies'",
    "When a combo is created, that combo will not be used again",""}
local function render()
    setLabel(S.hud,read("cne_hud"),WHITE,1)
    local shown=read("cne_ca")=="1"
    setRight(S.cause,read("cne_c"),shown and 1 or 0)
    setLabel(S.effect,read("cne_e"),WHITE,shown and 1 or 0)
    local opts=read("cne_os")=="1"
    -- cne_view = cursor*8 + effects stack + illegal*2 + no repeat*4
    -- the GSC value wins once it changes, except right after a local key press (it may still lag behind)
    local g=read("cne_view")
    S.n=(S.n or 0)+1
    if g~=S.gview and S.n>=(S.hold or 0) then S.gview=g;S.view=tonumber(g) or 0 end
    local code=S.view or 0
    local cur=math.floor(code/8)%4
    for i=0,3 do
        local text=OPTS[i+1]
        if i<3 then text=text..((math.floor(code/2^i)%2==1) and "ON" or "OFF") end
        setLabel(S.opts[i],text,(i==cur) and YELLOW or WHITE,opts and 1 or 0)
    end
    setLabel(S.desc,DESCS[cur+1],GREY,opts and 1 or 0)
    setLabel(S.help,"ADS / FIRE or ARROWS to move up/down.   USE or ENTER to select",WHITE,opts and 1 or 0)
end

local function tick()
    if not inMatch() then if S.frame then clear() end;return end
    local parent=displayParent()
    if not parent then return end
    if not S.frame or S.parent~=parent then build(parent) end
    render()
end

-- native UI timer (same technique as zm_splitter_post.lua): a hidden element with Wait(16), rescheduled each time
local function timerRoot()
    local L=rawget(_G,"LUI")
    local ok,current=pcall(invoke,L,"GetRoot")
    if ok and current then return current end
    return get(L,"primaryRoot")
end
local function ensureTimer()
    if not S.enabled then return end
    if not inMatch() then
        if S.host then pcall(call,S.host,"closeTree");S.host=nil end
        return
    end
    local root=timerRoot()
    if not root then return end
    local okParent,parent=pcall(call,S.host,"getParent")
    if okParent and parent==root then return end
    if S.host then pcall(call,S.host,"closeTree") end
    S.host=nil
    pcall(function()
        local host=newElement("UIElement")
        passive(host);call(root,"addElement",host);S.host=host
        local function schedule()
            if not S.enabled or S.host~=host then return end
            local animation=call(host,"Wait",16)
            if not animation then S.host=nil;return end
            animation.onComplete=function()
                if not S.enabled or S.host~=host then return end
                if not pcall(tick) then clear() end
                if not inMatch() then
                    pcall(call,host,"closeTree")
                    if S.host==host then S.host=nil end
                    return
                end
                pcall(schedule)
            end
        end
        schedule()
    end)
end
S.clear=clear

-- options screen keys: arrows / D-pad / Enter bump the cne_up / cne_down / cne_enter counters the GSC polls
-- (same technique and key names as FuzMenu's zmm_up / zmm_down / zmm_enter; names and their hashes)
local NAV={uparrow="up",arrowup="up",up="up",button_dpad_up="up",dpad_up="up",pad_up="up",dpadup="up",
    downarrow="down",arrowdown="down",down="down",button_dpad_down="down",dpad_down="down",pad_down="down",dpaddown="down",
    enter="enter",kp_enter="enter",["return"]="enter"}
local STICKS={}
for _,prefix in ipairs({"apad_","apad2_","stick_","lstick_","rstick_","button_lstick_","button_rstick_"}) do
    for _,direction in ipairs({"up","down","left","right"}) do STICKS[prefix..direction]=true end
end
for _,names in ipairs({NAV,STICKS}) do
    local hashed={}
    for name,value in pairs(names) do hashed[tostring(H(name)):lower()]=value end
    for name,value in pairs(hashed) do names[name]=value end
end
local function navKey(button,key,uiBind)
    local b,k,u=tostring(button):lower(),tostring(key):lower(),tostring(uiBind):lower()
    if STICKS[b] or STICKS[k] or STICKS[u] then return nil end
    return NAV[k] or NAV[b]
end

-- the timer is (re)started from input, like the splitter
local installed=setmetatable({},{__mode="k"})
local function install()
    local input=get(rawget(_G,"LUI"),"UIRoot")
    local original=get(input,"QueueInput")
    if type(original)~="function" or installed[input] then return end
    local wrapped=function(...)
        if S.enabled then pcall(ensureTimer) end
        local _,c,_,down,button,_,_,_,_,_,key,uiBind=...
        local ok,nav=pcall(function() return S.enabled and (tonumber(c) or 0)==0 and read("cne_os")=="1" and navKey(button,key,uiBind) end)
        nav=ok and nav
        if nav then
            if down==true then
                local name="cne_"..nav
                pcall(invoke,rawget(_G,"Dvar"),"SetDvarString",hd(name),tostring((tonumber(read(name)) or 0)+1))
                -- same rules as the GSC loop, shown at once instead of after the GSC round trip
                local v=S.view or 0
                local cur,bits=math.floor(v/8)%4,v%8
                if nav=="up" then cur=(cur+3)%4 elseif nav=="down" then cur=(cur+1)%4
                elseif cur<3 then local b=2^cur;bits=(math.floor(bits/b)%2==1) and bits-b or bits+b end
                S.view=cur*8+bits;S.hold=(S.n or 0)+20
                if S.frame then pcall(render) end
            end
            return true
        end
        return original(...)
    end
    installed[input]=true
    input.QueueInput=wrapped;input[h("QueueInput")]=wrapped
end
pcall(ensureTimer)
pcall(install)
