--#region DASH/Sprint
game.TraitData.ArtemisSprintBoon = {
	InheritFrom = { "BaseTrait", "EarthBoon" },
	Elements = { "Earth" }, -- Need to add this even if you inherit
	Name = "ArtemisSprintBoon",
	BoonInfoTitle = "ArtemisSprintBoon",
	Icon = "Boon_Artemis_ArtemisSprintBoon",
	Slot = "Rush",
	TraitOrderingValueCache = 50,
	BlockStacking = false,
	RarityLevels = {
		Common = {
			Multiplier = 1.0,
		},
		Rare = {
			Multiplier = 1.5,
		},
		Epic = {
			Multiplier = 2.0,
		},
		Heroic = {
			Multiplier = 2.5,
		},
		Perfect = {
			Multiplier = 3.5,
		},
	},

	OnWeaponFiredFunctions = {
		ValidWeapons = { "WeaponSprint", "WeaponBlink" },
		-- we need to do this string building or the save gets bricked as soon as you leave the room
		FunctionName = "rom.mods." .. _PLUGIN.guid .. ".not.ArtemisSprintFire",
		FunctionArgs = {
			ProjectileName = "ArtemisSupportingFireSprint",
			Cooldown = 0.3,
			Scatter = 180,
			Radius = 500,
			CostPerStrike = 2,
			DamageMultiplier = { BaseValue = 1 },
			ReportValues = {
				ReportedMultiplier = "DamageMultiplier",
				ReportedCost = "CostPerStrike",
				ReportedCooldown = "Cooldown",
			},
		},
	},

	StatLines = { "DashDamageStatDisplay1" },

	ExtractValues = {
		{
			Key = "ReportedMultiplier",
			ExtractAs = "Damage",
			Format = "MultiplyByBase",
			BaseType = "Projectile",
			BaseName = "ArtemisSupportingFireSprint",
			BaseProperty = "Damage",
		},
		{
			SkipAutoExtract = true,
			Key = "ReportedCost",
			ExtractAs = "ManaCost",
		},
		{
			ExtractAs = "Cooldown",
			Key = "ReportedCooldown",
			SkipAutoExtract = true,
			DecimalPlaces = 2,
		},
	},
}

game.ProjectileData.ArtemisSupportingFireSprint = {
	InheritFrom = { "ArtemisColorProjectile" }, -- This doesn't actually inherit anything for some reason
	Name = "ArtemisSupportingFireSprint",

	DamageTextStartColor = Color.ArtemisDamageLight,
	DamageTextColor = Color.ArtemisDamage,
	Sounds = {
		ImpactSounds = {
			Invulnerable = "/SFX/Player Sounds/ZagreusShieldRicochet",
			Armored = "/SFX/Player Sounds/ZagreusShieldRicochet",
			Bone = "/SFX/ArrowMetalBoneSmash",
			Brick = "/SFX/ArrowMetalStoneClang",
			Stone = "/SFX/ArrowMetalStoneClang",
			Organic = "/SFX/GunBulletOrganicImpact",
			StoneObstacle = "/SFX/ArrowWallHitClankSmall",
			BrickObstacle = "/SFX/ArrowWallHitClankSmall",
			MetalObstacle = "/SFX/ArrowWallHitClankSmall",
			BushObstacle = "/Leftovers/World Sounds/LeavesRustle",
		},
	},
}

-- this janky stuff is because the function needs to be public, but we don't really want it to appear as a public function
local not_public = {}
public["not"] = not_public

function not_public.ArtemisSprintFire(weaponData, functionArgs, triggerArgs)
	-- Initially to get rid of anything not sprint or dash, aka torches
	if weaponData.Name ~= "WeaponSprint" and weaponData.Name ~= "WeaponBlink" then
		return
	end

	if weaponData.Name == "WeaponBlink" then
		local OutgoingCritCooldown = 5
		local critvalue = 0.1
		local modifierAdded = false

		for i, v in ipairs(game.CurrentRun.Hero.OutgoingCritModifiers) do
			print("v.Name:" .. v.Name)
			if v.Name == "ArtemisSprintCrit" then
				if not modifierAdded then
					table.remove(game.CurrentRun.Hero.OutgoingCritModifiers, i)
					AddOutgoingCritModifier(game.CurrentRun.Hero, { Name = "ArtemisSprintCrit", ValidWeapons = WeaponSets.HeroPrimarySecondaryWeapons, Chance = critvalue })
					modifierAdded = true
					break
				end
			end
		end

		if not modifierAdded then
			AddOutgoingCritModifier(game.CurrentRun.Hero, { Name = "ArtemisSprintCrit", ValidWeapons = WeaponSets.HeroPrimarySecondaryWeapons, Chance = critvalue })
			modifierAdded = true
		end

		-- Wait 5 seconds, then remove if it exists
		wait(OutgoingCritCooldown, RoomThreadName)

		for i, v in ipairs(game.CurrentRun.Hero.OutgoingCritModifiers) do
			print("v.Name 2:" .. v.Name)

			if v.Name == "ArtemisSprintCrit" then
				table.remove(game.CurrentRun.Hero.OutgoingCritModifiers, i)
			end
			modifierAdded = false
		end
	end

	-- Then we do the arrows on sprint
	if weaponData.Name == "WeaponSprint" then
		local manaCost = 0
		if functionArgs.CostPerStrike and functionArgs.CostPerStrike > 0 then
			manaCost = GetManaCost(weaponData, true, { ManaCostOverride = functionArgs.CostPerStrike })
		end

		-- get closest enemy
		local enemyId = game.GetClosest({
			Id = game.CurrentRun.Hero.ObjectId,
			DestinationName = "EnemyTeam",
			IgnoreInvulnerable = true,
			IgnoreHomingIneligible = true,
			Distance = functionArgs.Radius,
		})

		-- if it's a valid enemy...
		if not (enemyId and game.ActiveEnemies[enemyId] and not game.ActiveEnemies[enemyId].IsDead) then
			return
		end

		local victim = game.ActiveEnemies[enemyId]

		if CheckCooldown("ArtemisSprintFire", functionArgs.Cooldown, true) then
			if game.CurrentRun.Hero.Mana >= manaCost then
				local angle = randomint(0, 360)
				if angle and functionArgs.Scatter then
					angle = angle + RandomFloat(-functionArgs.Scatter, functionArgs.Scatter)
				end

				CreateProjectileFromUnit({
					Name = functionArgs.ProjectileName,
					Id = CurrentRun.Hero.ObjectId,
					DestinationId = victim.ObjectId,
					Angle = angle,
					DamageMultiplier = functionArgs.DamageMultiplier,
					ProjectileCap = 3,
					Count = randomint(1, 3),
				})
				ManaDelta(-manaCost)
			end
		end
	end
