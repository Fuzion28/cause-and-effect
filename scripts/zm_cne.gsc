#using scripts\common\utility;
#using scripts\common\weapon;
#using scripts\common\callbacks;
#using scripts\common\status_effects\effect_charm;
#using scripts\mp\zm\systems\zm_armor;
#using scripts\mp\zm\systems\agent_manager;
#using script_3b64eb40368c1450;
#using script_6995a3eb7d571a9f;
#using script_4e3b2b1d9542e66b;
#using script_4fca32f463c5e4fa;
#using script_25a8fa2ac8997425;
#using script_3a9d7a7cfee99885;
#using script_2301d27669c5a079;
#using script_aa3bac81ad4fc8e;
#using script_427ce33ec0c820cf;
#using script_4f24ca7a470a5fa8;
#using script_4ccf8f7e270f2426;
#using script_4b576523c81e6ee3;
#using script_27623f7ac600060c;
#using script_54198e0a02e4a0cd;
#using script_7bef99a2b184bfd5;
#using script_46fecad419c065b2;
#using script_23131bd305bbd11b;
#using script_4478f81b31480314;
#using script_724b8f06df0c96b1;
#using script_734dce84c468439b;
#using script_1f6b7243f8d72fef;
#using script_53d9b43dfecd95ed;
#using script_681a06cc8e9fcb34;
#using script_7b92812967b04687;
#using script_6c2f6a14fa53759e;
#using script_6b0663a111030b30;
#using script_c1369b1abe9a0d1;
#using script_8c8e132af264960;
#using script_1ade2fa7cae9593d;
#using script_66cb9fe5d1bbff6;
#using script_3b3991e0b89ff57b;
#using script_64d6db6054238125;

#namespace zm_cne;

// Cause And Effect by LogisticalReaper, ported to BO7.
// Every round a random cause is linked to a random effect: each time the cause happens, the effect happens.
// HUD (cne_post.lua) reads the cne_* dvars.

