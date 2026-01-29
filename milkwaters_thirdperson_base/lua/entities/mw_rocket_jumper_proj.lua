if SERVER then
	AddCSLuaFile()
	game.AddParticles( "particles/rockettrail.pcf" )
	PrecacheParticleSystem("rockettrail_RocketJumper")
end

DEFINE_BASECLASS("mw_rocket_proj")

ENT.PrintName = "MW Rocket Jumper"
ENT.TrailEffect = "rockettrail_RocketJumper"