end

-- Icon Data
mod.Boon_Artemis_ArtemisSprintBoon = sjson.to_object({
	Name = "Boon_Artemis_ArtemisSprintBoon",
	InheritFrom = "BoonIcon",
	FilePath = rom.path.combine(_PLUGIN.guid, "GUI\\Screens\\BoonIcons\\Artemis\\"),
}, mod.IconOrder)

-- Boons Description/Display
mod.ArtemisSprintBoon = sjson.to_object({
	Id = "ArtemisSprintBoon",
	InheritFrom = "BaseBoonMultiline",
	DisplayName = "Hunter Dash",
	Description = "Your {$Keywords.Sprint} fires seeking arrows, each using {#ManaFormat}{$TooltipData.ExtractData.ManaCost}{#Prev}{!Icons.Mana}."
		.. " Gain a {#UpgradeFormat}10% {#Prev} chance to deal {$Keywords.Crit} damage on your {$Keywords.Attack} and {$Keywords.Special}.",
}, mod.Order)

mod.ArtemisSprintBoon_Text = sjson.to_object({
	Id = "DashDamageStatDisplay1",
	InheritFrom = "BaseStatLine",
	DisplayName = "{!Icons.Bullet}{#PropertyFormat}Arrow Damage:",
	Description = "{#UpgradeFormat}{$TooltipData.StatDisplay1}  {#ItalicFormat}(every {$TooltipData.ExtractData.Cooldown} Sec.)",
}, mod.Order)

-- Adding her ProjectileData
mod.ArtemisSupportingFireSprint = sjson.to_object({
	Name = "ArtemisSupportingFireSprint",
	InheritFrom = "1_BaseNonPhysicalProjectile",
	Type = "HOMING",
	HomingAllegiance = "ENEMIES",
	AdjustRateAcceleration = 900,
	MaxAdjustRate = 3600,
	Speed = 1200,
	Acceleration = 300,
	Range = 1000.0,
	Damage = 20, -- Damage Increased from 10
	CheckObstacleImpact = false,
	CheckUnitImpact = true,
	UnlimitedUnitPenetration = false,
	DetonateAtVictimLocation = true,
	UseVulnerability = true,
	IgnoreCoverageAngles = true,
	Thing = {
		Graphic = "ArtemisRangedArrowheadLegendary",
		OffsetZ = 112,
		AttachedAnim = "null",
		Grip = 999999,
		RotateGeometry = true,
		Points = {
			{
				X = 76,
				Y = 16,
			},
			{
				X = 76,
				Y = -16,
			},
			{
				X = -32,
				Y = -16,
			},
			{
				X = -32,
				Y = 16,
			},
		},
	},
}, mod.ProjectileSupportFireOrder)

-- Adding Boons to Default Artemis
table.insert(game.UnitSetData.NPC_Artemis.NPC_Artemis_Field_01.Traits, 3, "ArtemisSprintBoon")

-- Insert TraitIndex into BoonInfo or else it won't show up in codex since BoonInfo gets populated before traits are added by mods
-- Just adds the boon to the codex - aka the (Hidden) "TraitIndex"
game.ScreenData.BoonInfo.TraitDictionary.NPC_Artemis_Field_01["ArtemisSprintBoon"] = true

-- Adding Traits to TraitData Table, and adding her as core, aka weapon, special, cast, etc
table.insert(game.LinkedTraitData.ArtemisCoreTraits, "ArtemisSprintBoon")

--#endregion

