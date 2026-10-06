starPositions = gLevelValues.starPositions
vec3f_set(starPositions.TuxieMotherStarPos, 3500, -4300, 4650)
gLevelValues.entryLevel = SPECIAL_WARP_TITLE
gBehaviorValues.ProcessLODs = 1

local g, t = 0, 0
local x, y, k = 0, 0, 0
local T,Bt = 1, 1
local p
local P = {}

for _, id in ipairs{
	SOUND_PEACH_DEAR_MARIO, SOUND_PEACH_MARIO, SOUND_PEACH_POWER_OF_THE_STARS,
	SOUND_PEACH_THANKS_TO_YOU, SOUND_PEACH_THANK_YOU_MARIO, SOUND_PEACH_SOMETHING_SPECIAL,
	SOUND_PEACH_BAKE_A_CAKE, SOUND_PEACH_FOR_MARIO, SOUND_PEACH_MARIO2,
} do P[id & 0xF0FF0000] = true end

local function freeze(on)
	set_audio_muted(on)
	if on then enable_time_stop_including_mario() camera_freeze()
	else disable_time_stop_including_mario() camera_unfreeze() end
end

hook_event(HOOK_UPDATE, function()
	local m = gMarioStates[0]
	g = get_delayed_warp_op() == WARP_OP_GAME_OVER and g + 1 or 0
	if g == 47 then warp_special(SPECIAL_WARP_GODDARD_GAMEOVER) end
	if t > 0 then t = t + 1
	elseif m.controller.buttonPressed & Y_BUTTON ~= 0 then t = 1 freeze(true) end
	if t > 120 then
		t = 0
		freeze(false)
		local f = get_current_save_file_num()
		if f > 0 then save_file_erase(f - 1) end
		m.numStars, m.numLives, m.health = 0, 4, 0x880
		warp_special(SPECIAL_WARP_TITLE)
	end
end)

hook_event(HOOK_ON_HUD_RENDER, function()
	djui_hud_set_resolution(RESOLUTION_DJUI)
	local sw, sh = djui_hud_get_screen_width(), djui_hud_get_screen_height()
	djui_hud_set_color(20, 20, 40, 30)
	djui_hud_render_rect(0, 0, sw, sh)
	djui_hud_set_color(0, 0, 0, 255)
	for y = 0, sh, 2 do djui_hud_render_rect(0, y, sw, 1) end
	if t > 0 then
		local s = sh / 14
		local h = math.min(s * t / 25, s + 1)
		for y = 0, sh, s do djui_hud_render_rect(0, y, sw, h) end
	end
end)

hook_event(HOOK_ON_HUD_RENDER_BEHIND, function()
	djui_hud_set_resolution(RESOLUTION_N64)
	local w, h = djui_hud_get_screen_width(), djui_hud_get_screen_height()
	djui_hud_set_color(0, 0, 0, 50)
	djui_hud_render_rect(0, 0, w, T)
	djui_hud_render_rect(0, h - Bt, w, Bt)
end)

hook_behavior(id_bhvExclamationBox, OBJ_LIST_SURFACE, false, nil, function(o)
	if o.oTimer > 0 or o.oBehParams2ndByte ~= 8 or gNetworkPlayers[0].currLevelNum ~= LEVEL_JRB or not network_is_server() then return end
	spawn_sync_object(id_bhvStar, E_MODEL_STAR, o.oPosX, o.oPosY, o.oPosZ, nil)
	obj_mark_for_deletion(o)
end)

hook_behavior(id_bhvEyerokBoss,OBJ_LIST_GENACTOR,false,nil,function(o)
	local a=o.oAction
	if a~=p then
	p=a
	local d=a==EYEROK_BOSS_ACT_SHOW_INTRO_TEXT and 117 or a==EYEROK_BOSS_ACT_DIE and 118
	if d then set_mario_action(gMarioStates[0],ACT_READING_AUTOMATIC_DIALOG,d) end
	end
end)

hook_event(HOOK_ON_PLAY_SOUND, function(bits)
	if P[bits & 0xF0FF0000] then return NO_SOUND end
end)

hook_event(HOOK_ON_INTERACT, function(m, o, t)
	if m.playerIndex == 0 and t == INTERACT_STAR_OR_KEY and obj_has_behavior_id(o, id_bhvBowserKey) ~= 0 then k = 1 end
end)

hook_event(HOOK_ON_LEVEL_INIT, function() x, y, k = 0, 0, 0 end)

hook_event(HOOK_MARIO_UPDATE, function(m)
	if m.playerIndex ~= 0 then return end
	if m.action == ACT_FIRST_PERSON then
		local r = m.statusForCamera.headRotation
		x, y = r.x, r.y
	elseif k > 0 then
		if m.action & ACT_GROUP_MASK == ACT_GROUP_CUTSCENE then
			local b = m.marioBodyState
			k, b.allowPartRotation, b.headAngle.x, b.headAngle.y = 2, 1, x, y
		elseif k == 2 then k = 0 end
	end
end)
