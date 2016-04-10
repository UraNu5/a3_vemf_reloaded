/*
	DynamicLocationInvasion by Vampire, rewritten by IT07
*/

if isNil"VEMFrInvasionCount" then
{
	VEMFrInvasionCount = 0;
};

if (VEMFrInvasionCount < (([["DynamicLocationInvasion"],["maxInvasions"]] call VEMFr_fnc_getSetting) select 0)) then
{
	VEMFrInvasionCount = VEMFrInvasionCount + 1;
	private ["_settings","_grpCount","_groupUnits","_skipDistance","_loc","_hasPlayers","_spawned","_grpArr","_unitArr","_done","_boxes","_box","_chute","_colors","_lightType","_light","_smoke"];
	// Define _settings
	_settings = [["DynamicLocationInvasion"],["groupCount","groupUnits","maxDistance","maxDistancePrefered","skipDistance","marker","parachuteCrate","markCrateVisual","markCrateOnMap","announce","streetLights","streetLightsRestore","streetLightsRange","allowCrateLift"]] call VEMFr_fnc_getSetting;
	_grpCount = _settings select 0;
	_groupUnits = _settings select 1;
	_range = _settings select 2;
	_maxPref = _settings select 3;
	_skipDistance = _settings select 4;
	_useMissionMarker = _settings select 5;
	_useChute = (_settings select 6) select 0;
	_crateAltitude = (_settings select 6) select 1;
	_markCrateVisual = _settings select 7;
	_markCrateOnMap = _settings select 8;
	_announce = _settings select 9;
	_streetLights = _settings select 10;
	_streetLightsRestore = _settings select 11;
	_streetLightsRange = _settings select 12;
	_allowCrateLift = _settings select 13;

	_loc = ["loc", false, position (selectRandom allPlayers), _skipDistance, _maxPref, _skipDistance, "DynamicLocationInvasion"] call VEMFr_fnc_findPos;
	if (_loc isEqualTypeArray ["",[]]) then
	{
		_locName = _loc select 0;
		_locPos = _loc select 1;
		if (_locName isEqualTo "") then { _locName = "Area"; };
		["DynamicLocationInvasion", 1, format["Invading %1...", _locName]] spawn VEMFr_fnc_log;
		VEMFrInvasionCount = VEMFrInvasionCount + 1;
		// Send message to all players
		private ["_mode"];
		_mode = "aiMode" call VEMFr_fnc_getSetting;
		_randomModes = ([["DynamicLocationInvasion"],["randomModes"]] call VEMFr_fnc_getSetting) select 0;
		if (_randomModes isEqualTo 1) then
		{
			_mode = selectRandom [0,1,2];
		};
		if (_announce isEqualTo 1) then
		{
			if (_mode isEqualTo 0) then
			{
				[[format["Plundering groups have invaded %1 @ %2", _locName, mapGridPosition _locPos], "NEW INVASION"], ""] spawn VEMFr_fnc_broadCast;
			};
			if (_mode isEqualTo 1) then
			{
				[[format["%1 Police forces are now controlling %2 @ %3", worldName, _locName, mapGridPosition _locPos], "NEW MISSION"], ""] spawn VEMFr_fnc_broadCast;
			};
			if (_mode isEqualTo 2) then
			{
				[[format["%1 S.W.A.T. teams are now raiding %2 @ %3", worldName, _locName, mapGridPosition _locPos], "NEW RAID"], ""] spawn VEMFr_fnc_broadCast;
			};
		};
		private["_marker"];
		if (_useMissionMarker isEqualTo 1) then
		{ // Create/place the marker if enabled
			_marker = createMarker [format["VEMFr_DynaLocInva_ID%1", random 9000], _locPos];
			_marker setMarkerShape "ICON";
			_marker setMarkerType "o_unknown";
			switch true do
			{
				case (_mode isEqualTo 0):
				{
					_marker setMarkerColor "ColorEAST";
				};
				case (_mode isEqualTo 1):
				{
					_marker setMarkerColor "ColorWEST";
				};
				case (_mode isEqualTo 2):
				{
					_marker setMarkerColor "ColorBlack";
				};
			};
		};

		// If enabled, kill all the lights
		if (_streetLights isEqualTo 0) then
		{
			private ["_all"];
			_all = nearestObjects [_locPos, ["Lamps_Base_F","PowerLines_base_F","Land_PowerPoleWooden_L_F"], _streetLightsRange];
			{
				if (damage _x < 0.95) then
				{
					_x setDamage 0.95;
					uiSleep 0.1;
				};
			} forEach _all;
		};

		// Usage: POSITION, Radius
		_playerNear = [_locPos, 800] call VEMFr_fnc_waitForPlayers;
		if _playerNear then
		{
			// Player is Near, so Spawn the Units
			_spawned = [_locPos, ((_grpCount select 0) + round random ((_grpCount select 1) - (_grpCount select 0))), ((_groupUnits select 0) + round random ((_groupUnits select 1) - (_groupUnits select 0))), _mode, "DynamicLocationInvasion"] call VEMFr_fnc_spawnInvasionAI;
			if (_spawned isEqualType []) then
			{
				if (_spawned isEqualTypeArray [[],[]]) then
				{
					private ["_units","_cal50s"];
					_units = _spawned select 0;
					_groups = _spawned select 1;
					{
						[_x] spawn VEMFr_fnc_signAI;
					} forEach _groups;
					_cal50s = _spawned select 2;

					private ["_heliUnits"];
					_heliPatrolSettings = ([["DynamicLocationInvasion"],["heliPatrol"]] call VEMFr_fnc_getSetting) select 0;
					if (_heliPatrolSettings select 0 isEqualTo 1) then
					{ // If heliPatrol setting is enabled
						["DynamicLocationInvasion", 1, format["Adding a heli patrol to the invasion of %1 at %2", _locName, mapGridPosition _locPos]] spawn VEMFr_fnc_log;
						_heli = createVehicle [selectRandom (_heliPatrolSettings select 1), _locPos, [], 50, "FLY"];
						_heli engineOn true; // Just to make sure
						_spawnHeliGroup = [_locPos, 1, (((count allTurrets _heli) + (_heli emptyPositions "cargo") + (_heli emptyPositions "commander")) + 1), _mode, "DynamicLocationInvasion"] call VEMFr_fnc_spawnVEMFrAI;
						if (_spawnHeliGroup isEqualType []) then
						{
							_heliGroup = _spawnHeliGroup select 0;
							_heliUnits = units _heliGroup;
							{
								_x moveInAny _heli;
								removeBackpack _x;
								_x addBackpack "B_Parachute";
								_units pushBack _x;
							} forEach _heliUnits;

							_loiterWaypoint = _heliGroup addWaypoint [_locPos, 50, 1];
							_loiterWaypoint setWaypointType "LOITER";
							_loiterWaypoint setWaypointSpeed "LIMITED";
							_loiterWaypoint setWaypointCombatMode "RED";
							_loiterWaypoint setWaypointBehaviour "AWARE";
							_loiterWaypoint setWaypointLoiterType "CIRCLE_L";
							_loiterWaypoint setWaypointLoiterRadius 25;
							_heliGroup setCurrentWaypoint _loiterWaypoint;

							[_heliGroup] spawn VEMFr_fnc_signAI;
						};
					};

					// Place mines if enabled
					private ["_minesPlaced","_mines"];
					_mines = [["DynamicLocationInvasion"],["mines"]] call VEMFr_fnc_getSetting param [0, 0, [0]];
					if (_mines > 0) then
					{
						_minesPlaced = [_locPos, 5, 100] call VEMFr_fnc_placeMines param [0, [], [[]]];
						if (count _minesPlaced > 0) then
						{
							["DynamicLocationInvasion", 1, format["Successfully placed mines at %1", _locName]] spawn VEMFr_fnc_log;
						};
						if (count _minesPlaced isEqualto 0) then
						{
							["DynamicLocationInvasion", 0, format["Failed to place mines at %1", _locName]] spawn VEMFr_fnc_log;
							_minesPlaced = nil;
						};
					};

					// Wait for Mission Completion
					_done = [_loc select 0, _locPos, _units, _skipDistance] call VEMFr_fnc_waitForMissionDone;
					_usedLocs = uiNamespace getVariable "VEMFrUsedLocs";
					_index = _usedLocs find [_loc select 0, _locPos];
					if (_index > -1) then
					{
						_usedLocs deleteAt _index;
					};
					if _done then
					{
						// Broadcast
						if (_announce isEqualTo 1) then
						{
							if (_mode isEqualTo 0) then
							{
								[[format["%1 @ %2 has been cleared of %3 bad guys", _locName, mapGridPosition (_locPos), worldName], "COMPLETED"], ""] spawn VEMFr_fnc_broadCast;
							};
							if (_mode isEqualTo 1) then
							{
								[[format["%1 @ %2 has been cleared of %3 Police forces", _locName, mapGridPosition (_locPos), worldName], "CLEARED"], ""] spawn VEMFr_fnc_broadCast;
							};
							if (_mode isEqualTo 2) then
							{
								[[format["S.W.A.T. raid on %1 @ %2 has been eliminated", _locName, mapGridPosition (_locPos)], "DEFEATED"], ""] spawn VEMFr_fnc_broadCast;
							};
						};
						// Deal with the 50s
						if not isNil"_cal50s" then
						{
							private["_cal50sDelete"];
							_cal50sDelete = ([["DynamicLocationInvasion"],["cal50sDelete"]] call VEMFr_fnc_getSetting) select 0;
							if (_cal50sDelete > 0) then
							{
								{
									if (_cal50sDelete isEqualTo 1) then
									{
										deleteVehicle _x;
									};
									if (_cal50sDelete isEqualTo 2) then
									{
										_x setDamage 1;
									};
								} forEach _cal50s;
							};
						};
						// Choose a box
						_boxes = [["DynamicLocationInvasion"],["crateTypes"]] call VEMFr_fnc_getSetting;
						_box = (_boxes select 0) call BIS_fnc_selectRandom;
						_pos = [_locPos, 0, 100, 0, 0, 300, 0] call bis_fnc_findSafePos;
						private ["_crate"];
						if (_useChute isEqualTo 1) then
						{
							_chute = createVehicle ["I_Parachute_02_F", _pos, [], 0, "FLY"];
							_chute setPos [getPos _chute select 0, getPos _chute select 1, _crateAltitude];
							_chute enableSimulationGlobal true;

							if not isNull _chute then
							{
								_crate = createVehicle [_box, getPos _chute, [], 0, "NONE"];
								_crate allowDamage false;
								_crate enableSimulationGlobal true;
								_crate attachTo [_chute, [0,0,0]];
								if (_allowCrateLift isEqualTo 0) then
								{
									_crate enableRopeAttach false;
								};
								["DynamicLocationInvasion", 1, format ["Crate parachuted at: %1 / Grid: %2", (getPosATL _crate), mapGridPosition (getPosATL _crate)]] spawn VEMFr_fnc_log;
								_lootLoaded = [_crate] call VEMFr_fnc_loadLoot;
								if _lootLoaded then { ["DynamicLocationInvasion", 1, "Loot loaded successfully into parachuting crate"] spawn VEMFr_fnc_log };
							};
						};
						if (_useChute isEqualTo 0) then
						{
							_crate = createVehicle [_box, _pos, [], 0, "NONE"];
							_crate allowDamage false;
							if (_allowCrateLift isEqualTo 0) then
							{
								_crate enableRopeAttach false;
							};
							_lootLoaded = [_crate] call VEMFr_fnc_loadLoot;
							if _lootLoaded then { ["DynamicLocationInvasion", 1, "Loot loaded successfully into crate"] spawn VEMFr_fnc_log };
						};
						if (_markCrateVisual isEqualTo 1) then
						{
							uiSleep 0.5;
							// If night, attach a chemlight
							if (dayTime < 5 OR dayTime > 19) then
							{
								_colors = [["DynamicLocationInvasion"],["flairTypes"]] call VEMFr_fnc_getSetting param [0, [], [[]]];
								if (count _colors > 0) then
								{
									_lightType = selectRandom _colors;
									_light = _lightType createVehicle (position _crate);
									_light attachTo [_crate,[0,0,0]];
								};
							};
							// Attach smoke
							_colors = [["DynamicLocationInvasion"],["smokeTypes"]] call VEMFr_fnc_getSetting param [0, [], [[]]];
							if (count _colors > 0) then
							{
								_rndmColor = selectRandom _colors;
								_smoke = createVehicle [_rndmColor, getPos _crate, [], 0, "CAN_COLLIDE"];
								_smoke attachTo [_crate,[0,0,0]];
							};
						};
						if (_useChute isEqualTo 1) then
						{
							waitUntil { uiSleep 1; (((getPos _crate) select 2) < 7) };
							detach _crate;
						};
						if not isNil"_marker" then
						{
							deleteMarker _marker
						};
						VEMFrInvasionCount = VEMFrInvasionCount - 1;
						VEMFrMissionCount = VEMFrMissionCount - 1;

						// Put a marker on the crate if enabled
						if not isNil "_crate" then
						{
							if not isNull _crate then
							{
								if not ([getPos _crate, 2] call VEMFr_fnc_checkPlayerPresence) then
								{
									_addMarker = [["DynamicLocationInvasion"],["markCrateOnMap"]] call VEMFr_fnc_getSetting param [0, 1, [0]];
									if (_addMarker isEqualTo 1) then
									{
										private ["_crateMarker"];
										_crateMarker = createMarker [format["VEMF_lootCrate_ID%1", random 9000], position _crate];
										_crateMarker setMarkerShape "ICON";
										_crateMarker setMarkerType "mil_box";
										_crateMarker setMarkerColor "colorBlack";
										_crateMarker setMarkerText " Loot";
										[_crate, _crateMarker] spawn
										{
											_crate = _this select 0;
											_crateMarker = _this select 1;
											waitUntil { uiSleep 4; [getPos _crate, 3] call VEMFr_fnc_checkPlayerPresence };
											deleteMarker _crateMarker;
										};
									};
								};
							};
						};

						if isNil "_crate" then
						{
							["DynamicLocationInvasion", 0, "ERROR! _crate not found"] spawn VEMFr_fnc_log;
						};

						// Explode or remove the mines
						if not isNil"_minesPlaced" then
						{
							private ["_cleanMines"];
							_cleanMines = [["DynamicLocationInvasion"],["minesCleanup"]] call VEMFr_fnc_getSetting param [0, 1, [0]];
							if (_cleanMines isEqualTo 2) then
							{
								{
									if not isNull _x then
									{
										_x setDamage 1;
										uiSleep (2 + round random 2);
									};
								} forEach _minesPlaced;
								["DynamicLocationInvasion", 1, format["Successfully exploded all %1 mines at %2", count _minesPlaced, _locName]] spawn VEMFr_fnc_log;
								_minesPlaced = nil;
							};
							if (_cleanMines isEqualTo 1) then
							{
								{
									if not isNull _x then
									{
										deleteVehicle _x;
									};
								} forEach _minesPlaced;
								["DynamicLocationInvasion", 1, format["Successfully deleted all %1 mines at %2", count _minesPlaced, _locName]] spawn VEMFr_fnc_log;
								_minesPlaced = nil;
							};
						};

						// If enabled, fix all the lights
						if (_streetLightsRestore isEqualTo 1) then
						{
							private ["_all"];
							_all = nearestObjects [_locPos, ["Lamps_Base_F","PowerLines_base_F","Land_PowerPoleWooden_L_F"], _streetLightsRange];
							{
								if (damage _x > 0.94) then
								{
									_x setDamage 0;
									uiSleep 0.2;
								};
							} forEach _all;
						};
					};
				};
			};
			if not(_spawned isEqualType []) exitWith
			{
				VEMFrInvasionCount = VEMFrInvasionCount - 1;
				VEMFrMissionCount = VEMFrMissionCount - 1;
				[[format["Failed to spawn AI in %1 @ %2", _locName, mapGridPosition (_locPos)], "ERROR!"], ""] spawn VEMFr_fnc_broadCast;
			};
		};
		if not _playerNear then
		{
			["DynamicLocationInvasion", 1, format["Invasion of %1 timed out.", _locName]] spawn VEMFr_fnc_log;
			if not isNil"_marker" then
			{
				deleteMarker _marker
			};
			_usedLocs = uiNamespace getVariable "VEMFrUsedLocs";
			_index = _usedLocs find _loc;
			if (_index > -1) then
			{
				_usedLocs deleteAt _index;
			};
			VEMFrInvasionCount = VEMFrInvasionCount - 1;
			VEMFrMissionCount = VEMFrMissionCount - 1;
		};
	};
	if not(_loc isEqualType []) then
	{
		VEMFrInvasionCount = VEMFrInvasionCount - 1;
		VEMFrMissionCount = VEMFrMissionCount - 1;
	};
} else
{
	VEMFrMissionCount = VEMFrMissionCount - 1;
};