--#region Attack sjson
-- PropertyChanges = {{
--     WeaponName = "WeaponStaffSwing",
--     WeaponProperty = "FireFx",
--     ChangeValue = "StaffProjectileFireFx1_Aphrodite",
--     ChangeType = "Absolute"
-- }, {
--     WeaponName = "WeaponStaffSwing",
--     ProjectileName = "ProjectileStaffSwing1",
--     ProjectileProperty = "Graphic",
--     ChangeValue = "StaffComboAttack1_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponStaffSwing",
--     ProjectileName = "ProjectileStaffSwing1",
--     ProjectileProperty = "DissipateFx",
--     ChangeValue = "StaffComboAttack1Dissipate_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponStaffSwing",
--     ProjectileName = "ProjectileStaffSwing1",
--     ProjectileProperty = "DeathFx",
--     ChangeValue = "StaffComboAttack1Dissipate_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponStaffSwing2",
--     ProjectileName = "ProjectileStaffSwing2",
--     ProjectileProperty = "Graphic",
--     ChangeValue = "StaffComboAttack2_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponStaffSwing2",
--     ProjectileName = "ProjectileStaffSwing2",
--     ProjectileProperty = "DissipateFx",
--     ChangeValue = "StaffComboAttack2Dissipate_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponStaffSwing2",
--     ProjectileName = "ProjectileStaffSwing2",
--     ProjectileProperty = "DeathFx",
--     ChangeValue = "StaffComboAttack2Dissipate_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponStaffSwing3",
--     ProjectileName = "ProjectileStaffSwing3",
--     ProjectileProperty = "Graphic",
--     ChangeValue = "StaffComboAttack3_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponStaffSwing3",
--     ProjectileName = "ProjectileStaffSwing3",
--     ProjectileProperty = "GroupName",
--     ChangeValue = "FX_Standing_Add",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponStaffSwing3",
--     ProjectileName = "ProjectileStaffSwing3",
--     ProjectileProperty = "DissipateFx",
--     ChangeValue = "StaffComboAttack3Dissipate_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponStaffSwing3",
--     ProjectileName = "ProjectileStaffSwing3",
--     ProjectileProperty = "DeathFx",
--     ChangeValue = "StaffComboAttack3Dissipate_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponStaffDash",
--     ProjectileName = "ProjectileStaffDash",
--     ProjectileProperty = "Graphic",
--     ChangeValue = "StaffComboAttack1Dash_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponStaffSwing5",
--     ProjectileName = "ProjectileSwing5Magic",
--     ProjectileProperty = "DetonateFx",
--     ChangeValue = "StaffChargedAttackFx_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponDagger",
--     WeaponProperty = "FireFx",
--     ChangeValue = "DaggerSwipeFast_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponDagger2",
--     WeaponProperty = "FireFx",
--     ChangeValue = "DaggerSwipeFastFlip_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponDaggerMultiStab",
--     ProjectileName = "ProjectileDagger",
--     ProjectileProperty = "DetonateFx",
--     ChangeValue = "DaggerJab_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponDaggerDash",
--     ProjectileName = "ProjectileDaggerDash",
--     WeaponProperty = "FireFx",
--     ChangeValue = "DaggerSwipeFastFlipDash_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponDaggerDouble",
--     ProjectileName = "ProjectileDaggerSliceDouble",
--     ProjectileProperty = "DetonateFx",
--     ChangeValue = "DaggerSwipeDouble_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponDaggerDouble",
--     WeaponProperty = "FireFx",
--     ChangeValue = "null",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponDagger5",
--     WeaponProperty = "FireFx",
--     ChangeValue = "null",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponDagger5",
--     WeaponProperty = "ChargeStartFx",
--     ChangeValue = "DaggerCharge_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponDagger5",
--     ProjectileName = "ProjectileDaggerBackstab",
--     ProjectileProperty = "StartFx",
--     ChangeValue = "DaggerSwipe_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponAxe",
--     WeaponProperty = "FireFx",
--     ChangeValue = "AxeSwipe1_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponAxe2",
--     WeaponProperty = "FireFx",
--     ChangeValue = "AxeSwipe2_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponAxe3",
--     ProjectileName = "ProjectileAxeOverhead",
--     ProjectileProperty = "DetonateFx",
--     ChangeValue = "AxeNova_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponAxeDash",
--     WeaponProperty = "FireFx",
--     ChangeValue = "AxeSwipeUpper_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponAxeSpin",
--     ProjectileName = "ProjectileAxeSpin",
--     ProjectileProperty = "DetonateFx",
--     ChangeValue = "AxeSwipe2Spin_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponLob",
--     ProjectileName = "ProjectileLob",
--     ProjectileProperty = "Graphic",
--     ChangeValue = "LobProjectile_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponLob",
--     ProjectileName = "ProjectileLob",
--     ProjectileProperty = "BounceFx",
--     ChangeValue = "LobProjectileBounceFx_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponLob",
--     ProjectileName = "ProjectileLob",
--     ProjectileProperty = "StartFx",
--     ChangeValue = "StaffProjectileFireFx2Close_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponLob",
--     ProjectileName = "ProjectileLob",
--     ProjectileProperty = "DetonateFx",
--     ChangeValue = "LobExplosion_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponLob",
--     ProjectileName = "ProjectileLobCharged",
--     ProjectileProperty = "Graphic",
--     ChangeValue = "LobProjectileCharged_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponLob",
--     ProjectileName = "ProjectileLobCharged",
--     ProjectileProperty = "AttachedAnim",
--     ChangeValue = "LobProjectileChargedSecondaryEmitter_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponLob",
--     ProjectileName = "ProjectileLobCharged",
--     ProjectileProperty = "DescentStartFx",
--     ChangeValue = "LobEXDescentStart_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponLob",
--     ProjectileName = "ProjectileLobCharged",
--     ProjectileProperty = "StartFx",
--     ChangeValue = "LobEXFireFx_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponLob",
--     ProjectileName = "ProjectileLobCharged",
--     ProjectileProperty = "DetonateFx",
--     ChangeValue = "LobExplosionCharged_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponTorch",
--     ProjectileName = "ProjectileTorchBall",
--     ProjectileProperty = "Graphic",
--     ChangeValue = "TorchProjectileSmallIn_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponTorch",
--     ProjectileName = "ProjectileTorchBallLarge",
--     ProjectileProperty = "Graphic",
--     ChangeValue = "TorchProjectileLargeIn_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponTorch",
--     ProjectileName = "ProjectileTorchBall",
--     ProjectileProperty = "AttachedAnim",
--     ChangeValue = "TorchProjectileShadow_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponTorch",
--     ProjectileName = "ProjectileTorchBallLarge",
--     ProjectileProperty = "AttachedAnim",
--     ChangeValue = "TorchProjectileShadowLarge_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponTorch",
--     ProjectileName = "ProjectileTorchBall",
--     ProjectileProperty = "DissipateFx",
--     ChangeValue = "TorchProjectileDissipate_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponTorch",
--     ProjectileName = "ProjectileTorchBallLarge",
--     ProjectileProperty = "DissipateFx",
--     ChangeValue = "TorchProjectileDissipate_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponTorch",
--     ProjectileName = "ProjectileTorchRepeatStrike",
--     ProjectileProperty = "DetonateFx",
--     ChangeValue = "RadialNovaPentagramCharged_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "WeaponTorch",
--     ProjectileName = "ProjectileTorchRepeatStrikeLarge",
--     ProjectileProperty = "DetonateFx",
--     ChangeValue = "RadialNovaPentagramCharged_Aphrodite",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }}
mod.AxeSwipe1_Artemis = sjson.to_object({
	Name = "AxeSwipe1_Artemis",
	InheritFrom = "AxeSwipe1",
	ClearCreateAnimations = true,
	StartRed = 1.0,
	StartGreen = 0.6,
	StartBlue = 0.8,
	EndRed = 0.99,
	EndGreen = 0.05,
	EndBlue = 0.99,
	VisualFx = "AxeSwipeArtemisParticle", -- BASE DONE
	VisualFxRadialOffsetScaleY = 0.66,
	VisualFxRadialOffsetStartAngle = 40,
	VisualFxRadialOffsetIncrementAngle = -25,
	CreateAnimations = {
		{
			Name = "AxeSwipe1Dark",
		},
		{
			Name = "AxeSwipe1ArtemisFx", -- BASE DONE
		},
		{
			Name = "AxeSwipe1ArtemisFxDisplace", -- BASE DONE
		},
		{
			Name = "AxeSwipe1Spectral_Artemis", -- BASE DONE
		},
		{
			Name = "AxeSwipe1Displacement",
		},
		{
			Name = "AxeSwipeLight_Artemis",
		},
	},
}, mod.Order)

