/*
	Author: IT07

	Description:
	launches VEMFr (You don't say?)
*/

["Launcher", 2, format["/// STARTING v%1 \\\", getNumber (configFile >> "CfgPatches" >> "exile_vemf_reloaded" >> "version")]] spawn VEMFr_fnc_log;
uiNamespace setVariable ["VEMFrUsedLocs", []];
uiNamespace setVariable ["VEMFrHcLoad", []];

[] spawn VEMFr_fnc_checkLoot; // Check loot tables if enabled
[] spawn VEMFr_fnc_missionTimer; // Launch mission timer
[] spawn VEMFr_fnc_spawnStaticAI; // Launch Static AI spawner
west setFriend [independent, 0];
independent setFriend [west, 0];

[] spawn
{
	uiSleep 4;
	_overridesToRPT = "overridesToRPT" call VEMFr_fnc_getSetting;
	if (_overridesToRPT isEqualTo 1) then
	{
		_root = configProperties [configFile >> "CfgVemfReloaded" >> "CfgSettingsOverride", "true", false];
		if (count _root > 0) then
		{
			{
				if (isClass _x) then
				{
					_classLv1Name = configName _x;
					_levelOne = configProperties [configFile >> "CfgVemfReloaded" >> "CfgSettingsOverride" >> _classLv1Name, "true", false];
					if (count _levelOne > 0) then
					{
						{
							if (isClass _x) then
							{
								_classLv2Name = configName _x;
								_levelTwo = configProperties [configFile >> "CfgVemfReloaded" >> "CfgSettingsOverride" >> _classLv1Name >> _classLv2Name, "true", false];
								if (count _levelTwo > 0) then
								{
									{
										if not(isClass _x) then
										{
											["overridesToRPT", 1, format["Overriding 'CfgVemfReloaded >> %1 >> %2 >> %3'", _classLv1Name, _classLv2Name, configName _x]] spawn VEMFr_fnc_log;
										};
									} forEach _levelTwo;
								};
							};
							if not(isClass _x) then
							{
								["overridesToRPT", 1, format["Overriding 'CfgVemfReloaded >> %1 >> %2", _classLv1Name, configName _x]] spawn VEMFr_fnc_log;
							};
						} forEach _levelOne;
					};
				};
				if not(isClass _x) then
				{
					["overridesToRPT", 1, format["Overriding 'CfgVemfReloaded >> %1'", configName _x]] spawn VEMFr_fnc_log;
				};
			} forEach _root;
		};
	};
};
