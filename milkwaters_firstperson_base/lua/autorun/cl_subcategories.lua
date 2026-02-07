if CLIENT then
	local function DoGenericSpawnmenuRightclickMenu(self)
		local menu = DermaMenu()

		menu:AddOption("#spawnmenu.menu.copy", function()
			SetClipboardText(self:GetSpawnName())
		end):SetIcon("icon16/page_copy.png")

		if isfunction(self.OpenMenuExtra) then
			self:OpenMenuExtra(menu)
		end

		if not IsValid(self:GetParent()) or not self:GetParent().GetReadOnly or not self:GetParent():GetReadOnly() then
			menu:AddSpacer()

			menu:AddOption("#spawnmenu.menu.delete", function()
				self:Remove()
				hook.Run("SpawnlistContentChanged")
			end):SetIcon("icon16/bin_closed.png")
		end

		menu:Open()
	end

	local function AddWeaponToCategory(propPanel, ent)
		return spawnmenu.CreateContentIcon(ent.ScriptedEntityType or "weapon", propPanel, {
			nicename = ent.PrintName or ent.ClassName,
			spawnname = ent.ClassName,
			material = ent.IconOverride or ("entities/" .. ent.ClassName .. ".png"),
			admin = ent.AdminOnly
		})
	end

	spawnmenu.AddContentType("mb_weapon", function(container, obj)
		if not obj.material then return end
		if not obj.nicename then return end
		if not obj.spawnname then return end

		local icon = vgui.Create("ContentIcon", container)
		icon:SetContentType("weapon")
		icon:SetSpawnName(obj.spawnname)
		icon:SetName(obj.nicename)
		icon:SetMaterial(obj.material)
		icon:SetAdminOnly(obj.admin)
		icon:SetColor(Color(135, 206, 250, 255))

		local SWEPinfo = weapons.Get(obj.spawnname)
		local toolTip = language.GetPhrase(obj.nicename)

		if not SWEPinfo then
			SWEPinfo = list.Get("Weapon")[obj.spawnname]
		end

		if SWEPinfo then
			toolTip = toolTip .. "\n"
			if SWEPinfo.Description and SWEPinfo.Description != "" then
				toolTip = SWEPinfo.Description
			end
		end

		icon:SetTooltip(toolTip)

		icon.DoClick = function()
			RunConsoleCommand("gm_giveswep", obj.spawnname)
			surface.PlaySound("ui/buttonclickrelease.wav")
		end

		icon.DoMiddleClick = function()
			RunConsoleCommand("gm_spawnswep", obj.spawnname)
			surface.PlaySound("ui/buttonclickrelease.wav")
		end

		icon.OpenMenuExtra = function(self, menu)
			menu:AddOption("#spawnmenu.menu.spawn_with_toolgun", function()
				RunConsoleCommand("gmod_tool", "creator")
				RunConsoleCommand("creator_type", "3")
				RunConsoleCommand("creator_name", obj.spawnname)
			end):SetIcon("icon16/brick_add.png")

			if self:GetIsNPCWeapon() then
				local opt = menu:AddOption("#spawnmenu.menu.use_as_npc_gun", function()
					RunConsoleCommand("gmod_npcweapon", self:GetSpawnName())
				end)

				if self:GetSpawnName() == GetConVarString("gmod_npcweapon") then
					opt:SetIcon("icon16/monkey_tick.png")
				else
					opt:SetIcon("icon16/monkey.png")
				end
			end
		end

		icon.OpenMenu = DoGenericSpawnmenuRightclickMenu

		if IsValid(container) then
			container:Add(icon)
		end

		return icon
	end)

	hook.Add("PopulateWeapons", "MB_SubCategories", function(pnlContent, tree, anode)
		local cvar = 1

		timer.Simple(0, function()
			local Weapons = list.Get("Weapon")
			local Categorised = {}
			local MWCats = {}

			for k, weapon in pairs(Weapons) do
				if not weapon.Spawnable then continue end
				if not weapons.IsBasedOn(k, "weapon_tf2milkbase") then continue end

				local Category = weapon.Category or "Other2"
				local WepTable = weapons.Get(weapon.ClassName)

				if not isstring(Category) then Category = tostring(Category) end

				local SubCategories = { "Other" }

				if cvar == 1 and WepTable and WepTable.SubCatType then
					if istable(WepTable.SubCatType) then
						-- multiple subcategories
						SubCategories = {}
						for _, sub in ipairs(WepTable.SubCatType) do
							table.insert(SubCategories, tostring(sub))
						end
					else
						-- single subcategory
						SubCategories = { tostring(WepTable.SubCatType) }
					end
				end

				local wep = weapons.Get(weapon.ClassName)
				weapon.Quality = wep.SubCatTier

				Categorised[Category] = Categorised[Category] or {}
				for _, sub in ipairs(SubCategories) do
					Categorised[Category][sub] = Categorised[Category][sub] or {}
					table.insert(Categorised[Category][sub], weapon)
				end
				MWCats[Category] = true
			end

			for _, node in pairs(tree:Root():GetChildNodes()) do
				if not MWCats[node:GetText()] then continue end

				local catSubcats = Categorised[node:GetText()]
				if not catSubcats then continue end

				node.DoPopulate = function(self)
					if self.PropPanel then return end

					self.PropPanel = vgui.Create("ContentContainer", pnlContent)
					self.PropPanel:SetVisible(false)
					self.PropPanel:SetTriggerSpawnlistChange(false)

					for subcatName, subcatWeps in SortedPairs(catSubcats) do

						if table.Count(catSubcats) > 1 then
							local label = vgui.Create("ContentHeader", container)
							label:SetText(subcatName)
							self.PropPanel:Add(label)
						end
						
						-- sort alphabetically in reverse because garrys mod
						table.sort(subcatWeps, function(a, b)
							return a.PrintName < b.PrintName
						end)

						for _, ent in ipairs(subcatWeps) do
							spawnmenu.CreateContentIcon("mb_weapon", self.PropPanel, {
								nicename = ent.PrintName or ent.ClassName,
								spawnname = ent.ClassName,
								material = ent.IconOverride or "entities/" .. ent.ClassName .. ".png",
								admin = ent.AdminOnly,
								quality = ent.Quality
							})
						end
					end
				end

				node.DoClick = function(self)
					self:DoPopulate()
					pnlContent:SwitchPanel(self.PropPanel)
				end
			end

			local FirstNode = tree:Root():GetChildNode(0)
			if IsValid(FirstNode) then
				FirstNode:InternalDoClick()
			end
		end)
	end)

	local function BuildWeaponCategories()
		local weapons = list.Get("Weapon")
		local Categorised = {}

		for k, weapon in pairs(weapons) do
			if not weapon.Spawnable then continue end

			local Category = weapon.Category or "Other"
			if not isstring(Category) then Category = tostring(Category) end

			Categorised[Category] = Categorised[Category] or {}
			table.insert(Categorised[Category], weapon)
		end
		
		return Categorised
	end

	local function AddCategory(tree, cat)
		local CustomIcons = list.Get("ContentCategoryIcons")
		local node = tree:AddNode(cat, CustomIcons[cat] or "icon16/gun.png")
		tree.Categories[cat] = node

		node.DoPopulate = function(self)
			if IsValid(self.PropPanel) then return end

			self.PropPanel = vgui.Create("ContentContainer", tree.pnlContent)
			self.PropPanel:SetVisible(false)
			self.PropPanel:SetTriggerSpawnlistChange(false)

			local weps = BuildWeaponCategories()[cat]

			for k, ent in SortedPairsByMemberValue(weps, "PrintName") do
				spawnmenu.CreateContentIcon(ent.ScriptedEntityType or "weapon", self.PropPanel, {
					nicename = ent.PrintName or ent.ClassName,
					spawnname = ent.ClassName,
					material = ent.IconOverride or ("entities/" .. ent.ClassName .. ".png"),
					admin = ent.AdminOnly
				})
			end
		end

		node.DoClick = function(self)
			self:DoPopulate()
			tree.pnlContent:SwitchPanel(self.PropPanel)
		end

		node.OnRemove = function(self)
			if IsValid(self.PropPanel) then
				self.PropPanel:Remove()
			end
		end

		return node
	end

	local function AutorefreshWeaponToSpawnmenu(weapon, name)
		local swepTab = g_SpawnMenu.CreateMenu:GetCreationTab("#spawnmenu.category.weapons")
		if not swepTab or not swepTab.ContentPanel or not IsValid(swepTab.Panel) then return end

		local tree = swepTab.ContentPanel.ContentNavBar.Tree
		if not tree.Categories then return end

		local newCategory = weapon.Category or "Other"

		for cat, catPnl in pairs(tree.Categories) do
			if not IsValid(catPnl.PropPanel) then continue end

			for _, icon in pairs(catPnl.PropPanel.IconList:GetChildren()) do
				if icon:GetName() != "ContentIcon" then continue end

				if icon:GetSpawnName() == name then
					local added = false

					if cat == newCategory then
						local newIcon = AddWeaponToCategory(catPnl.PropPanel, weapon)
						newIcon:MoveToBefore(icon)
						added = true
					end

					icon:Remove()
					if added then return end
				end
			end
		end

		if IsValid(tree.Categories[newCategory]) then
			if IsValid(tree.Categories[newCategory].PropPanel) then
				AddWeaponToCategory(tree.Categories[newCategory].PropPanel, weapon)
			end
		else
			AddCategory(tree, newCategory)
		end
	end

	hook.Add("InitPostEntity", "MB_OverrideSpawnmenuReloadSWEP", function()
		hook.Add("PreRegisterSWEP", "spawnmenu_reload_swep", function(weapon, name)
			if not weapon.Spawnable or weapons.IsBasedOn(name, "weapon_tf2_milkbase") then return end

			timer.Simple(0, function()
				AutorefreshWeaponToSpawnmenu(weapon, name)
			end)
		end)
	end)
end