mod.AxeSwipe2_Artemis = sjson.to_object({
	Name = "AxeSwipe2_Artemis",
	InheritFrom = "AxeSwipe2",
	ClearCreateAnimations = true,
	StartRed = 1.0,
	StartGreen = 0.6,
	StartBlue = 0.8,
	EndRed = 0.99,
	EndGreen = 0.05,
	EndBlue = 0.99,
	FlipVertical = true,
	VisualFx = "AxeSwipeArtemisParticleFlip",
	VisualFxRadialOffsetScaleY = 0.66,
	VisualFxRadialOffsetStartAngle = -40,
	VisualFxRadialOffsetIncrementAngle = 25,
	CreateAnimations = {
		{
			Name = "AxeSwipe2Dark",
		},
		{
			Name = "AxeSwipe2Spectral_Artemis",
		},
		{
			Name = "AxeSwipe1ArtemisFxDisplaceFlip",
		},
		{
			Name = "AxeSwipe2Displacement",
		},
		{
			Name = "AxeSwipeLight2_Artemis",
		},
		{
			Name = "AxeSwipe1ArtemisFxFlip",
		},
	},
}, mod.Order)

mod.AxeNova_Artemis = sjson.to_object({
	Name = "AxeNova_Artemis",
	InheritFrom = "AxeNova",
	StartRed = 1.0,
	StartGreen = 0.6,
	StartBlue = 0.8,
	EndRed = 0.99,
	EndGreen = 0.05,
	EndBlue = 0.99,
	VisualFx = "AxeNovaParticles_Artemis",
	VisualFxCap = 24,
	VisualFxIntervalMin = 0.01,
	VisualFxIntervalMax = 0.011,
	TimeModifierFraction = 0.33,
	Sound = "/SFX/Player Sounds/ArtemisLoveShotgunBlast",
	CreateAnimations = { {
		Name = "AxeNovaDark",
	}, {
		Name = "AxeNovaLight_Artemis",
	}, {
		Name = "AxeNovaDisplacement",
	}, {
		Name = "AxeNovaFlare_Artemis",
	}, {
		Name = "AxeGroundCrack",
	}, {
		Name = "AxeNovaArtemisCircle",
	} },
}, mod.Order)

mod.AxeSwipeUpper_Artemis = sjson.to_object({
	Name = "AxeSwipeUpper_Artemis",
	InheritFrom = "AxeSwipeUpper",
	ClearCreateAnimations = true,
	StartRed = 1.0,
	StartGreen = 0.6,
	StartBlue = 0.8,
	EndRed = 0.99,
	EndGreen = 0.05,
	EndBlue = 0.99,
	VisualFx = "AxeSwipeUpperParticles_Artemis",
	VisualFxIntervalMin = 0.01,
	VisualFxIntervalMax = 0.01,
	VisualFxCap = 10,
	Sound = "/SFX/Player Sounds/ArtemisLoveSwipe",
	CreateAnimations = { {
		Name = "AxeSwipeUpperDark",
	}, {
		Name = "AxeSwipeUpperSpectral_Artemis",
	}, {
		Name = "AxeSwipeUpperDisplacement",
	}, {
		Name = "AxeSwipeUpperLight_Artemis",
	}, {
		Name = "AxeSwipeUpper_ArtemisFx",
	} },
}, mod.Order)

mod.AxeSwipe2Spin_Artemis = sjson.to_object({
	Name = "AxeSwipe2Spin_Artemis",
	InheritFrom = "AxeSwipe1_Artemis",
	LocationZFromOwner = "Take",
	FlipVertical = true,
	ClearCreateAnimations = true,
	StartAngle = 0,
	EndAngle = 359,
	AngleMin = 0,
	AngleMax = 180,
	RandomPlaySpeedMin = 40,
	RandomPlaySpeedMax = 50,
	ScaleRadius = 256,
	StartRed = 1.0,
	StartGreen = 0.7,
	StartBlue = 0.9,
	EndRed = 0.9,
	EndGreen = 0.2,
	EndBlue = 0.999,
	Sound = "/SFX/Player Sounds/ArtemisLoveSwipe",
	VisualFx = "AxeSpinArtemisSparkle",
	VisualFxRadialOffsetScaleY = 0.66,
	VisualFxRadialOffsetStartAngle = 0,
	VisualFxRadialOffsetIncrementAngle = 40,
	VisualFxCap = 8,
	VisualFxIntervalMin = 0.01,
	VisualFxIntervalMax = 0.01,
	UseAttachedTipLocation = true,
	AttachedTipLocationScaleY = 0.6,
	VisualFxRadialOffsetLength = 350,
	CreateAnimations = { {
		Name = "AxeSwipe2SpinDark",
	}, {
		Name = "AxeSwipeSpinArtemisFx",
	}, {
		Name = "AxeSwipeLightSpin_Artemis",
	}, {
		Name = "AxeSwipe2SpinSpectral_Artemis",
	}, {
		Name = "AxeSwipe2SpinDisplacement",
	} },
}, mod.Order)

