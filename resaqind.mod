###################################################################################
###################################################################################
# SCROLL DOWN TO THE VERY BOTTOM IN ORDER TO SET THE OBJECTIVE FUNCTION AND ANYTHING YOU WANT TO DISPLAY
# DON'T CHANGE ANYTHING ELSE
###################################################################################
###################################################################################
# Don't change params here; do so in the data section at the very end of this file,
# or specify them in a different file.

#Sets
set Standard_Ores := {
	"Arkonor", "Bistot", "Crokite", "Dark Ochre",
	"Gneiss", "Hedbergite", "Hemorphite", "Jaspet",
	"Kernite", "Mercoxit", "Omber", "Plagioclase",
	"Pyroxeres", "Scordite", "Spodumain", "Veldspar"};

set Ice_Ores := {
	"Blue Ice", "Clear Icicle", "Dark Glitter", "Gelidus",
	"Glacial Mass", "Glare Crust", "Krystallos", "White Glaze"};
	
set Moon_Ores_Common := {"Cobaltite", "Euxenite", "Titanite", "Scheelite"};
set Moon_Ores_Exceptional := {"Xenotime", "Monazite", "Loparite", "Ytterbite"};
set Moon_Ores_Rare := {"Carnotite", "Zircon", "Pollucite", "Cinnabar"};
set Moon_Ores_Ubiquitous := {"Zeolites", "Sylvite", "Bitumens", "Coesite"};
set Moon_Ores_Uncommon := {"Otavite", "Sperrylite", "Vanadinite", "Chromite"};
set Moon_Ores := Moon_Ores_Common
	union Moon_Ores_Exceptional
	union Moon_Ores_Rare
	union Moon_Ores_Ubiquitous
	union Moon_Ores_Uncommon;
	
set Mineral_Ores := Standard_Ores union Moon_Ores;
set Compressable_Ores := Standard_Ores union Ice_Ores;
set Uncompressable_Ores := Moon_Ores;
set Ores := Mineral_Ores union Ice_Ores;

set Minerals := {
	"Tritanium", "Pyerite", "Mexallon", "Isogen",
	"Nocxium", "Zydrine", "Megacyte", "Morphite"
	};
	
set Ice_Isotopes := {"Helium Isotopes", "Hydrogen Isotopes", "Nitrogen Isotopes", "Oxygen Isotopes"};
set Ice_Products := {"Heavy Water", "Liquid Ozone", "Strontium Clathrates"} union Ice_Isotopes;


set Moongoo_Ubiquitous := {"Atmospheric Gases", "Evaporite Deposits", "Hydrocarbons", "Silicates"};
set Moongoo_Common := {"Cobalt", "Scandium", "Tungsten", "Titanium"};
set Moongoo_Uncommon := {"Cadmium", "Chromium", "Platinum", "Vanadium"};
set Moongoo_Rare := {"Caesium", "Hafnium", "Mercury", "Tecnetium"};
set Moongoo_Exceptional := {"Dysprosium", "Neodymium", "Promethium", "Thulium"};
set Moongoo := Moongoo_Ubiquitous union Moongoo_Common union Moongoo_Uncommon union Moongoo_Rare union Moongoo_Exceptional;

set Materials := Minerals union Ice_Products union Moongoo;

set Ores_Richest_Mineral, dimen 2;

set Reprocessing_Skills := 
	{"Reprocessing", "Reprocessing Efficiency"}
	union Standard_Ores
	union {"Ice"}
	union {"Common Moon", "Exceptional Moon", "Rare Moon", "Ubiquitous Moon", "Uncommon Moon"}
	;

# Parameters ########################################

# Static Data
param Ore_Volume{o in Ores}, > 0, default 0;
param Ore_Compressed_Volume{o in Compressable_Ores}, > 0, default 0; # Moon Ores cannot be compressed
param Batch_Mineral_Yield{o in Mineral_Ores, m in Minerals} integer, default 0, >= 0;
param Batch_Moongoo_Yield{o in Moon_Ores, m in Moongoo} integer, default 0, >= 0;
param Batch_Ice_Product_Yield{o in Ice_Ores, i in Ice_Products} integer, default 0, >= 0;

param Material_Volume{m in Materials} > 0, :=
	if m in Minerals then .01
	else if m in Moongoo then .05
	else if m in Ice_Isotopes then .03
	else if m = "Heavy Water" then .4
	else if m = "Liquid Ozone" then .4
	else if m = "Strontium Clathrates" then 3