autoexec init()
{
    if ( !utility::iszm() )
    {
        return;
    }
    // autoexec can run twice (FuzMenu guards the same way): two option loops would steal each other's presses
    if ( isdefined( level.cne_initialized ) )
    {
        return;
    }
    level.cne_initialized = 1;
    setdvar( @"cne_hud", "" );
    setdvar( @"cne_c", "" );
    setdvar( @"cne_e", "" );
    setdvar( @"cne_ca", "0" );
    setdvar( @"cne_os", "0" );
    // dvars created after init never reach the Lua side, so create every one here
    setdvar( @"cne_view", "" );
    setdvar( @"cne_up", "0" );
    setdvar( @"cne_down", "0" );
    setdvar( @"cne_enter", "0" );
    level.cne = spawnstruct();
    level.cne.causes = [];
    level.cne.effects = [];
    level.cne.illegal = [];
    level.cne.used = [];
    level.cne.stack = 0;
    level.cne.allow_illegal = 0;
    level.cne.no_repeat = 0;

    cne_cause( "when a perk is purchased", 1, "cne_perk" );
    cne_cause( "when a powerup spawns", 0, "cne_powerup" );
    cne_cause( "when a zombie spawns", 0, "cne_zspawn" );
    cne_cause( "when a zombie dies", 0, "cne_zdie" );
    cne_cause( "when a player takes damage", 1, "cne_damage" );
    cne_cause( "when a player gets a headshot", 0, "cne_headshot" );
    cne_cause( "when a zombie dies to a grenade", 0, "cne_grenade" );
    cne_cause( "when a player earns 100+ points", 0, "cne_earn100" );
    cne_cause( "when a player loses 300+ points", 0, "cne_lose300" );
    cne_cause( "when a player loses 1000+ points", 0, "cne_lose1000" );
    cne_cause( "when a door is purchased", 0, "cne_door", &cne_doors_left );
    cne_cause( "when a player reloads", 1, "cne_reload" );
    cne_cause( "when a player swaps weapons", 1, "cne_swap" );
    cne_cause( "when a gumball is eaten", 1, "cne_gum", &cne_gums_exist );
    cne_cause( "when a player slides", 0, "cne_slide" );

    cne_effect( "a zombie spawns", &cne_e_zombie );
    cne_effect( "5 zombies spawn", &cne_e_zombies5 );
    cne_effect( "a random perk is lost", &cne_e_perk_lose );
    cne_effect( "a random perk is gained", &cne_e_perk_gain );
    cne_effect( "gain 100 points", &cne_e_gain100 );
    cne_effect( "lose 100 points", &cne_e_lose100 );
    cne_effect( "gain 10 percent of your total points", &cne_e_gain10p );
    cne_effect( "lose 10 percent of your total points", &cne_e_lose10p );
    cne_effect( "Activate a random gobblegum effect", &cne_e_gum_use, &cne_gums_exist );
    cne_effect( "Give a random gobblegum", &cne_e_gum_give, &cne_gums_exist );
    cne_effect( "Give a random gun", &cne_e_gun );
    cne_effect( "Give a random paped gun", &cne_e_gun_pap, &cne_round_over6 );
    cne_effect( "Active gun toggles being paped", &cne_e_pap_toggle, &cne_round_over6 );
    cne_effect( "Held gun becomes paped", &cne_e_pap, &cne_round_over6 );
    cne_effect( "Held gun becomes un-paped", &cne_e_unpap, &cne_round_over6 );
    cne_effect( "Spawn a random powerup", &cne_e_powerup );
    cne_effect( "Open a random door", &cne_e_door, &cne_doors_left );
    cne_effect( "Player speed is randomised", &cne_e_speed );
    cne_effect( "Wallbuy prices are randomised", &cne_e_wall_prices );
    cne_effect( "Wallbuys are randomised", &cne_e_wall_shuffle );
    cne_effect( "An earthquake occurs", &cne_e_quake );
    cne_effect( "A random zombie dies", &cne_e_zombie_die );
    cne_effect( "A random player drops a grenade", &cne_e_grenade );
    cne_effect( "The mystery box moves", &cne_e_box_move );
    cne_effect( "Active weapon gets random attachments", &cne_e_atts );
    cne_effect( "Players orientation is slightly changed", &cne_e_orient );
    cne_effect( "A random zombie triggers an AAT", &cne_e_zombie_aat, &cne_aats_exist );
    cne_effect( "Players gun gets a random AAT", &cne_e_aat_give, &cne_aat_round );
    cne_effect( "Players AAT is removed", &cne_e_aat_remove, &cne_aat_round );
    cne_effect( "Players take 1 damage", &cne_e_damage1 );
    cne_effect( "Players ability to sprint will toggle", &cne_e_sprint );
    cne_effect( "Players ability to ADS will toggle", &cne_e_ads );
    cne_effect( "Players gun gets a random camo", &cne_e_camo );
    cne_effect( "all zombies gain 10 percent of their max health", &cne_e_zombie_health );
    cne_effect( "a random player is slightly moved", &cne_e_push );
    cne_effect( "a random zombie teleports near a player", &cne_e_zombie_tp );
    cne_effect( "Players ability to slide will toggle", &cne_e_slide );
    cne_effect( "Players ability to jump will toggle", &cne_e_jump );
    cne_effect( "perks will randomize their locations", &cne_e_perk_shuffle );
    cne_effect( "active gun looses a bullet", &cne_e_bullet );

    cne_illegal( "when a zombie spawns", "a zombie spawns" );
    cne_illegal( "when a zombie spawns", "5 zombies spawn" );
    cne_illegal( "when a zombie dies", "a zombie spawns" );
    cne_illegal( "when a zombie dies", "5 zombies spawn" );
    cne_illegal( "when a player earns 100+ points", "gain 100 points" );
    cne_illegal( "when a player earns 100+ points", "gain 10 percent of your total points" );
    cne_illegal( "when a player loses 300+ points", "lose 10 percent of your total points" );
    cne_illegal( "when a player loses 1000+ points", "lose 10 percent of your total points" );
    cne_illegal( "when a powerup spawns", "Spawn a random powerup" );
    cne_illegal( "when a player swaps weapons", "Give a random gun" );
    cne_illegal( "when a player swaps weapons", "Give a random paped gun" );
    cne_illegal( "when a player swaps weapons", "Active gun toggles being paped" );
    cne_illegal( "when a zombie spawns", "A random zombie dies" );
    cne_illegal( "when a player swaps weapons", "Active weapon gets random attachments" );
    cne_illegal( "when a zombie spawns", "lose 10 percent of your total points" );
    cne_illegal( "when a zombie dies", "lose 10 percent of your total points" );
    cne_illegal( "when a player gets a headshot", "lose 10 percent of your total points" );
    cne_illegal( "when a player takes damage", "lose 10 percent of your total points" );
    cne_illegal( "when a player slides", "lose 10 percent of your total points" );
    cne_illegal( "when a player reloads", "lose 10 percent of your total points" );
    cne_illegal( "when a player swaps weapons", "lose 10 percent of your total points" );
    cne_illegal( "when a zombie spawns", "Give a random gun" );
    cne_illegal( "when a zombie dies", "Give a random gun" );
    cne_illegal( "when a zombie spawns", "Give a random paped gun" );
    cne_illegal( "when a zombie dies", "Give a random paped gun" );

    level callback::add( #"player_spawned", &cne_on_spawned );
    level callback::add( #"hash_652eb614ba902b3d", &cne_on_damaged );
    level callback::add( "on_zombie_ai_spawned", &cne_on_zombie_spawned );
    level callback::add( "on_zombie_ai_killed", &cne_on_zombie_killed );
    level callback::add( "currency_add", &cne_on_currency_add );
    level callback::add( "currency_sub", &cne_on_currency_sub );
    level callback::add( "doorbuy_opened", &cne_on_door );
    level callback::add( "on_gobblegum_activated", &cne_on_gum );
    level thread cne_level_bridges();
    level thread cne_main();
}

function cne_cause( name, player_scoped, ev, valid )
{
    c = spawnstruct();
    c.name = name;
    c.player_scoped = player_scoped;
    c.ev = ev;
    c.valid = valid;
    level.cne.causes[ level.cne.causes.size ] = c;
}

function cne_effect( name, fn, valid )
{
    e = spawnstruct();
    e.name = name;
    e.fn = fn;
    e.valid = valid;
    level.cne.effects[ level.cne.effects.size ] = e;
}

function cne_illegal( cause, effect )
{
    level.cne.illegal[ level.cne.illegal.size ] = cause + "|" + effect;
}

// ---------------------------------------------------------------- flow

function cne_main()
{
    while ( !isdefined( level.players ) || level.players.size == 0 )
    {
        wait 0.1;
    }
    wait 2;
    cne_options();
    total = level.cne.effects.size * level.cne.causes.size;
    if ( !level.cne.allow_illegal )
    {
        total -= level.cne.illegal.size;
    }
    iprintlnbold( total + " possible combos found" );
    wait 1;
    round = cne_round();
    while ( true )
    {
        cne_roll();
        while ( cne_round() == round )
        {
            wait 0.25;
        }
        round = cne_round();
    }
}

function cne_roll()
{
    c = level.cne.causes[ randomint( level.cne.causes.size ) ];
    e = level.cne.effects[ randomint( level.cne.effects.size ) ];
    setdvar( @"cne_c", c.name );
    setdvar( @"cne_e", e.name );
    setdvar( @"cne_ca", "1" );
    for ( i = 0; i < 10; i++ )
    {
        wait 0.1;
        c = level.cne.causes[ randomint( level.cne.causes.size ) ];
        e = level.cne.effects[ randomint( level.cne.effects.size ) ];
        setdvar( @"cne_c", c.name );
        setdvar( @"cne_e", e.name );
        cne_sound_all( "evt_perk_deny" );
    }
    while ( cne_is_illegal( c, e ) )
    {
        wait 0.1;
        c = level.cne.causes[ randomint( level.cne.causes.size ) ];
        e = level.cne.effects[ randomint( level.cne.effects.size ) ];
        setdvar( @"cne_c", c.name );
        setdvar( @"cne_e", e.name );
        cne_sound_all( "evt_perk_deny" );
    }
    cne_sound_all( "purchase" );
    level.cne.used[ level.cne.used.size ] = c.name + "|" + e.name;
    level.cne.last_c = c;
    level.cne.last_e = e;
    setdvar( @"cne_hud", c.name + ", " + e.name );
    level thread cne_listen( c, e );
    wait 3;
    setdvar( @"cne_ca", "0" );
    wait 1;
}

function cne_is_illegal( c, e )
{
    if ( isdefined( level.cne.last_c ) && ( level.cne.last_c == c || level.cne.last_e == e ) )
    {
        return 1;
    }
    if ( isdefined( c.valid ) && ![[ c.valid ]]() )
    {
        return 1;
    }
    if ( isdefined( e.valid ) && ![[ e.valid ]]() )
    {
        return 1;
    }
    key = c.name + "|" + e.name;
    if ( level.cne.no_repeat && cne_in( level.cne.used, key ) )
    {
        return 1;
    }
    if ( !level.cne.allow_illegal && cne_in( level.cne.illegal, key ) )
    {
        return 1;
    }
    return 0;
}

function cne_in( arr, value )
{
    foreach ( v in arr )
    {
        if ( v == value )
        {
            return 1;
        }
    }
    return 0;
}

// shortcut: player-scoped causes share one level listener (BO3 ran one per player, so its 0.3 s cooldown was per player)
function cne_listen( c, e )
{
    level notify( "cne_newcombo" );
    wait 0.1;
    if ( !level.cne.stack )
    {
        level endon( "cne_newcombo" );
    }
    while ( true )
    {
        level waittill( c.ev );
        level thread [[ e.fn ]]();
        wait 0.3;
    }
}

function cne_round()
{
    if ( isdefined( level.round_number ) )
    {
        return level.round_number;
    }
    if ( isdefined( level.var_6781718da4f78d1c ) && isdefined( level.var_6781718da4f78d1c.roundnumber ) )
    {
        return level.var_6781718da4f78d1c.roundnumber;
    }
    return 1;
}

function cne_sound_all( alias )
{
    foreach ( player in level.players )
    {
        player function_a4dacccfc139cfca( alias );
    }
}

function cne_host()
{
    // the function_b36623eefe0028c8 host check left the options loop with no host here
    // shortcut: in coop a guest at index 0 drives the options screen, upgrade if guests report it
    return level.players[ 0 ];
}

// button reads run on the host's own thread, like FuzMenu's menu input loop
function cne_options_input()
{
    self endon( "disconnect" );
    level endon( "cne_options_done" );
    was = 1;
    while ( true )
    {
        btn = undefined;
        if ( self adsbuttonpressed() )
        {
            btn = "up";
        }
        else if ( self attackbuttonpressed() )
        {
            btn = "down";
        }
        else if ( self usebuttonpressed() )
        {
            btn = "use";
        }
        // one press per push: act on the frame it goes down
        if ( isdefined( btn ) && !was )
        {
            level.cne.opt_btn = btn;
        }
        was = isdefined( btn );
        wait 0.05;
    }
}

// host picks the options, everyone is frozen until it confirms
// cne_post.lua owns the texts: cne_view is one number, cursor * 8 + effects stack + illegal * 2 + no repeat * 4
function cne_options()
{
    // number -> dvar string without building strings at runtime
    codes = strtok( "0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31", "," );
    vals = [];
    vals[ 0 ] = 0;
    vals[ 1 ] = 0;
    vals[ 2 ] = 0;
    cursor = 0;
    // only movement is blocked: freezecontrols may stop the host button reads in BO7
    // shortcut: players joining during the options screen can move, fine for a few seconds
    foreach ( player in level.players )
    {
        player namespace_214d79f87f4bf971::set( "cne_options", "allow_movement", 0 );
    }
    level.cne.opt_btn = undefined;
    last = -1;
    host = undefined;
    nav_up = getdvar( @"cne_up" );
    nav_down = getdvar( @"cne_down" );
    nav_enter = getdvar( @"cne_enter" );
    setdvar( @"cne_os", "1" );
    while ( true )
    {
        code = cursor * 8 + vals[ 0 ] + vals[ 1 ] * 2 + vals[ 2 ] * 4;
        if ( code != last )
        {
            setdvar( @"cne_view", codes[ code ] );
            last = code;
        }
        // (re)start the reader when the host changes or leaves
        if ( !isdefined( host ) || host != cne_host() )
        {
            host = cne_host();
            level notify( "cne_options_reader" );
            if ( isdefined( host ) )
            {
                host thread cne_options_reader();
            }
        }
        // arrow keys / D-pad / Enter: counters bumped by cne_post.lua, like FuzMenu's zmm_up / zmm_down / zmm_enter
        // every press since the last frame is applied, so fast presses are not lost
        btns = [];
        for ( i = int( nav_up ); i < int( getdvar( @"cne_up" ) ); i++ )
        {
            btns[ btns.size ] = "up";
        }
        for ( i = int( nav_down ); i < int( getdvar( @"cne_down" ) ); i++ )
        {
            btns[ btns.size ] = "down";
        }
        for ( i = int( nav_enter ); i < int( getdvar( @"cne_enter" ) ); i++ )
        {
            btns[ btns.size ] = "use";
        }
        nav_up = getdvar( @"cne_up" );
        nav_down = getdvar( @"cne_down" );
        nav_enter = getdvar( @"cne_enter" );
        if ( isdefined( level.cne.opt_btn ) )
        {
            btns[ btns.size ] = level.cne.opt_btn;
            level.cne.opt_btn = undefined;
        }
        done = 0;
        foreach ( btn in btns )
        {
            if ( btn == "up" )
            {
                cursor = ( cursor + 3 ) % 4;
            }
            else if ( btn == "down" )
            {
                cursor = ( cursor + 1 ) % 4;
            }
            else if ( cursor == 3 )
            {
                done = 1;
                break;
            }
            else
            {
                vals[ cursor ] = 1 - vals[ cursor ];
            }
        }
        if ( done )
        {
            break;
        }
        waitframe();
    }
    level notify( "cne_options_done" );
    level.cne.stack = vals[ 0 ];
    level.cne.allow_illegal = vals[ 1 ];
    level.cne.no_repeat = vals[ 2 ];
    setdvar( @"cne_os", "0" );
    foreach ( player in level.players )
    {
        player namespace_214d79f87f4bf971::function_9a5ee51116044765( "cne_options" );
    }
}

// one reader at a time: a new host stops the old reader
function cne_options_reader()
{
    level endon( "cne_options_reader" );
    self cne_options_input();
}

// ---------------------------------------------------------------- causes

function cne_level_bridges()
{
    level thread cne_bridge( #"perk_purchased", "cne_perk" );
    level thread cne_bridge( #"hash_8db4924bade08eda", "cne_powerup" );
}

function cne_bridge( from, to )
{
    while ( true )
    {
        level waittill( from );
        level notify( to );
    }
}

function cne_on_spawned( params )
{
    self notify( "cne_spawned" );
    self thread cne_player_bridge( "reload_start", "cne_reload" );
    self thread cne_player_bridge( "weapon_change", "cne_swap" );
    self thread cne_watch_slide();
}

function cne_player_bridge( from, to )
{
    self endon( "cne_spawned" );
    self endon( "disconnect" );
    self endon( "death" );
    while ( true )
    {
        self waittill( from );
        // the camo effect re-gives the gun: its weapon_change must not fire "when you swap weapons" again
        if ( !istrue( self.cne_quiet ) )
        {
            level notify( to );
        }
    }
}

function cne_watch_slide()
{
    self endon( "cne_spawned" );
    self endon( "disconnect" );
    self endon( "death" );
    while ( true )
    {
        self waittill( #"sprint_slide_begin" );
        level notify( "cne_slide" );
    }
}

function cne_on_damaged( params )
{
    if ( isdefined( self ) && isplayer( self ) && isdefined( params ) && isdefined( params.var_a87b62c261a8d114 ) && params.var_a87b62c261a8d114 > 0 )
    {
        level notify( "cne_damage" );
    }
}

function cne_on_zombie_spawned( params )
{
    level notify( "cne_zspawn" );
}

function cne_on_zombie_killed( params )
{
    // BO3 counted player kills only: every death would chain with "A random zombie dies"
    if ( !isdefined( params ) )
    {
        return;
    }
    if ( isdefined( params.var_917e21c98d80255e ) && isplayer( params.var_917e21c98d80255e ) )
    {
        level notify( "cne_zdie" );
    }
    if ( isdefined( params.var_917e21c98d80255e ) && isplayer( params.var_917e21c98d80255e ) && ( params.var_f5a880abf0b199dc === "MOD_HEAD_SHOT" || params.var_181dac8470cfcf7e === "head" || params.var_181dac8470cfcf7e === "helmet" ) )
    {
        level notify( "cne_headshot" );
    }
    if ( params.var_f5a880abf0b199dc === "MOD_GRENADE" || params.var_f5a880abf0b199dc === "MOD_GRENADE_SPLASH" )
    {
        level notify( "cne_grenade" );
    }
}

function cne_on_currency_add( params )
{
    if ( isdefined( params ) && params.var_b5ef086383fc50ad === #"essence" && isdefined( params.var_bcfddc715fcfced6 ) && params.var_bcfddc715fcfced6 >= 100 )
    {
        level notify( "cne_earn100" );
    }
}

function cne_on_currency_sub( params )
{
    if ( !isdefined( params ) || !( params.var_b5ef086383fc50ad === #"essence" ) || !isdefined( params.var_bcfddc715fcfced6 ) )
    {
        return;
    }
    if ( params.var_bcfddc715fcfced6 >= 300 )
    {
        level notify( "cne_lose300" );
    }
    if ( params.var_bcfddc715fcfced6 >= 1000 )
    {
        level notify( "cne_lose1000" );
    }
}

function cne_on_door( params )
{
    level notify( "cne_door" );
}

function cne_on_gum( params )
{
    level notify( "cne_gum" );
}

// ---------------------------------------------------------------- validators

function cne_round_over6()
{
    return cne_round() > 6;
}

function cne_gums_exist()
{
    return cne_gum_pool().size > 0;
}

function cne_aats_exist()
{
    return istrue( level.var_63141d9a04f77f16 ) && isdefined( level.var_19d17bcdd41b0abc ) && getarraykeys( level.var_19d17bcdd41b0abc ).size > 0;
}

function cne_aat_round()
{
    return cne_round_over6() && cne_aats_exist();
}

function cne_doors_left()
{
    return cne_closed_doors().size > 0;
}

// ---------------------------------------------------------------- helpers

function cne_players()
{
    out = [];
    foreach ( player in level.players )
    {
        if ( isdefined( player ) && isalive( player ) )
        {
            out[ out.size ] = player;
        }
    }
    return out;
}

function cne_random_player()
{
    players = cne_players();
    if ( players.size == 0 )
    {
        return undefined;
    }
    return players[ randomint( players.size ) ];
}

function cne_zombies()
{
    team = isdefined( level.zombie_team ) ? level.zombie_team : "team_two_hundred";
    out = [];
    foreach ( ai in getaiarray( team ) )
    {
        if ( isdefined( ai ) && isalive( ai ) && !( ai.var_e4312c2c1a4a2190 === "boss" ) )
        {
            out[ out.size ] = ai;
        }
    }
    return out;
}

function cne_random_zombie()
{
    zombies = cne_zombies();
    if ( zombies.size == 0 )
    {
        return undefined;
    }
    return zombies[ randomint( zombies.size ) ];
}

function cne_nav_near( origin, dist )
{
    yaw = randomfloatrange( 0, 360 );
    point = getclosestpointonnavmesh( origin + anglestoforward( ( 0, yaw, 0 ) ) * dist );
    if ( !isdefined( point ) )
    {
        point = getclosestpointonnavmesh( origin );
    }
    return isdefined( point ) ? point : origin;
}

function cne_points( player )
{
    return player points::function_8f0a9502ff7321a();
}

function cne_set_points( player, value )
{
    if ( value > 999999 )
    {
        value = 999999;
    }
    if ( value < 0 )
    {
        value = 0;
    }
    player points::function_40dc4b206b63ac2e( int( value ) );
}

function cne_perk_keys()
{
    keys = [];
    if ( !isdefined( level.var_35cae1d5b8f6f7c2 ) )
    {
        return keys;
    }
    foreach ( perk in getarraykeys( level.var_35cae1d5b8f6f7c2 ) )
    {
        if ( perk != "specialty_choice" )
        {
            keys[ keys.size ] = perk;
        }
    }
    return keys;
}

function cne_gum_ok( name )
{
    if ( !isdefined( name ) || name == "" || name == "none" || name == "empty" || name == "weapon_null" || name == "mr_peeks" )
    {
        return 0;
    }
    if ( !isdefined( level.bgb[ name ] ) || !isdefined( level.bgb[ name ].name ) || istrue( level.bgb[ name ].banned ) )
    {
        return 0;
    }
    gum_hash = getxhash( name );
    return isdefined( level.gobblegums[ gum_hash ] ) && isdefined( level.gobblegums[ gum_hash ].index );
}

function cne_gum_pool()
{
    pool = [];
    if ( !isdefined( level.bgb ) || !isdefined( level.gobblegums ) )
    {
        return pool;
    }
    foreach ( name in getarraykeys( level.bgb ) )
    {
        if ( cne_gum_ok( name ) )
        {
            pool[ pool.size ] = name;
        }
    }
    return pool;
}

function cne_gum_slot_busy( slot )
{
    if ( isdefined( self.var_f1dccd054c74a27e ) && istrue( self.var_f1dccd054c74a27e[ slot ] ) )
    {
        return 1;
    }
    return isdefined( self.bgb_activation_in_progress ) && istrue( self.bgb_activation_in_progress[ slot ] );
}

function cne_write_gum_slot( slot, name )
{
    index = level.gobblegums[ getxhash( name ) ].index;
    self.var_b02f6e7abbbc8a84[ slot ] = name;
    self setclientomnvar( "ui_gobblegum_slot_" + slot, index );
    self setclientomnvar( "ui_focused_gobblegum_slot_index", slot );
    self setclientomnvar( "ui_gobblegum_slot_acquired_notify", slot );
}

// FuzMenu menu_equip_gum: put the gum in a slot and use it at once
function cne_use_gum( name )
{
    if ( !isdefined( self.var_b02f6e7abbbc8a84 ) )
    {
        return;
    }
    slot = self bgb::function_ad853cdb036bfd57( name );
    if ( !isdefined( slot ) )
    {
        slot = self bgb::function_c0286238eba807();
    }
    if ( !isdefined( slot ) || self bgb::is_active( name ) || !self bgb::function_f88abb570e486ee7( name, slot ) )
    {
        return;
    }
    self bgb::function_d9c0fbf34ae14706( slot, name, 1, 0 );
    if ( self.var_b02f6e7abbbc8a84[ slot ] === name )
    {
        self bgb::function_60937e6f9fe071c5( slot );
    }
}

function cne_is_melee( w )
{
    return isdefined( w ) && isdefined( w.basename ) && ( issubstr( w.basename, "_me_" ) || issubstr( w.basename, "_ww_locust" ) );
}

function cne_assign_slot( w )
{
    if ( weapon::function_6b74ecd475e99b4( w ) || cne_is_melee( w ) )
    {
        self weapon::function_b4c9549dee5d0fc5( w );
        return;
    }
    self assignweaponprimaryslot( w );
}

function cne_fill_one( w )
{
    self givemaxammo( w );
    clip = weaponclipsize( w );
    if ( isdefined( clip ) && clip > 0 )
    {
        self setweaponammoclip( w, clip );
    }
    stock = utility::get_max_stock_ammo( w );
    if ( isdefined( stock ) && stock > 0 )
    {
        self setweaponammostock( w, stock );
    }
}

function cne_fill_ammo( w )
{
    if ( !isdefined( w ) || isnullweapon( w ) )
    {
        return;
    }
    cne_fill_one( w );
    alt = w getaltweapon();
    if ( isdefined( alt ) && !isnullweapon( alt ) )
    {
        cne_fill_one( alt );
    }
}

function cne_pap_level( w )
{
    if ( !utility::issharedfuncdefined( #"pack_a_punch", #"get_pap_level" ) )
    {
        return 0;
    }
    lvl = self utility::callsharedfunc( #"pack_a_punch", #"get_pap_level", w );
    if ( !isdefined( lvl ) || lvl < 0 )
    {
        return 0;
    }
    return lvl;
}

function cne_call_pap_weapon( w, cur, tier )
{
    self.cne_wnew = self utility::callsharedfunc( #"pack_a_punch", #"pap_weapon", w, cur, 0, undefined, undefined, 0, 0, tier );
}

function cne_call_rebuild_pap( base, tier )
{
    ammo_mod = undefined;
    if ( utility::issharedfuncdefined( #"ammo_mod", #"hash_cf1012c4d313de70" ) )
    {
        ammo_mod = self utility::callsharedfunc( #"ammo_mod", #"hash_cf1012c4d313de70", base );
    }
    self.cne_wnew = self utility::callsharedfunc( #"pack_a_punch", #"rebuild_pap_weapon", base, tier, ammo_mod );
}

// FuzMenu menu_pap on the held gun
function cne_pap( tier )
{
    if ( !utility::issharedfuncdefined( #"pack_a_punch", #"pap_weapon" ) )
    {
        return;
    }
    if ( !isdefined( self.var_66c0acd81fb4e585 ) )
    {
        self.var_66c0acd81fb4e585 = [];
    }
    w = self getcurrentweapon();
    if ( !isdefined( w ) || isnullweapon( w ) || cne_is_melee( w ) )
    {
        return;
    }
    cur = cne_pap_level( w );
    if ( cur == tier )
    {
        return;
    }
    self.cne_wnew = undefined;
    self thread cne_call_pap_weapon( w, cur, tier );
    waitframe();
    waitframe();
    w_new = self.cne_wnew;
    if ( isdefined( w_new ) && !isnullweapon( w_new ) )
    {
        self cne_assign_slot( w_new );
        self switchtoweapon( w_new );
        cne_fill_ammo( w_new );
        return;
    }
    if ( !utility::issharedfuncdefined( #"pack_a_punch", #"rebuild_pap_weapon" ) )
    {
        return;
    }
    base = w getnoaltweapon();
    if ( !isdefined( base ) || isnullweapon( base ) )
    {
        base = w;
    }
    self.cne_wnew = undefined;
    self thread cne_call_rebuild_pap( base, tier );
    waitframe();
    waitframe();
    w_new = self.cne_wnew;
    if ( isdefined( w_new ) && !isnullweapon( w_new ) )
    {
        self takeweapon( w );
        self giveweapon( w_new, undefined, 0, -1, 1 );
        self cne_assign_slot( w_new );
        cne_fill_ammo( w_new );
        self switchtoweapon( w_new );
        self utility::callsharedfunc( #"pack_a_punch", #"set_pap_level", w_new, tier, 1, base );
    }
}

function cne_gun_pool()
{
    // string array literals come out undefined in BO7 here, so fill by index
    pool = [];
    pool[ pool.size ] = "t10_ar_p01_coslo723";
    pool[ pool.size ] = "t10_ar_p02_aking74";
    pool[ pool.size ] = "t10_ar_p04_clove";
    pool[ pool.size ] = "t10_ar_p05_fable";
    pool[ pool.size ] = "t10_ar_p05_rmary2";
    pool[ pool.size ] = "t10_ar_p06_asvalor";
    pool[ pool.size ] = "t10_ar_p22_able18";
    pool[ pool.size ] = "t10_ar_p23_love85";
    pool[ pool.size ] = "t10_ar_p34_tbaker";
    pool[ pool.size ] = "t10_ar_p45_kent";
    pool[ pool.size ] = "t10_ar_p47_gilroy";
    pool[ pool.size ] = "t10_ar_p49_fresno";
    pool[ pool.size ] = "t10_ar_p54_aspen";
    pool[ pool.size ] = "t10_ar_p56_milan";
    pool[ pool.size ] = "t10_sm_p02_geasy9";
    pool[ pool.size ] = "t10_sm_p03_safox";
    pool[ pool.size ] = "t10_sm_p04_chuck9";
    pool[ pool.size ] = "t10_sm_p06_sroger3";
    pool[ pool.size ] = "t10_sm_p12_roger31";
    pool[ pool.size ] = "t10_sm_p21_pparis90";
    pool[ pool.size ] = "t10_sm_p28_saug";
    pool[ pool.size ] = "t10_sm_p41_perth";
    pool[ pool.size ] = "t10_sm_p43_schuck";
    pool[ pool.size ] = "t10_sm_p52_lisbon";
    pool[ pool.size ] = "t10_sm_p57_mpug40";
    pool[ pool.size ] = "t10_lm_p01_aroger10";
    pool[ pool.size ] = "t10_lm_p02_puncle21";
    pool[ pool.size ] = "t10_lm_p07_ksugar58";
    pool[ pool.size ] = "t10_lm_p33_uxray";
    pool[ pool.size ] = "t10_lm_p53_mesa";
    pool[ pool.size ] = "t10_sh_p10_moslo500";
    pool[ pool.size ] = "t10_sh_p11_olove";
    pool[ pool.size ] = "t10_sh_p25_uncle12";
    pool[ pool.size ] = "t10_sh_p27_jhavana";
    pool[ pool.size ] = "t10_dm_p01_sroger25";
    pool[ pool.size ] = "t10_dm_p02_aeasy";
    pool[ pool.size ] = "t10_dm_p03_sgeorge550";
    pool[ pool.size ] = "t10_dm_p05_falove";
    pool[ pool.size ] = "t10_dm_p09_svalor";
    pool[ pool.size ] = "t10_dm_p50_erie";
    pool[ pool.size ] = "t10_sn_p08_ultiger";
    pool[ pool.size ] = "t10_sn_p09_droger";
    pool[ pool.size ] = "t10_sn_p24_love96";
    pool[ pool.size ] = "t10_sn_p26_mary82";
    pool[ pool.size ] = "t10_sn_p46_hugo";
    pool[ pool.size ] = "t10_pi_p12_paris30";
    pool[ pool.size ] = "t10_pi_p13_usugar9";
    pool[ pool.size ] = "t10_pi_p14_mable";
    pool[ pool.size ] = "t10_pi_p14_stiger";
    pool[ pool.size ] = "t10_pi_p42_pyork";
    return pool;
}

// FuzMenu menu_give_bo6: random t10 gun, replaces the held one when the player already has 3 guns
function cne_give_gun( paped )
{
    self endon( "disconnect" );
    pool = cne_gun_pool();
    name = pool[ randomint( pool.size ) ] + "_mp";
    if ( !weaponexists( name ) )
    {
        return;
    }
    w = weapon::buildweapon( name, getweapondefaultattachments( name ) );
    if ( !isdefined( w ) || isnullweapon( w ) || self hasweapon( w ) )
    {
        return;
    }
    self loadweaponsforplayer( [ w ], 1 );
    for ( i = 0; i < 50 && !self hasloadedviewweapons( [ w ] ); i++ )
    {
        wait 0.1;
    }
    if ( !self hasloadedviewweapons( [ w ] ) )
    {
        return;
    }
    guns = [];
    if ( isdefined( self.primaryinventory ) )
    {
        foreach ( g in self.primaryinventory )
        {
            if ( isdefined( g ) && !isnullweapon( g ) && isdefined( g.basename ) && !issubstr( g.basename, "_me_" ) )
            {
                guns[ guns.size ] = g;
            }
        }
    }
    if ( guns.size >= 3 )
    {
        old = guns[ 0 ];
        foreach ( g in guns )
        {
            if ( g == self getcurrentweapon() )
            {
                old = g;
            }
        }
        self takeweapon( old );
        wait 0.1;
    }
    self giveweapon( w, undefined, 0, -1, 0 );
    self assignweaponprimaryslot( w );
    self switchtoweapon( w );
    cne_fill_ammo( w );
    if ( paped )
    {
        wait 0.5;
        self cne_pap( 1 );
    }
}

function cne_closed_doors()
{
    out = [];
    if ( !isdefined( level.var_7cfb92ddbd4165 ) )
    {
        return out;
    }
    foreach ( buy in level.var_7cfb92ddbd4165 )
    {
        if ( !isdefined( buy ) || !isdefined( buy.var_3c562ea28639ec43 ) )
        {
            continue;
        }
        foreach ( door in buy.var_3c562ea28639ec43 )
        {
            if ( isdefined( door ) && !istrue( door.var_c1c98a810b837560 ) )
            {
                out[ out.size ] = door;
            }
        }
    }
    return out;
}

// toggles revert when the next combo is rolled
function cne_reset_on_new_combo( kind )
{
    level notify( "cne_reset_" + kind );
    level endon( "cne_reset_" + kind );
    level waittill( "cne_newcombo" );
    foreach ( player in level.players )
    {
        if ( !isdefined( player ) )
        {
            continue;
        }
        if ( kind == "speed" )
        {
            player setmovespeedscale( 1 );
        }
        else if ( kind == "sprint" )
        {
            player cne_allow( "sprint", 1 );
        }
        else if ( kind == "ads" )
        {
            player cne_allow( "ads", 1 );
        }
        else if ( kind == "slide" )
        {
            player cne_allow( "slide", 1 );
        }
        else if ( kind == "jump" )
        {
            player function_92305205d36aa2e1( 1 );
        }
    }
    level.cne.toggle[ kind ] = undefined;
}

function cne_toggle( kind )
{
    if ( !isdefined( level.cne.toggle ) )
    {
        level.cne.toggle = [];
    }
    level.cne.toggle[ kind ] = !istrue( level.cne.toggle[ kind ] );
    level thread cne_reset_on_new_combo( kind );
    return level.cne.toggle[ kind ];
}

// ---------------------------------------------------------------- effects (self = level)

function cne_spawn_zombie()
{
    player = cne_random_player();
    if ( !isdefined( player ) )
    {
        return;
    }
    origin = cne_nav_near( player.origin, ( 500 + randomint( 400 ) ) );
    agent_manager::spawn_agent( "zombie_base", origin, ( 0, randomint( 360 ), 0 ), isdefined( level.zombie_team ) ? level.zombie_team : "team_two_hundred" );
}

function cne_e_zombie()
{
    cne_spawn_zombie();
}

function cne_e_zombies5()
{
    for ( i = 0; i < 5; i++ )
    {
        cne_spawn_zombie();
        waitframe();
    }
}

function cne_e_perk_lose()
{
    foreach ( player in cne_players() )
    {
        owned = [];
        foreach ( perk in cne_perk_keys() )
        {
            if ( player namespace_377106c4017f7cda::function_e183e1e4f906ec3b( perk ) )
            {
                owned[ owned.size ] = perk;
            }
        }
        if ( owned.size > 0 )
        {
            player namespace_377106c4017f7cda::function_145b00820a9f68b2( owned[ randomint( owned.size ) ], 1 );
        }
    }
}

function cne_e_perk_gain()
{
    foreach ( player in cne_players() )
    {
        if ( !player namespace_214d79f87f4bf971::function_e5c588558239ba2a( "allow_zm_perks" ) )
        {
            continue;
        }
        missing = [];
        foreach ( perk in cne_perk_keys() )
        {
            if ( !player namespace_377106c4017f7cda::function_e183e1e4f906ec3b( perk ) )
            {
                missing[ missing.size ] = perk;
            }
        }
        if ( missing.size > 0 )
        {
            player namespace_377106c4017f7cda::function_a969ec70f9242aa4( missing[ randomint( missing.size ) ], 0 );
        }
    }
}

function cne_e_gain100()
{
    foreach ( player in cne_players() )
    {
        cne_set_points( player, cne_points( player ) + 100 );
    }
}

function cne_e_lose100()
{
    foreach ( player in cne_players() )
    {
        cne_set_points( player, cne_points( player ) - 100 );
    }
}

function cne_e_gain10p()
{
    foreach ( player in cne_players() )
    {
        p = cne_points( player );
        cne_set_points( player, p + int( p / 10 ) );
    }
}

function cne_e_lose10p()
{
    foreach ( player in cne_players() )
    {
        p = cne_points( player );
        cne_set_points( player, p - int( p / 10 ) );
    }
}

function cne_e_gum_use()
{
    pool = cne_gum_pool();
    if ( pool.size == 0 )
    {
        return;
    }
    foreach ( player in cne_players() )
    {
        player thread cne_use_gum( pool[ randomint( pool.size ) ] );
    }
}

function cne_e_gum_give()
{
    pool = cne_gum_pool();
    if ( pool.size == 0 )
    {
        return;
    }
    foreach ( player in cne_players() )
    {
        if ( !isdefined( player.var_b02f6e7abbbc8a84 ) )
        {
            continue;
        }
        name = pool[ randomint( pool.size ) ];
        for ( slot = 1; slot <= 3; slot++ )
        {
            if ( !isdefined( player.var_b02f6e7abbbc8a84[ slot ] ) && !player cne_gum_slot_busy( slot ) )
            {
                player cne_write_gum_slot( slot, name );
                break;
            }
        }
    }
}

function cne_e_gun()
{
    foreach ( player in cne_players() )
    {
        player thread cne_give_gun( 0 );
    }
}

function cne_e_gun_pap()
{
    foreach ( player in cne_players() )
    {
        player thread cne_give_gun( 1 );
    }
}

function cne_e_pap_toggle()
{
    foreach ( player in cne_players() )
    {
        w = player getcurrentweapon();
        player thread cne_pap( player cne_pap_level( w ) > 0 ? 0 : 1 );
    }
}

function cne_e_pap()
{
    foreach ( player in cne_players() )
    {
        if ( player cne_pap_level( player getcurrentweapon() ) == 0 )
        {
            player thread cne_pap( 1 );
        }
    }
}

function cne_e_unpap()
{
    foreach ( player in cne_players() )
    {
        if ( player cne_pap_level( player getcurrentweapon() ) > 0 )
        {
            player thread cne_pap( 0 );
        }
    }
}

function cne_e_powerup()
{
    player = cne_random_player();
    if ( !isdefined( player ) || !utility::issharedfuncdefined( #"powerups", #"dropPowerup" ) || !utility::issharedfuncdefined( #"powerups", #"hash_a25fdc7ee24539fb" ) )
    {
        return;
    }
    root = utility::callsharedfunc( #"powerups", #"hash_a25fdc7ee24539fb" );
    if ( !isdefined( root ) || !isdefined( root.powerups ) )
    {
        return;
    }
    names = [];
    foreach ( name in strtok( "double_points,insta_kill,full_ammo,full_armor,full_power,free_perk,fire_sale,bonus_points_team", "," ) )
    {
        if ( isdefined( root.powerups[ name ] ) )
        {
            names[ names.size ] = name;
        }
    }
    if ( names.size > 0 )
    {
        utility::callsharedfunc( #"powerups", #"dropPowerup", names[ randomint( names.size ) ], player.origin + ( 0, 0, 40 ), undefined, undefined, undefined, 0 );
    }
}

function cne_e_door()
{
    doors = cne_closed_doors();
    if ( doors.size > 0 )
    {
        doors[ randomint( doors.size ) ] thread doorbuy::function_f3160e450543b4f1();
    }
}

function cne_e_speed()
{
    level thread cne_reset_on_new_combo( "speed" );
    foreach ( player in cne_players() )
    {
        player setmovespeedscale( randomfloatrange( 0.5, 1.5 ) );
    }
}

function cne_e_quake()
{
    earthquake( 0.75, 1.5, ( 0, 0, 0 ), 1000000 );
}

function cne_e_zombie_die()
{
    zombie = cne_random_zombie();
    if ( isdefined( zombie ) )
    {
        zombie dodamage( zombie.health + 666, zombie.origin );
    }
}

function cne_e_grenade()
{
    player = cne_random_player();
    if ( isdefined( player ) )
    {
        function_6ab09d0c58e92c8f( function_c95bf1a14134f45c( "frag_grenade_mp" ), player.origin, ( 0, 0, 300 ), 3, player );
    }
}

function cne_e_orient()
{
    foreach ( player in cne_players() )
    {
        player setplayerangles( player getplayerangles() + ( ( -10 + randomint( 20 ) ), ( -10 + randomint( 20 ) ), ( -10 + randomint( 20 ) ) ) );
    }
}

function cne_aat_names()
{
    if ( !cne_aats_exist() )
    {
        return [];
    }
    return getarraykeys( level.var_19d17bcdd41b0abc );
}

function cne_e_zombie_aat()
{
    names = cne_aat_names();
    zombie = cne_random_zombie();
    player = cne_random_player();
    if ( names.size == 0 || !isdefined( zombie ) || !isdefined( player ) )
    {
        return;
    }
    aat = level.var_19d17bcdd41b0abc[ names[ randomint( names.size ) ] ];
    if ( !isdefined( aat ) || !isdefined( aat.var_511d306b51d343a2 ) )
    {
        return;
    }
    params = spawnstruct();
    params.var_e663e01e515b27 = player getcurrentweapon();
    params.var_9da2453b2f6432c6 = "MOD_RIFLE_BULLET";
    params.var_128a21c9943cb581 = player;
    params.death = 0;
    params.var_181dac8470cfcf7e = "torso_upper";
    params.var_3652debfa8ff37f2 = zombie.origin;
    zombie thread [[ aat.var_511d306b51d343a2 ]]( params );
}

function cne_e_aat_give()
{
    names = cne_aat_names();
    if ( names.size == 0 )
    {
        return;
    }
    foreach ( player in cne_players() )
    {
        player namespace_cb5c0a8769de6627::function_b166f92c763fbcba( player getcurrentweapon(), names[ randomint( names.size ) ], 1, 1, 1 );
    }
}

function cne_e_aat_remove()
{
    foreach ( player in cne_players() )
    {
        player namespace_cb5c0a8769de6627::function_e6267ae500506234( player getcurrentweapon(), 1 );
    }
}

function cne_e_damage1()
{
    foreach ( player in cne_players() )
    {
        player dodamage( 1, player.origin );
    }
}

function cne_e_sprint()
{
    on = cne_toggle( "sprint" );
    foreach ( player in cne_players() )
    {
        player cne_allow( "sprint", !on );
    }
}

function cne_e_ads()
{
    on = cne_toggle( "ads" );
    foreach ( player in cne_players() )
    {
        player cne_allow( "ads", !on );
    }
}

function cne_e_slide()
{
    on = cne_toggle( "slide" );
    foreach ( player in cne_players() )
    {
        player cne_allow( "slide", !on );
    }
}

// BO7 val system (namespace_214d79f87f4bf971): set( id, ability, 0 ) blocks, function_9a5ee51116044765( id ) restores
function cne_allow( kind, allow )
{
    if ( allow )
    {
        self namespace_214d79f87f4bf971::function_9a5ee51116044765( "cne_" + kind );
    }
    else
    {
        self namespace_214d79f87f4bf971::set( "cne_" + kind, kind, 0 );
    }
}

function cne_e_jump()
{
    on = cne_toggle( "jump" );
    foreach ( player in cne_players() )
    {
        player function_92305205d36aa2e1( on ? 0 : 1 );
    }
}

function cne_camo_one()
{
    self endon( "disconnect" );
    gun = self getcurrentweapon();
    if ( !isdefined( gun ) || isnullweapon( gun ) )
    {
        return;
    }
    idx = randomint( 210 );
    num = ( idx % 15 ) + 1;
    letters = strtok( "a,b,c,d,e,f,g,h,i,j,k,l,m,n", "," );
    camo = "camo_" + letters[ int( idx / 15 ) ] + ( num < 10 ? "_0" : "_" ) + num;
    w = gun withcamo( camo );
    if ( !isdefined( w ) || isnullweapon( w ) )
    {
        return;
    }
    self loadweaponsforplayer( [ w ], 1 );
    for ( i = 0; i < 30 && !self hasloadedviewweapons( [ w ] ); i++ )
    {
        wait 0.1;
    }
    self.cne_quiet = 1;
    self takeweapon( gun );
    wait 0.1;
    self giveweapon( w, undefined, 0, -1, 0 );
    self cne_assign_slot( w );
    self switchtoweapon( w );
    cne_fill_ammo( w );
    // shortcut: a real swap in this 0.5 s is not counted either
    wait 0.5;
    self.cne_quiet = undefined;
}

function cne_e_camo()
{
    foreach ( player in cne_players() )
    {
        player thread cne_camo_one();
    }
}

function cne_e_zombie_health()
{
    foreach ( zombie in cne_zombies() )
    {
        if ( isdefined( zombie.maxhealth ) )
        {
            zombie.health += int( zombie.maxhealth / 10 );
        }
    }
}

function cne_e_push()
{
    player = cne_random_player();
    if ( isdefined( player ) )
    {
        player setvelocity( anglestoforward( ( 0, randomint( 360 ), 0 ) ) * 100 );
    }
}

function cne_e_zombie_tp()
{
    zombie = cne_random_zombie();
    player = cne_random_player();
    if ( isdefined( zombie ) && isdefined( player ) )
    {
        zombie forceteleport( cne_nav_near( player.origin, ( 150 + randomint( 150 ) ) ), zombie.angles );
    }
}

function cne_e_bullet()
{
    foreach ( player in cne_players() )
    {
        w = player getcurrentweapon();
        clip = player getweaponammoclip( w );
        if ( clip > 0 )
        {
            player setweaponammoclip( w, clip - 1 );
        }
    }
}

function cne_shuffle( a )
{
    for ( i = a.size - 1; i > 0; i-- )
    {
        j = randomint( i + 1 );
        t = a[ i ];
        a[ i ] = a[ j ];
        a[ j ] = t;
    }
    return a;
}

// the game's own box swap (magicbox hide / show), within the active box's group
function cne_e_box_move()
{
    if ( istrue( level.var_5542fc8f8eafa0c0 ) || !isdefined( level.var_1bbb5557537e2c0c ) )
    {
        return;
    }
    if ( namespace_60b3bdcc70f79fc6::function_f0bb112fe637e41c( "powerup_fire_sale_active" ) || namespace_60b3bdcc70f79fc6::function_f0bb112fe637e41c( "magicbox_moving" ) )
    {
        return;
    }
    cur = undefined;
    foreach ( b in level.var_1bbb5557537e2c0c )
    {
        if ( istrue( b.var_f14b2b4820b635e7 ) )
        {
            cur = b;
        }
    }
    if ( !isdefined( cur ) || istrue( cur.var_c73496e2485e061c ) || !isdefined( level.var_e0e84452fe117b5f[ cur.var_93e4a0a8514ca47e ] ) )
    {
        return;
    }
    use = cur.var_97c6497c84d770a;
    if ( isdefined( use ) && isdefined( use.var_4cf63ec91b753a3c ) && istrue( use.var_4cf63ec91b753a3c.var_6365ea93403efebd ) )
    {
        return;
    }
    opts = [];
    foreach ( b in level.var_e0e84452fe117b5f[ cur.var_93e4a0a8514ca47e ] )
    {
        if ( b == cur || istrue( b.var_c5f5d57861834358 ) )
        {
            continue;
        }
        if ( isdefined( b.var_fb2d21c83ee3088 ) && !namespace_60b3bdcc70f79fc6::function_f0bb112fe637e41c( b.var_fb2d21c83ee3088 ) )
        {
            continue;
        }
        opts[ opts.size ] = b;
    }
    if ( opts.size == 0 )
    {
        return;
    }
    dest = opts[ randomint( opts.size ) ];
    cur magicbox::function_3fc5ec87d3083d53( 1, 0 );
    cur.var_f14b2b4820b635e7 = undefined;
    dest magicbox::function_d032ba44d110e870( 1, 0 );
    dest.var_f14b2b4820b635e7 = 1;
}

// BO3: 0.5x to 2x the original price, rounded to 10 (the buy and the hint read .cost live)
function cne_e_wall_prices()
{
    if ( !isdefined( level.var_caf65b937e9cbfaf ) )
    {
        return;
    }
    foreach ( s in level.var_caf65b937e9cbfaf )
    {
        w = s.var_f9b6c5834058f21c;
        if ( !isdefined( w ) || !isdefined( w.weapon ) || !isdefined( w.cost ) )
        {
            continue;
        }
        if ( !isdefined( w.cne_cost0 ) )
        {
            w.cne_cost0 = w.cost;
        }
        w.cost = randomintrange( int( w.cne_cost0 / 20 ), int( w.cne_cost0 / 5 ) + 1 ) * 10;
    }
    level.cne.wall_prices = 1;
}

// BO3 swaps the weapons between the walls; respawned the way the game re-rolls walls (zombie_mode_modifiers)
function cne_e_wall_shuffle()
{
    if ( !isdefined( level.var_caf65b937e9cbfaf ) )
    {
        return;
    }
    walls = [];
    refs = [];
    foreach ( s in level.var_caf65b937e9cbfaf )
    {
        w = s.var_f9b6c5834058f21c;
        if ( !isdefined( w ) || !isdefined( w.weapon ) || !isdefined( s.script_noteworthy ) || istrue( w.var_8f971982b0ee9b70 ) || isdefined( w.var_ba4beeeffc39ecc1 ) )
        {
            continue;
        }
        walls[ walls.size ] = s;
        refs[ refs.size ] = s.script_noteworthy;
    }
    if ( walls.size < 2 )
    {
        return;
    }
    refs = cne_shuffle( refs );
    for ( i = 0; i < walls.size; i++ )
    {
        s = walls[ i ];
        if ( s.script_noteworthy == refs[ i ] )
        {
            continue;
        }
        w = s.var_f9b6c5834058f21c;
        rarity = w.rarity;
        w function_7f6c18bb105e8057();
        if ( isdefined( w.var_5499b4433cb4a919 ) )
        {
            w.var_5499b4433cb4a919 delete();
        }
        s.script_noteworthy = refs[ i ];
        s namespace_60b3bdcc70f79fc6::function_81557bcd4ddf6a05( #"wallbuy", #"hash_d188728d6e7395f5", s, rarity );
        // shortcut: the game's 1-7 unit chalk nudge per weapon (zombie_mode_modifiers::function_8aee443ce950d61d) is skipped,
        // no other base script links that script, so it may be loaded only in that mode (linking it could break the mod); copy it if a chalk sits off
        waitframe();
    }
    // the respawned walls are back at their table price
    if ( istrue( level.cne.wall_prices ) )
    {
        cne_e_wall_prices();
    }
}

// BO3 function_24b2ba2f: the held gun is rebuilt with random attachments (one per slot), camo / variant / PaP kept
function cne_atts_one()
{
    self endon( "disconnect" );
    cur = self getcurrentweapon();
    if ( !isdefined( cur ) || isnullweapon( cur ) || cne_is_melee( cur ) )
    {
        return;
    }
    root = weapon::function_f541f60718130d5d( cur );
    if ( !isdefined( root ) || root == "" )
    {
        return;
    }
    // the game's own fit check (weapon::function_c9460ac2e5b36f70) reads this setup; a weapon is a setup too
    setup = cur;
    if ( isdefined( level.var_2500f362153f0a30 ) && isdefined( level.var_2500f362153f0a30[ root ] ) && isdefined( level.var_2500f362153f0a30[ root ].var_f8983e5049a6b2cd ) )
    {
        setup = level.var_2500f362153f0a30[ root ].var_f8983e5049a6b2cd;
    }
    pool = cne_shuffle( weapon::function_c377d088dcc0bf5a() );
    want = 1 + randomint( 5 );
    atts = [];
    vars = [];
    used = [];
    foreach ( att in pool )
    {
        if ( atts.size >= want )
        {
            break;
        }
        slot = function_5b465daf157fa9a1( setup, att );
        if ( !isdefined( slot ) || slot == -1 || isdefined( used[ slot ] ) )
        {
            continue;
        }
        used[ slot ] = 1;
        atts[ atts.size ] = att;
    }
    if ( atts.size == 0 )
    {
        return;
    }
    while ( atts.size < 17 )
    {
        atts[ atts.size ] = "none";
    }
    for ( i = 0; i < 17; i++ )
    {
        vars[ i ] = 0;
    }
    variant = cur.variantid ?? 0;
    bundle = weapon::function_2374da6f1b4fad4e( weapon::function_9312097aa84e222d( root ), variant );
    w = weapon::function_5416d4273f081ce2( root, atts, "camo_none", "none", variant, vars, "charm_none", [ "sticker_none", "sticker_none", "sticker_none", "sticker_none", "sticker_none" ], undefined, undefined, undefined, bundle );
    if ( !isdefined( w ) || isnullweapon( w ) )
    {
        return;
    }
    if ( isdefined( cur.camo ) )
    {
        camo = w withcamo( cur.camo );
        if ( isdefined( camo ) && !isnullweapon( camo ) )
        {
            w = camo;
        }
    }
    tier = cne_pap_level( cur );
    self loadweaponsforplayer( [ w ], 1 );
    for ( i = 0; i < 30 && !self hasloadedviewweapons( [ w ] ); i++ )
    {
        wait 0.1;
    }
    if ( !self hasloadedviewweapons( [ w ] ) || self getcurrentweapon() != cur )
    {
        return;
    }
    self.cne_quiet = 1;
    self takeweapon( cur );
    wait 0.1;
    self giveweapon( w, undefined, 0, -1, 0 );
    self cne_assign_slot( w );
    self switchtoweapon( w );
    cne_fill_ammo( w );
    if ( tier > 0 )
    {
        wait 0.5;
        self cne_pap( tier );
    }
    // shortcut: a real swap in this 0.5 s is not counted either
    wait 0.5;
    self.cne_quiet = undefined;
}

function cne_e_atts()
{
    foreach ( player in cne_players() )
    {
        player thread cne_atts_one();
    }
}

// the old machine's parts, as FuzMenu menu_forge_kill: entities deleted, scriptables freed
function cne_free( e )
{
    if ( !isdefined( e ) )
    {
        return;
    }
    if ( function_9922b1d39dd0034b( e ) )
    {
        e delete();
        return;
    }
    e function_7f6c18bb105e8057();
}

// spawn half of namespace_34fc1661493f2405::function_9a3e81eb8357ad32, as FuzMenu replays it, at s.origin / s.angles
function cne_spawn_machine( s )
{
    kind = s.script_noteworthy;
    def = level.var_35cae1d5b8f6f7c2[ kind ];
    model = def.var_5a88606a27cbabb1 ?? "t10_zm_machine_juggernog";
    swap = def.var_f0be533e42313bb4 ?? model;
    bundle = function_3161539e0a96d772().var_4a98227bf6f428ba;
    if ( function_58736ce92359fa07( bundle ) )
    {
        foreach ( entry in bundle )
        {
            if ( entry.var_5d4a55e1eb574935 == swap )
            {
                model = entry.var_5fb82424b4f67aee;
                swap = entry.var_5fb82424b4f67aee;
            }
        }
    }
    s.var_5a88606a27cbabb1 = model;
    if ( swap != model )
    {
        e = namespace_2bf8af33322ac10f::function_66b9b0c7a4a77d6b( s, swap, 1, 1 );
    }
    else
    {
        e = function_d5fc43f4fe047ed6( swap, s.origin, s.angles );
    }
    s.var_b69810c6c14b1634 = e;
    if ( !isdefined( e ) )
    {
        return;
    }
    namespace_60b3bdcc70f79fc6::function_81557bcd4ddf6a05( #"Scriptable", #"hash_10d5e3bb8a551724", e, "icon" );
    radius = s.RADIUS ?? def.var_86c9ab7f8a945b12 ?? 64;
    if ( function_9922b1d39dd0034b( e ) )
    {
        e.var_4cf63ec91b753a3c = namespace_7fc982453bce8e6a::register_interact( e, radius, level.var_8d83c65a20889deb[ "on_use" ], undefined, undefined, undefined, undefined, "HINT_BUTTON" );
        e.var_4cf63ec91b753a3c function_29e5a164a795cbd8( 130 );
        e.var_4cf63ec91b753a3c namespace_7fc982453bce8e6a::function_316e9b54139e4683( level.var_8d83c65a20889deb[ "per_player_hint" ] );
        if ( e function_9f30212275828d56( "tag_hint" ) )
        {
            e function_c5cb9ee04701c381( "tag_hint" );
        }
    }
    else
    {
        e.var_4cf63ec91b753a3c = namespace_7fc982453bce8e6a::function_2558ae94964fd952( e, level.var_8d83c65a20889deb[ "on_use" ] );
        e.var_4cf63ec91b753a3c namespace_7fc982453bce8e6a::function_316e9b54139e4683( level.var_8d83c65a20889deb[ "per_player_hint" ] );
    }
    e namespace_34fc1661493f2405::function_9fbcc91de1978444( e.var_4cf63ec91b753a3c );
    if ( e function_79ba985c3a2c6d8a() && e function_94cedaac4572406a( "use" ) )
    {
        e function_7555d0f6ef1562a9( "use", "default" );
    }
    e.var_4cf63ec91b753a3c.var_c519b7af216dc312 = s;
    // think starts the power thread, which waits for the power flag and powers the machine itself
    e thread [[ level.var_8d83c65a20889deb[ "think" ] ]]( kind, e.var_4cf63ec91b753a3c );
    e thread namespace_34fc1661493f2405::function_91eb8bd11a034ed2( kind );
}

// BO3 function_3d7c6349: the machines swap places (Wunderfizz left alone)
// shortcut: map props around a machine (decals, bump triggers) stay where they were
function cne_e_perk_shuffle()
{
    if ( !isdefined( level.var_2ad433898c7f6057 ) || !isdefined( level.var_35cae1d5b8f6f7c2 ) || !isdefined( level.var_8d83c65a20889deb ) )
    {
        return;
    }
    ms = [];
    foreach ( s in level.var_2ad433898c7f6057 )
    {
        if ( istrue( s.var_646a6e83c12f8d37 ) || !isdefined( s.var_b69810c6c14b1634 ) || !isdefined( s.script_noteworthy ) || !isdefined( level.var_35cae1d5b8f6f7c2[ s.script_noteworthy ] ) )
        {
            continue;
        }
        ms[ ms.size ] = s;
    }
    if ( ms.size < 2 )
    {
        return;
    }
    spots = [];
    foreach ( s in ms )
    {
        spot = spawnstruct();
        spot.origin = s.origin;
        spot.angles = s.angles;
        spots[ spots.size ] = spot;
    }
    spots = cne_shuffle( spots );
    for ( i = 0; i < ms.size; i++ )
    {
        s = ms[ i ];
        e = s.var_b69810c6c14b1634;
        level notify( s.script_noteworthy + "_power_thread_end" );
        cne_free( e.var_d3e9ac2f3fe07320 );
        cne_free( e.var_a3338cc37b82b7b3 );
        if ( isdefined( e.var_4cf63ec91b753a3c ) && e.var_4cf63ec91b753a3c != e )
        {
            cne_free( e.var_4cf63ec91b753a3c );
        }
        cne_free( e );
        s.origin = spots[ i ].origin;
        s.angles = spots[ i ].angles;
    }
    waitframe();
    foreach ( s in ms )
    {
        cne_spawn_machine( s );
    }
}