mod.AxeSwipe1ArtemisFx = sjson.to_object({
	Name = "AxeSwipe1ArtemisFx",
	FilePath = "Fx\\Artemis\\ArtemisSwipe\\ArtemisSwipe", -- ADD
	NumFrames = 23,
	PostRotateScaleY = 0.6,
	Material = "Unlit",
	LocationZFromOwner = "Take",
	LocationFromOwner = "Maintain",
	AngleFromOwner = "Take",
	SortMode = "FromParent",
	SortFromOwner = "Maintain",
	GroupName = "FX_Standing_Add",
	Scale = 2.0,
	StartRed = 1.0,
	StartGreen = 0.7,
	StartBlue = 0.9,
	EndRed = 0.9,
	EndGreen = 0.6,
	EndBlue = 0.999,
	EaseIn = 0.99,
	EaseOut = 1.00,
	StartScale = 1.0,
	EndScale = 1.05,
}, mod.Order)

mod.AxeSwipe1ArtemisFxDisplace = sjson.to_object({
	Name = "AxeSwipe1ArtemisFxDisplace",
	InheritFrom = "AxeSwipe1ArtemisFx",
	GroupName = "FX_Displacement",
	Scale = 3,
	PlaySpeed = 45,
	Alpha = 0.25,
}, mod.Order)

mod.AxeSwipe1ArtemisFxDisplaceFlip = sjson.to_object({
	Name = "AxeSwipe1ArtemisFxDisplaceFlip",
	InheritFrom = "AxeSwipe1ArtemisFxDisplace",
	FlipVertical = true,
}, mod.Order)

mod.AxeSwipeArtemisParticle = sjson.to_object({
	Name = "AxeSwipeArtemisParticle",
	FilePath = "Fx\\Artemis\\ArtemisAxeHeartParticle\\ArtemisAxeHeartParticle", -- ADD
	RandomPlaySpeedMin = 45,
	RandomPlaySpeedMax = 60,
	NumFrames = 19,
	Material = "Unlit",
	AngleFromOwner = "Take",
	VelocityMin = 400,
	VelocityMax = 500,
	Acceleration = -600,
	LocationFromOwner = "Ignore",
	LocationZFromOwner = "Ignore",
	GroupName = "FX_Standing_Add",
	EaseIn = 0.95,
	EaseOut = 1.0,
	RandomFlipVertical = true,
	StartScale = 0.5,
	EndScale = 1.0,
	AngleMin = -90,
	AngleMax = -90.1,
	PostRotateScaleY = 0.5,
	TransferAngle = true,
	VisualFx = "AxeSwipeArtemisSparkle",
	VisualFxCap = 2,
	VisualFxIntervalMin = 0.01,
	VisualFxIntervalMax = 0.1,
	VisualFxUse3DAngle = true,
}, mod.Order)

mod.AxeSwipe1Spectral_Artemis = sjson.to_object({
	Name = "AxeSwipe1Spectral_Artemis",
	InheritFrom = "AxeSwipe1Spectral",
	Scale = 3.0,
	PlaySpeed = 45,
	Hue = 0.75,
	Red = 1,
	Green = 1,
	Blue = 0.5,
	Saturation = -0.3,
}, mod.Order)

mod.AxeSwipeLight_Artemis = sjson.to_object({
	Name = "AxeSwipeLight_Artemis",
	InheritFrom = "AxeSwipeLight",
	StartRed = 1.0,
	StartGreen = 0.9,
	StartBlue = 0.7,
	EndRed = 0.999,
	EndGreen = 0.85,
	EndBlue = 0.05,
	Duration = 0.25,
	Scale = 3.5,
	RotationSpeed = 360,
}, mod.Order)

--#endregion