;

# Parameters - Optimization
param Optimization_Moon_Ores_Only_Yield_Moongoo binary, default 1;
param Optimization_Set_Richest_Mineral_Ores_As_Upper_Bounds binary, default 0;

# Parameters - Dynamic Data
param Need_Material{m in Materials} integer, default 0, >= 0;

param base_facility_reprocessing_efficiency, >= 0, default .5;
param Reprocessing_Skill_Level {s in Reprocessing_Skills}, default 5, >= 0, <= 5;
param Reprocessing_Efficiency{o in Ores}, >= 0, default
	base_facility_reprocessing_efficiency 
	* (1 + .03 * Reprocessing_Skill_Level["Reprocessing"])
	* (1 + .02 * Reprocessing_Skill_Level["Reprocessing Efficiency"])
	* if o in Standard_Ores then 
		1 + .02 * Reprocessing_Skill_Level[o]
	else if o in Ice_Ores then
		1 + .02 * Reprocessing_Skill_Level["Ice"]
	else if o in Moon_Ores_Common then 
		1 + .02 * Reprocessing_Skill_Level["Common Moon"]
	else if o in Moon_Ores_Exceptional then 
		1 + .02 * Reprocessing_Skill_Level["Exceptional Moon"]
	else if o in Moon_Ores_Rare then 
		1 + .02 * Reprocessing_Skill_Level["Rare Moon"]
	else if o in Moon_Ores_Ubiquitous then 
		1 + .02 * Reprocessing_Skill_Level["Ubiquitous Moon"]
	else if o in Moon_Ores_Uncommon then 
		1 + .02 * Reprocessing_Skill_Level["Uncommon Moon"]
	;

param Batch_Mineral_Yield_Given_Efficiency{o in Ores, m in Minerals}, >= 0, default Batch_Mineral_Yield[o, m]* Reprocessing_Efficiency[o];


# Needs and Constraints

var Need_Ore{o in Ores} integer, >= 0;
var Yield_Material{m in Materials}, >= 0;
var Yield_Material_Ceil{m in Materials} integer, >= 0;

mineral_yield_sum{m in Minerals}: Yield_Material[m] =
	sum{o in Standard_Ores} (Need_Ore[o] * Batch_Mineral_Yield_Given_Efficiency[o,m])
	+ if !Optimization_Moon_Ores_Only_Yield_Moongoo then sum{o in Moon_Ores} (Need_Ore[o] * Batch_Mineral_Yield_Given_Efficiency[o, m])
	;

mineral_yields_is_geq_need{m in Minerals}: 	Yield_Material[m] >= Need_Material[m];
mineral_yield_ceil{m in Materials}: Yield_Material_Ceil[m] >= Yield_Material[m];

optimization_set_richest_mineral_ores_as_upper_bounds_{(m, o) in Ores_Richest_Mineral}: Need_Ore[o] <= 
	if Optimization_Set_Richest_Mineral_Ores_As_Upper_Bounds
	then 10 * ceil(Need_Material[m] /  Batch_Mineral_Yield_Given_Efficiency[o, m])
	else .99 * Infinity
	;

var Uncompressed_Volume;
uncompressed_volume_sum_of_each_ore: Uncompressed_Volume = sum{o in Ores} (Need_Ore[o] * Ore_Volume[o]);
var Compressed_Volume;
compressed_volume_sum_of_each_ore: Compressed_Volume = 
	sum{o in Compressable_Ores} (Need_Ore[o] * Ore_Compressed_Volume[o]) +
	sum{o in Uncompressable_Ores} (Need_Ore[o] * Ore_Volume[o]);

var Material_Delta{m in Materials} integer, >= 0;
material_delta_computation{m in Materials}: Material_Delta[m] = Yield_Material[m] - Need_Material[m];
var Material_Delta_Total integer, >= 0;
material_delta_total_computation: Material_Delta_Total = sum{m in Materials}(Material_Delta[m]);

###################################################################################
###################################################################################
#OBJECTIVE FUNCTION
###################################################################################
###################################################################################

minimize objective: Uncompressed_Volume;
solve;

###################################################################################
# Display stuff below this line
###################################################################################

display{o in Ores: Need_Ore[o] > 0}: Need_Ore[o];
end;