--#region Special SJSON
-- What the fuck is this
-- EnemyPropertyChanges = {{
--     TraitName = "GunLoadedGrenadeTrait",
--     LegalUnits = {"GunBombUnit"},
--     ThingProperty = "Graphic",
--     ChangeValue = "LuciferBomb-Artemis",
--     ChangeType = "Absolute"
-- }},
-- PropertyChanges = {{
--     WeaponName = "SwordParry",
--     ProjectileProperty = "DetonateGraphic",
--     ChangeValue = "RadialNovaSwordParry-Artemis",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "SpearWeaponThrow",
--     ProjectileProperty = "Graphic",
--     ChangeValue = "SpearThrowProjectile-Artemis",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "SpearWeaponThrowReturn",
--     ProjectileProperty = "Graphic",
--     ChangeValue = "SpearThrowProjectile-Artemis",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "SpearWeaponThrow",
--     ProjectileProperty = "StartFx",
--     ChangeValue = "ArtemisSpearThrowStartFx",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "BowSplitShot",
--     ProjectileProperty = "Graphic",
--     ChangeValue = "BowWeaponArrow-Artemis-SplitShot",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "BowSplitShot",
--     WeaponProperty = "MinChargeStartFx",
--     ChangeValue = "BowCharge-Artemis",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponNames = {"ShieldThrow", "ShieldThrowDash"},
--     ProjectileName = "ShieldThrow",
--     ProjectileProperty = "DetonateGraphic",
--     ChangeValue = "ShieldSwipe-Artemis",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponNames = {"ShieldThrowDash"},
--     ProjectileName = "ShieldThrowDash",
--     ProjectileProperty = "DetonateGraphic",
--     ChangeValue = "ShieldSwipe-Artemis",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponNames = {"ShieldThrow", "ShieldThrowDash"},
--     WeaponProperty = "ChargeStartFx",
--     ChangeValue = "ShieldCharge-Artemis",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "GunGrenadeToss",
--     ProjectileProperty = "DetonateGraphic",
--     ChangeValue = "ZagGrenadeExplosionArtemis",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponNames = {"ShieldThrow", "ShieldThrowDash"},
--     ProjectileProperty = "Graphic",
--     ChangeValue = "ProjectileShield-Artemis",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     TraitName = "ShieldRushBonusProjectileTrait",
--     ProjectileProperty = "Graphic",
--     WeaponNames = {"ShieldThrow", "ShieldThrowDash", "ChaosShieldThrow"},
--     ChangeValue = "ProjectileShieldAlt01-Artemis",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     TraitName = "ShieldLoadAmmoTrait",
--     ProjectileProperty = "Graphic",
--     WeaponNames = {"ShieldThrow", "ShieldThrowDash", "ChaosShieldThrow"},
--     ChangeValue = "ProjectileShieldAlt03-Artemis",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     TraitName = "ShieldTwoShieldTrait",
--     ProjectileProperty = "Graphic",
--     WeaponName = "ShieldThrow",
--     ChangeValue = "ProjectileShieldAlt02-Poseidon",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     TraitName = "ShieldTwoShieldTrait",
--     WeaponName = "ShieldThrow",
--     ProjectileName = "ShieldThrow",
--     ProjectileProperty = "DetonateGraphic",
--     ChangeValue = "ShieldThrowTrailMirage-Artemis",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "GunGrenadeToss",
--     WeaponProperty = "FireFx",
--     ChangeValue = "SwordSwipeAFlipped-Artemis",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponName = "GunGrenadeToss",
--     ProjectileProperty = "StartFx",
--     ChangeValue = "SwordSwipeA-Emitter-Artemis",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     TraitName = "SpearTeleportTrait",
--     WeaponName = "SpearRushWeapon",
--     ProjectileName = "SpearRushWeapon",
--     ProjectileProperty = "DetonateGraphic",
--     ChangeValue = "SpearRushTrailFx-Artemis",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     WeaponNames = {"FistWeaponSpecial", "FistWeaponSpecialDash"},
--     WeaponProperty = "FireFx",
--     ChangeValue = "FistFxUppercutDirectionalArtemis",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     TraitName = "GunLoadedGrenadeTrait",
--     WeaponNames = {"GunGrenadeToss"},
--     ProjectileProperty = "Graphic",
--     ChangeValue = "GunGrenadeLuciferOrb-Artemis",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     TraitName = "GunLoadedGrenadeTrait",
--     WeaponNames = {"GunGrenadeToss"},
--     ProjectileProperty = "GroupName",
--     ChangeValue = "FX_Standing_Add",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     TraitName = "GunLoadedGrenadeTrait",
--     WeaponNames = {"GunBombWeapon"},
--     ProjectileProperty = "DetonateGraphic",
--     ChangeValue = "ZagGrenadeExplosionArtemis",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     TraitName = "GunLoadedGrenadeTrait",
--     WeaponName = "GunGrenadeToss",
--     ProjectileProperty = "StartFx",
--     ChangeValue = "null",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     TraitName = "GunLoadedGrenadeTrait",
--     WeaponName = "GunGrenadeToss",
--     WeaponProperty = "FireFx",
--     ChangeValue = "null",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     TraitName = "GunLoadedGrenadeTrait",
--     WeaponNames = {"GunBombImmolation"},
--     ProjectileProperty = "DetonateGraphic",
--     ChangeValue = "LuciferOrbAoE-Artemis",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     TraitName = "BowMarkHomingTrait",
--     WeaponNames = {"BowSplitShot"},
--     ProjectileProperty = "Graphic",
--     ChangeValue = "BowWeaponArrow-Artemis-SplitShot-Alt01",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     TraitName = "BowLoadAmmoTrait",
--     WeaponNames = {"BowSplitShot"},
--     ProjectileProperty = "Graphic",
--     ChangeValue = "BowWeaponArrow-Artemis-SplitShot-Alt02",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     TraitName = "FistDetonateTrait",
--     WeaponNames = {"FistWeaponSpecial"},
--     WeaponProperty = "FireFx",
--     ChangeValue = "ClawSwipeUppercut-Artemis",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     TraitName = "FistDetonateTrait",
--     WeaponNames = {"FistWeaponSpecialDash"},
--     WeaponProperty = "FireFx",
--     ChangeValue = "ClawSwipeUppercutSpecial-Artemis",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }, {
--     TraitName = "FistTeleportSpecialTrait",
--     WeaponNames = {"FistWeaponSpecial", "FistWeaponSpecialDash"},
--     WeaponProperty = "FireFx",
--     ChangeValue = "FistFxUppercutDirectionalArtemis_FlashKick",
--     ChangeType = "Absolute",
--     ExcludeLinked = true
-- }}
--#endregion

mod.GUIFlameGlow = { "Name", "InheritFrom", "Color" }
mod.GUISymbol = { "Name", "InheritFrom", "ChildAnimation", "Scale", "CreateAnimations", "Color" }
mod.GUIBackingB = { "Name", "InheritFrom", "ChildAnimation", "Scale", "Color" }
mod.GUIBackingC = { "Name", "InheritFrom", "ChildAnimation", "Color" }
mod.GUIIcon = { "Name", "InheritFrom", "EndFrame", "StartFrame", "FilePath" }
--
-- GUiAnimations.sjson
mod.BoonSymbolGlow_Artemis = sjson.to_object({
	Name = "BoonSymbolGlow_Artemis",
	InheritFrom = "BoonSymbolGlow",
	Color = {
		Red = 1.000,
		Green = 0.329,
		Blue = 0.173,
	},
}, mod.GUIFlameGlow)

mod.BoonSymbolFlare_Artemis = sjson.to_object({
	Name = "BoonSymbolFlare_Artemis",
	InheritFrom = "BoonSymbolFlare",
	Color = {
		Red = 1.000,
		Green = 0.235,
		Blue = 0.000,
	},
}, mod.GUIFlameGlow)

mod.BoonSymbolArtemis = sjson.to_object({
	Name = "BoonSymbolArtemis",
	InheritFrom = "BoonBackingA",
	ChildAnimation = "BoonBackingB_Artemis",
	Scale = 0.5,
	CreateAnimations = { {
		Name = "BoonSymbolGlow_Artemis",
	}, {
		Name = "BoonSymbolFlare_Artemis",
	} },
	Color = {
		Red = 1.000,
		Green = 0.800,
		Blue = 0.000,
	},
}, mod.GUISymbol)

mod.BoonBackingB_Artemis = sjson.to_object({
	Name = "BoonBackingB_Artemis",
	InheritFrom = "BoonBackingB",
	ChildAnimation = "BoonBackingC_Artemis",
	Scale = 0.5,
	Color = {
		Red = 1.000,
		Green = 0.953,
		Blue = 0.631,
	},
}, mod.GUIBackingB)

mod.BoonBackingC_Artemis = sjson.to_object({
	Name = "BoonBackingC_Artemis",
	InheritFrom = "BoonBackingC",
	ChildAnimation = "BoonSymbolArtemisIcon",
	Color = {
		Red = 1.000,
		Green = 0.392,
		Blue = 0.749,
	},
}, mod.GUIBackingC)

mod.BoonSymbolArtemisIcon = sjson.to_object({
	Name = "BoonSymbolArtemisIcon",
	InheritFrom = "BoonSymbolBase",
	EndFrame = 1,
	StartFrame = 1,
	FilePath = "GUI\\Screens\\BoonSelectSymbols\\Artemis2",
}, mod.GUIIcon)

-- GUI Hook
table.insert(data.Animations, mod.BoonSymbolGlow_Artemis)
table.insert(data.Animations, mod.BoonSymbolFlare_Artemis)
table.insert(data.Animations, mod.BoonSymbolArtemis)
table.insert(data.Animations, mod.BoonBackingB_Artemis)
-- Game already has these 2
table.insert(data.Animations, mod.BoonBackingC_Artemis)
table.insert(data.Animations, mod.BoonSymbolArtemisIcon)

-- Stat Line Stuff - TraitTextFile
table.insert(data.Texts, mod.ArtemisWeaponBoon_Text)
table.insert(data.Texts, mod.ArtemisSpecialBoon_Text)

mod.ArtemisWeaponBoon_Text = sjson.to_object({
	Id = "AttackBonusStatDisplay1",
	InheritFrom = "BaseStatLine",
	DisplayName = "{!Icons.Bullet}{#PropertyFormat}Attack Damage:",
	Description = "{#UpgradeFormat}{$TooltipData.ExtractData.TooltipDamage:F}",
}, mod.Order)

mod.ArtemisSpecialBoon_Text = sjson.to_object({
	Id = "SpecialBonusStatDisplay1",
	InheritFrom = "BaseStatLine",
	DisplayName = "{!Icons.Bullet}{#PropertyFormat}Special Damage:",
	Description = "{#UpgradeFormat}{$TooltipData.ExtractData.TooltipDamage:F}",
}, mod.Order)

-- Alternative SJSON hook used while trying to troubleshoot artemis arrows being broken
sjson.hook(mod.ProjectileDataFile, function(data)
	local order = {}
	local projectile = {}
	for _, v in ipairs(data.Projectiles) do
		if v.Name == "ArtemisSupportingFire" then
			projectile = game.DeepCopyTable(v)
			order = sjson.get_order(v)
		end
	end

	projectile.Name = "ArtemisSupportingFireSprint"
	local projectileEntry = sjson.to_object(projectile, order)

	table.insert(data.Projectiles, projectileEntry)
end)

-- Jowday Messing arround with other projectiles
sjson.hook(mod.ProjectileDataFile, function(data)
	local order = {}
	local projectile = {}
	for _, v in ipairs(data.Projectiles) do
		if v.Name == "ArtemisSupportingFire" then
			--v.Thing.Graphic = "ArtemisRangedArrowheadLegendary"
			projectile = game.DeepCopyTable(v)
			order = sjson.get_order(v)
		end
	end

	projectile.Name = "ArtemisSupportingFireSprint"
	projectile.Thing.Graphic = "HecatePolymorphProjectile"
	projectile.Thing.Color = { Red = 0.78, Green = 1.0, Blue = 0.11, Opacity = 1.0 }
	projectile.Thing.Scale = 0.33
	local projectileEntry = sjson.to_object(projectile, order)

	table.insert(data.Projectiles, projectileEntry)
	--table.insert(data.Projectiles, mod.ArtemisSupportingFireSprint)
end)

-- Non-working dart copy, looked cool tho
mod.ArtemisDart = sjson.to_object({
	Name = "ArtemisDart",
	ChildAnimation = "DartTrapWeaponGlow",
	FilePath = "Particles\\particle_cone_spike",
	GroupName = "FX_Standing_Add",
	VisualFx = "DartTrapTrail",
	AddColor = true,
	EndFrame = 1,
	NumFrames = 1,
	StartFrame = 1,
	OriginX = 63.0,
	OriginY = 10.0,
	Scale = 1.66,
	Ambient = 0.0,
	VisualFxDistanceMax = 90.0,
	VisualFxDistanceMin = 80.0,
	Color = { Red = 0.78, Green = 1.0, Blue = 0.11 },
}, { "Name", "ChildAnimation", "FilePath", "GroupName", "VisualFx", "AddColor", "EndFrame", "NumFrames", "StartFrame", "OriginX", "OriginY", "Scale", "Ambient", "VisualFxDistanceMax", "VisualFxDistanceMin", "Color" })

-- Updating Descriptions
-- local function updateArtemisDescription(data, updateAttack, updateSpecial)
-- 	print("Updating Artemis Description")
-- 	for _, v in ipairs(data.Texts) do
-- 		if updateAttack and v.Id == "ArtemisWeaponBoon" then
-- 			if updateAttack then
-- 				print("Applying scaling description to weapon boon")
-- 				v.Description = "Your {$Keywords.Attack} is stronger, with a chance to deal {$Keywords.Crit} damage."
-- 			else
-- 				print("Applying standard description to weapon boon")
-- 				v.Description = "Your {$Keywords.Attack} is stronger, with a {#AltUpgradeFormat}{$TooltipData.ExtractData.TooltipCritChance:P} {#Prev} chance to deal {$Keywords.Crit} damage."
-- 			end
-- 		end

-- 		if updateSpecial and v.Id == "ArtemisSpecialBoon" then
-- 			if updateSpecial then
-- 				print("Applying scaling description to special boon")
-- 				v.Description = "Your {$Keywords.Special} is stronger, with a chance to deal {$Keywords.Crit} damage."
-- 			else
-- 				print("Applying standard description to special boon")
-- 				v.Description = "Your {$Keywords.Special} is stronger, with a {#AltUpgradeFormat}{$TooltipData.ExtractData.TooltipCritChance:P} {#Prev} chance to deal {$Keywords.Crit} damage."
-- 			end
-- 		end
-- 	end
-- end

local mods = rom.mods
local Generalist = mods["zannc-Generalist"]

function ConfigureArtemisBoon(scaleAttack, scaleSpecial)
	-- Weapon Boon
	if scaleAttack then
		-- game.TraitData.ArtemisWeaponBoon.StatLines = { "CritChanceStatDisplay1", "AttackDamageStatDisplay1" } -- Commenting this out till sjson can reset on room without reloading all mods, this is default now
		game.TraitData.ArtemisWeaponBoon.AddOutgoingCritModifiers.Chance.NoScaling = false

		-- Check for Generalist Scaling cause loadorder
		if Generalist then
			if Generalist.config.RemoveDiminishingReturns then
				game.TraitData.ArtemisWeaponBoon.AddOutgoingCritModifiers.Chance.MinMultiplier = nil
				game.TraitData.ArtemisWeaponBoon.AddOutgoingCritModifiers.Chance.IdenticalMultiplier = nil
			else
				-- You kinda have to do this manually to find a sweet spot
				game.TraitData.ArtemisWeaponBoon.AddOutgoingCritModifiers.Chance.MinMultiplier = 0.07
				game.TraitData.ArtemisWeaponBoon.AddOutgoingCritModifiers.Chance.IdenticalMultiplier = { Value = -0.7, DiminishingReturnsMultiplier = 0.7 }
			end
		end
	else
		-- game.TraitData.ArtemisWeaponBoon.StatLines = { "AttackDamageStatDisplay1" } -- Commenting this out till sjson can reset on room without reloading all mods
		game.TraitData.ArtemisWeaponBoon.AddOutgoingCritModifiers.Chance.NoScaling = true
		game.TraitData.ArtemisWeaponBoon.AddOutgoingCritModifiers.Chance.MinMultiplier = nil
		game.TraitData.ArtemisWeaponBoon.AddOutgoingCritModifiers.Chance.IdenticalMultiplier = nil
	end

	-- Special Boon
	if scaleSpecial then
		-- game.TraitData.ArtemisSpecialBoon.StatLines = { "CritChanceStatDisplay1", "SpecialDamageStatDisplay1" } -- Commenting this out till sjson can reset on room without reloading all mods, this is default now
		game.TraitData.ArtemisSpecialBoon.AddOutgoingCritModifiers.Chance.NoScaling = false

		-- Check for Generalist Scaling cause loadorder
		if Generalist then
			if Generalist.config.RemoveDiminishingReturns then
				game.TraitData.ArtemisSpecialBoon.AddOutgoingCritModifiers.Chance.MinMultiplier = nil
				game.TraitData.ArtemisSpecialBoon.AddOutgoingCritModifiers.Chance.IdenticalMultiplier = nil
			else
				-- You kinda have to do this manually to find a sweet spot
				game.TraitData.ArtemisSpecialBoon.AddOutgoingCritModifiers.Chance.MinMultiplier = 0.05
				game.TraitData.ArtemisSpecialBoon.AddOutgoingCritModifiers.Chance.IdenticalMultiplier = { Value = -0.55, DiminishingReturnsMultiplier = 0.55 }
			end
		end
	else
		-- game.TraitData.ArtemisWeaponBoon.StatLines = { "SpecialDamageStatDisplay1" } -- Commenting this out till sjson can reset on room without reloading all mods
		game.TraitData.ArtemisSpecialBoon.AddOutgoingCritModifiers.Chance.NoScaling = true
		game.TraitData.ArtemisSpecialBoon.AddOutgoingCritModifiers.Chance.MinMultiplier = nil
		game.TraitData.ArtemisSpecialBoon.AddOutgoingCritModifiers.Chance.IdenticalMultiplier = nil
	end

	-- sjson.hook(mod.TraitTextFile, function(data)
	--     print("Calling sjson hook")
	--     updateArtemisDescription(data, scaleAttack, scaleSpecial)
	-- end)
end

ModUtil.LoadOnce(function()
	ConfigureArtemisBoon(config.ArtemisAttackCritScale, config.ArtemisSpecialCritScale)
end)

-- game.OnAnyLoad({
-- 	function()
--         rom.data.reload_game_data(
--             sjson.hook(mod.TraitTextFile, function(data)
--                 print("Calling sjson hook")
--                 updateArtemisDescription(data, config.ArtemisAttackCritScale, config.ArtemisSpecialCritScale)
--             end)
--         )
-- 	end,
-- })
