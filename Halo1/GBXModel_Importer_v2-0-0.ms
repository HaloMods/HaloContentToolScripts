--***************************************************************************
--*					  GBXModel Impoter v2 by TheGhost						*
--*					   for 3ds Max v5+ and gmax v1.2						*
--*				http://ghost.halomaps.org/bluestreak/gbxmodel/				*
--*					   as part of Project BlueStreak						*
--***************************************************************************
--*		Features:															*
--*			- Import any geometry from the tag with many import options		*
--*			- Import perfect UVW coordinates and material ID's				*
--*			- Setup the max material library for the model's shaders		*
--*			- Import model's nodes and/or markers with many options			*
--*				(nodes/markers are perfectly placed and rotated)			*
--*			- Optionally import biped nodes as bone objects					*
--*			- Imports vertex weights for a fully rigged model				*
--*-------------------------------------------------------------------------*
--*	Instructions: Click the "Load GBXModel" button and navigate to the		*
--*	desired GBXModel tag. Select from the import options and press the 		*
--*	"Import	GBXModel" button to import the tag.								*
--*-------------------------------------------------------------------------*
--*	Submit bugs to TheGhost on the Gearbox Software forums. Visit the		*
--*	forums for additional help at http://gbxforums.gearboxsoftware.com.		*
--*	Visit the project site (http://ghost.halomaps.org/BlueStreak/) for more	*
--* details on this and other projects.										*
--*-------------------------------------------------------------------------*
--*	Copyright (C) 2006 Adam Papamarcos (mailto:papamarcos@gmail.com)		*
--*	This program is free software; you can redistribute it and/or modify it	*
--*	under the terms of the GNU General Public License as published by the	*
--*	Free Software Foundation; either version 2 of the License, or (at your	*
--*	option) any later version. This program is distributed in the hope that	*
--*	it will be useful, but WITHOUT ANY WARRANTY; without even the implied	*
--*	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See	*
--*	the GNU General Public License for more details. A full copy of this	*
--*	license is available at http://www.gnu.org/licenses/gpl.txt.			*
--*-------------------------------------------------------------------------*

marker_blocks = 0
marker_name = #()
marker_instance_blocks = #()
marker_instance_region_index = #()
marker_instance_permutation_index = #()
marker_instance_node_index = #()
marker_instance_translation = #()
marker_instance_rotation = #()

node_blocks = 0
node_name = #()
node_next_sibling_node_index = #()
node_first_child_node_index = #()
node_parent_node_index = #()
node_translation = #()
node_rotation = #()
node_distance_from_parent = #()

region_blocks = 0
region_name = #()
region_permutation_blocks = #()
region_permutation_name = #()
region_permutation_LOD_indices = #()
region_permutation_marker_blocks = #()
region_permutation_marker_name = #()
region_permutation_marker_node_index = #()
region_permutation_marker_rotation = #()
region_permutation_marker_translation = #()

geometry_blocks = 0
geometry_part_blocks = #()
geometry_part_shader_index = #()
geometry_part_data_offset = #()
geometry_part_uncompressed_vertex_blocks = #()
geometry_part_compressed_vertex_blocks = #()
geometry_part_triangle_blocks = #()
geometry_part_local_nodes = #()

shader_blocks = 0
shader_name = #()

node_array = #()
marker_array = #()

node_list_checksum = 0
in_file = undefined
in_name = undefined
local_nodes = false
u_scale = 1.0
v_scale = 1.0
ceRoot = ""
tagLoc = ""
maxver = maxVersion()

fn readShortB strType =
(
	b1 = readByte in_file #unsigned
	b2 = readByte in_file #unsigned
	bigEndianShort = (b1 * 256) + b2
	if strType == "#signed" then
	(
		if bigEndianShort > 32768 then
		(
			(65536 - bigEndianShort) * -1
		)
		else
		(
			bigEndianShort
		)
	)
	else
	(
		bigEndianShort
	)
)

fn readLongB strType =
(
	b1 = readByte in_file #unsigned
	b2 = readByte in_file #unsigned
	b3 = readByte in_file #unsigned
	b4 = readByte in_file #unsigned
	bigEndianLong = (b1 * 16777216) + (b2 * 65536) + (b3 * 256) + (b4 * 1)
	if strType == "#signed" then
	(
		if bigEndianLong as float > 2147483648 as float then
		(
			(4294967296 - bigEndianLong) * -1
		)
		else
		(
			bigEndianLong
		)
	)
	else
	(
		bigEndianLong
	)
)

fn readFloatB =
(
	local myBitArray = #{}
	b1 = readByte in_file #unsigned
	b2 = readByte in_file #unsigned
	b3 = readByte in_file #unsigned
	b4 = readByte in_file #unsigned
	for i = 8 to 1 by -1 do
	(
		myBitArray[i] = (mod b1 2 > .5)
		b1 /= 2
	)
	for i = 16 to 9 by -1 do
	(
		myBitArray[i] = (mod b2 2 > .5)
		b2 /= 2
	)
	for i = 24 to 17 by -1 do
	(
		myBitArray[i] = (mod b3 2 > .5)
		b3 /= 2
	)
	for i = 32 to 25 by -1 do
	(
		myBitArray[i] = (mod b4 2 > .5)
		b4 /= 2
	)
	
	local exp = 0.0
	for i = 9 to 2 by -1 do
	(
		if myBitArray[i] == true then
		(
			exp += 2.0 ^ (9 - i)
		)
	)
	exp -= 127.0
	
	local myFloat = 2.0 ^ exp
	exp -= 1
	for i = 10 to 32 do
	(
		if myBitArray[i] == true then
		(
			myFloat += 2.0 ^ exp
		)
		exp -= 1
	)
	if myBitArray[1] == true then
	(
		-myFloat
	)
	else
	(
		myFloat
	)
)

fn readQuat =
(
	q1 = readFloatB()
	q2 = readFloatB()
	q3 = readFloatB()
	q4 = readFloatB()
	normalize (quat q1 q2 q3 q4)
)

fn readTrans =
(
	f1 = readFloatB() * 100
	f2 = readFloatB() * 100
	f3 = readFloatB() * 100
	[f1,f2,f3]
)

fn getFlagArray num =
(
	local myBitArray = #{}
	for i = 1 to 8 do
	(
		myBitArray[i] = (mod num 2 > .5)
		num /= 2
	)
	myBitArray
)

rollout roll "GBXModel Importer v2 by TheGhost" width:408 height:450
(
	GroupBox grp_load "Load File" pos:[8,8] width:392 height:77
	button unload_button "Unload GBXModel" pos:[211,22] width:127 height:29 enabled:false
	button load_button "Load GBXModel" pos:[77,22] width:122 height:29
	label lbl_model "Model:" pos:[19,61] width:38 height:16 enabled:false
	edittext edt_model "" pos:[52,59] width:335 height:16 enabled:false
	
	GroupBox grp_select "LOD / Region / Permutation Selection" pos:[8,89] width:392 height:120 enabled:false
	radiobuttons radio_LOD "Select LOD" pos:[18,105] width:72 height:94 enabled:false labels:#("super high", "high", "medium", "low", "super low") default:1 columns:1
	listbox listbox_permutation "Select Model Permutation" pos:[232,111] width:156 height:5 enabled:false
	listbox listbox_region "Select Model Region" pos:[97,111] width:125 height:5 enabled:false
	
	GroupBox grp_import_selection "Import Geometry Selection" pos:[8,214] width:392 height:72 enabled:false
	radiobuttons radio_geometry "" pos:[16,231] width:206 height:48 enabled:false labels:#("Selected Permutation from All Regions", "All Permutations of Selected Region", "Selected Region and Permutation Only")
	checkbox chk_model "Import Model Geometry" pos:[240,228] width:128 height:17 enabled:false checked:true
	checkbox chk_node "Import All Nodes" pos:[240,245] width:96 height:17 enabled:false checked:true
	checkbox chk_marker "Import Markers" pos:[240,262] width:88 height:17 enabled:false checked:true
	
	GroupBox grp_model_options "Model Geometry Options" pos:[8,291] width:216 height:94 enabled:false
	checkbox chk_attach "Attach Parts of Mesh Within Region" pos:[16,309] width:192 height:17 enabled:false checked:true
	checkbox chk_uvw "Import UVW Coordinates and MatID's" pos:[16,326] width:197 height:17 enabled:false checked:true
	checkbox chk_matlib "Setup 3ds Material Library Shaders" pos:[16,343] width:184 height:17 enabled:false checked:true
	checkbox chk_weight "Import Vertex Weights (Rigged Model)" pos:[16,360] width:200 height:17 enabled:false checked:true
	
	GroupBox grp_node_marker_options "Node/Marker Options" pos:[231,291] width:169 height:94 enabled:false
	checkbox chk_bone "Import All Nodes as Bones" pos:[240,307] width:144 height:15 enabled:false
	checkbox chk_bip "Only Biped Nodes as Bones" pos:[240,324] width:150 height:15 enabled:false
	label lbl_node "Node Radius" pos:[264,346] width:64 height:13 enabled:false
	label lbl_marker "Marker Radius" pos:[256,364] width:71 height:13 enabled:false
	spinner spn_node "" pos:[330,344] width:42 height:16 enabled:false range:[0.01,30,2]
	spinner spn_marker "" pos:[330,363] width:42 height:16 enabled:false range:[0.01,30,1]
	
	GroupBox grp_import "Import Button" pos:[8,388] width:392 height:54 enabled:false
	button import_button "Import GBXModel" pos:[144,403] width:141 height:29 enabled:false
	label lbl_by "Script by TheGhost" pos:[16,423] width:105 height:15 enabled:false
	label lbl_version "v2.0.0" pos:[357,423] width:37 height:15 enabled:false
	
	on roll open do
	(
		ClearListener()
		format "-- GBXModel Importer v2 by TheGhost --\n"
		format "Using max version: %\n" (maxver[1] / 1000.0)
	)
	on roll close do
	(
		fclose in_file
	)
	on unload_button pressed do
	(
		fclose in_file
		unload_button.enabled = false
		lbl_model.enabled = false
		edt_model.text = ""
		grp_select.enabled = false
		radio_LOD.enabled = false
		listbox_permutation.enabled = false
		listbox_region.enabled = false
		listbox_permutation.items = #()
		listbox_region.items = #()
		grp_import_selection.enabled = false
		radio_geometry.enabled = false
		chk_model.enabled = false
		chk_node.enabled = false
		chk_marker.enabled = false
		grp_model_options.enabled = false
		chk_attach.enabled = false
		chk_uvw.enabled = false
		chk_matlib.enabled = false
		chk_weight.enabled = false
		grp_node_marker_options.enabled = false
		chk_bone.enabled = false
		chk_bip.enabled = false
		lbl_node.enabled = false
		lbl_marker.enabled = false
		spn_node.enabled = false
		spn_marker.enabled = false
		grp_import.enabled = false
		import_button.enabled = false
	)
	on load_button pressed do
	(
		in_name = getOpenFileName \
			filename: "C:\\Program Files\\Microsoft Games\\Halo Custom Edition\\tags\\" \
			types: "GBXModel Tag (*.gbxmodel)|*.gbxmodel|All Tag Files (*.*)|*.*"
			
		if in_name != undefined then
		(
			in_file = fopen in_name "rb"
			if in_file == undefined then
			(
				messageBox "Error in opening file!" title:"File opening error"
			)
			else
			(
				print ("Opened File: " + in_name)
				fseek in_file 36 #seek_set
				tag_type = readLongB "#unsigned"
				print ("Tag type check: " + tag_type as string)
				if tag_type != 1836016690 then
				(
					messageBox "Error: Incorrect file type!\n\nPlease select a valid .gbxmodel tag.  " \
						title:"Incorrect file type error"
				)
				else
				(
					start1 = timeStamp()
					
					local_nodes = false
					unload_button.enabled = true
					lbl_model.enabled = true
					grp_select.enabled = true
					radio_LOD.enabled = true
					listbox_permutation.enabled = true
					listbox_region.enabled = true
					grp_import_selection.enabled = true
					radio_geometry.enabled = true
					chk_model.enabled = true
					chk_node.enabled = true
					chk_marker.enabled = true
					grp_model_options.enabled = true
					chk_attach.enabled = true
					chk_uvw.enabled = true
					chk_matlib.enabled = true
					chk_weight.enabled = true
					grp_node_marker_options.enabled = true
					chk_bone.enabled = true
					chk_bip.enabled = true
					lbl_node.enabled = true
					lbl_marker.enabled = true
					spn_node.enabled = true
					spn_marker.enabled = true
					grp_import.enabled = true
					import_button.enabled = true
					
					marker_blocks = 0
					marker_name = #()
					marker_instance_blocks = #()
					marker_instance_region_index = #()
					marker_instance_permutation_index = #()
					marker_instance_node_index = #()
					marker_instance_translation = #()
					marker_instance_rotation = #()
					node_blocks = 0
					node_name = #()
					node_next_sibling_node_index = #()
					node_first_child_node_index = #()
					node_parent_node_index = #()
					node_translation = #()
					node_rotation = #()
					node_distance_from_parent = #()
					region_blocks = 0
					region_name = #()
					region_permutation_blocks = #()
					region_permutation_name = #()
					region_permutation_LOD_indices = #()
					region_permutation_marker_blocks = #()
					region_permutation_marker_name = #()
					region_permutation_marker_node_index = #()
					region_permutation_marker_rotation = #()
					region_permutation_marker_translation = #()
					geometry_blocks = 0
					geometry_part_blocks = #()
					geometry_part_shader_index = #()
					geometry_part_data_offset = #()
					geometry_part_uncompressed_vertex_blocks = #()
					geometry_part_compressed_vertex_blocks = #()
					geometry_part_triangle_blocks = #()
					geometry_part_local_nodes = #()
					shader_blocks = 0
					shader_name = #()
					
					ss = in_name as StringStream
					skipToString ss "tags\\"
					startPos = filePos ss
					ceRoot = substring in_name 1 (startPos - 5)
					global filenamePath = getFilenamePath in_name
					tagLoc = substring filenamePath (startPos+1) -1
					global tagName = getFilenameFile in_name
					edt_model.text = (" " + tagLoc + tagName + ".gbxmodel")
							
					print ("-------------------------------------------------------")
					
					fseek in_file 66 #seek_set
					flags = readShortB "#unsigned"
					model_flags = getFlagArray flags
					print ("Model Flags: " + model_flags as string)
					if model_flags[2] == true then
					(
						local_nodes = true
						print ("Model uses local nodes")
					)
					
					fseek in_file 68 #seek_set
					node_list_checksum = readLongB "#signed"
					print ("Node List Checksum: " + node_list_checksum as string)
					
					fseek in_file 112 #seek_set
					u_scale = readFloatB()
					fseek in_file 112 #seek_set
					if readFloat in_file == 0.0 do u_scale = 1.0
					print ("Base Map U-Scale: " + u_scale as string)
					
					fseek in_file 116 #seek_set
					v_scale = readFloatB()
					fseek in_file 116 #seek_set
					if readFloat in_file == 0.0 do v_scale = 1.0
					print ("Base Map V-Scale: " + v_scale as string)
					
					print ("-------------------------------------------------------")
					
					fseek in_file 238 #seek_set
					marker_blocks = readShortB "#unsigned"
					print ("Marker Blocks: " + marker_blocks as string)
					
					fseek in_file 250 #seek_set
					node_blocks = readShortB "#unsigned"
					print ("Node Blocks: " + node_blocks as string)
					
					fseek in_file 262 #seek_set
					region_blocks = readShortB "#unsigned"
					print ("Region Blocks: " + region_blocks as string)
					
					fseek in_file 274 #seek_set
					geometry_blocks = readShortB "#unsigned"
					print ("Geometry Blocks: " + geometry_blocks as string)
					
					fseek in_file 286 #seek_set
					shader_blocks = readShortB "#unsigned"
					print ("Shader Blocks: " + shader_blocks as string)
					
					print ("-------------------------------------------------------")
					
					fseek in_file 296 #seek_set
					
					print ("Marker block offset: " + (ftell in_file) as string)
					
					for m = 1 to marker_blocks do
					(
						offset = (ftell in_file)
						marker_name[m] = readString in_file
						fseek in_file (offset + 32) #seek_set
						fseek in_file 22 #seek_cur
						marker_instance_blocks[m] = readShortB "#unsigned"
						fseek in_file 8 #seek_cur
					)
					for m = 1 to marker_blocks do
					(
						temp_region_index = #()
						temp_permutation_index = #()
						temp_node_index = #()
						temp_translation = #()
						temp_rotation = #()
						for i = 1 to marker_instance_blocks[m] do
						(
							temp_region_index[i] = readByte in_file #unsigned
							temp_permutation_index[i] = readByte in_file #unsigned
							temp_node_index[i] = readByte in_file #unsigned
							fseek in_file 1 #seek_cur
							temp_translation[i] = readTrans()
							temp_rotation[i] = readQuat()
						)
						marker_instance_region_index[m] = temp_region_index
						marker_instance_permutation_index[m] = temp_permutation_index
						marker_instance_node_index[m] = temp_node_index
						marker_instance_translation[m] = temp_translation
						marker_instance_rotation[m] = temp_rotation
					)
					
					print ("Node block offset: " + (ftell in_file) as string)
					
					for n = 1 to node_blocks do
					(
						offset = (ftell in_file)
						node_name[n] = readString in_file
						fseek in_file (offset + 32) #seek_set
						node_next_sibling_node_index[n] = readShortB "#signed"
						node_first_child_node_index[n] = readShortB "#signed"
						node_parent_node_index[n] = readShortB "#signed"
						fseek in_file 2 #seek_cur
						node_translation[n] = readTrans()
						node_rotation[n] = readQuat()
						node_distance_from_parent[n] = readFloatB()
						fseek in_file 84 #seek_cur
					)
					
					print ("Region block offset: " + (ftell in_file) as string)
					
					for r = 1 to region_blocks do
					(
						offset = (ftell in_file)
						region_name[r] = readString in_file
						fseek in_file (offset + 32) #seek_set
						fseek in_file 34 #seek_cur
						region_permutation_blocks[r] = readShortB "#unsigned"
						fseek in_file 8 #seek_cur
					)
					for r = 1 to region_blocks do
					(
						temp_permutation_name = #()
						temp_permutation_LOD_indices = #()
						temp_permutation_marker_blocks = #()
						for p = 1 to region_permutation_blocks[r] do
						(
							offset = (ftell in_file)
							temp_permutation_name[p] = readString in_file
							fseek in_file (offset + 32) #seek_set
							fseek in_file 32 #seek_cur
							superlow = readShortB "#signed"
							low = readShortB "#signed"
							medium = readShortB "#signed"
							high = readShortB "#signed"
							superhigh = readShortB "#signed"
							temp_permutation_LOD_indices[p] = #(superlow, low, medium, high, superhigh)
							fseek in_file 4 #seek_cur
							temp_permutation_marker_blocks[p] = readShortB "#unsigned"
							fseek in_file 8 #seek_cur
						)
						region_permutation_name[r] = temp_permutation_name
						region_permutation_LOD_indices[r] = temp_permutation_LOD_indices
						region_permutation_marker_blocks[r] = temp_permutation_marker_blocks
						
						temp_permutation_marker_name = #()
						temp_permutation_marker_node_index = #()
						temp_permutation_marker_rotation = #()
						temp_permutation_marker_translation = #()
						for p = 1 to region_permutation_blocks[r] do
						(
							temp_marker_name = #()
							temp_marker_node_index = #()
							temp_marker_rotation = #()
							temp_marker_translation = #()
							for m = 1 to region_permutation_marker_blocks[r][p] do
							(
								offset = (ftell in_file)
								temp_marker_name[m] = readString in_file
								fseek in_file (offset + 32) #seek_set
								temp_marker_node_index[m] = readShortB "#signed"
								fseek in_file 2 #seek_cur
								temp_marker_rotation[m] = readQuat()
								temp_marker_translation[m] = readTrans()
								fseek in_file 16 #seek_cur
							)
							temp_permutation_marker_name[p] = temp_marker_name
							temp_permutation_marker_node_index[p] = temp_marker_node_index
							temp_permutation_marker_rotation[p] = temp_marker_rotation
							temp_permutation_marker_translation[p] = temp_marker_translation
						)
						region_permutation_marker_name[r] = temp_permutation_marker_name
						region_permutation_marker_node_index[r] = temp_permutation_marker_node_index
						region_permutation_marker_rotation[r] = temp_permutation_marker_rotation
						region_permutation_marker_translation[r] = temp_permutation_marker_translation
					)
					
					print ("Geometry block offset: " + (ftell in_file) as string)
					
					for g = 1 to geometry_blocks do
					(
						fseek in_file 38 #seek_cur
						geometry_part_blocks[g] = readShortB "#unsigned"
						fseek in_file 8 #seek_cur
					)
					for g = 1 to geometry_blocks do
					(
						temp_part_shader_index = #()
						temp_part_uncompressed_vertex_blocks = #()
						temp_part_compressed_vertex_blocks = #()
						temp_part_triangle_blocks = #()
						if local_nodes == true do temp_part_local_nodes = #()
						for p = 1 to geometry_part_blocks[g] do
						(
							fseek in_file 4 #seek_cur
							temp_part_shader_index[p] = readShortB "#signed"
							fseek in_file 28 #seek_cur
							temp_part_uncompressed_vertex_blocks[p] = readShortB "#unsigned"
							fseek in_file 10 #seek_cur
							temp_part_compressed_vertex_blocks[p] = readShortB "#unsigned"
							fseek in_file 10 #seek_cur
							temp_part_triangle_blocks[p] = readShortB "#unsigned"
							offset = (ftell in_file)
							if local_nodes == true then
							(
								fseek in_file 46 #seek_cur
								number_local_nodes = readShortB "#unsigned"
								the_local_nodes = #()
								for n = 1 to number_local_nodes do
								(
									append the_local_nodes (readByte in_file #unsigned)
								)
								temp_part_local_nodes[p] = the_local_nodes
							)
							fseek in_file (offset + 72) #seek_set
						)
						geometry_part_shader_index[g] = temp_part_shader_index
						geometry_part_uncompressed_vertex_blocks[g] = temp_part_uncompressed_vertex_blocks
						geometry_part_compressed_vertex_blocks[g] = temp_part_compressed_vertex_blocks
						geometry_part_triangle_blocks[g] = temp_part_triangle_blocks
						if local_nodes == true do geometry_part_local_nodes[g] = temp_part_local_nodes
						
						temp_part_data_offset = #()
						for p = 1 to geometry_part_blocks[g] do
						(
							temp_part_data_offset[p] = ftell in_file
							fseek in_file (geometry_part_uncompressed_vertex_blocks[g][p] * 68) #seek_cur
							fseek in_file (geometry_part_compressed_vertex_blocks[g][p] * 32) #seek_cur
							fseek in_file (geometry_part_triangle_blocks[g][p] * 6) #seek_cur
						)
						geometry_part_data_offset[g] = temp_part_data_offset
					)
					
					print ("Shader block offset: " + (ftell in_file) as string)
					
					fseek in_file (shader_blocks * 32) #seek_cur
					for s = 1 to shader_blocks do
					(
						shader_dir = readString in_file
						ss = shader_dir as StringStream
						d2 = 1
						d1 = 0
						while d1 < d2 do
						(
							temp_pos = filePos ss
							skipToString ss "\t"
							d2 = filePos ss - temp_pos
							seek ss temp_pos
							skipToString ss "\\"
							d1 = filePos ss - temp_pos
						)
						seek ss temp_pos
						shader_name[s] = readDelimitedString ss "\t"
					)
					
					print ("-------------------------------------------------------")
					
					end1 = timeStamp()
					print ("Model indexing took " + ((end1 - start1) as float / 1000.0) as string + " seconds")
					
					listbox_region.items = region_name
					listbox_permutation.items = region_permutation_name[1]
					listbox_region.selection = 1
					listbox_permutation.selection = 1
					
				)
			)
		)
	)
	on listbox_region selected i do
	(
		listbox_permutation.items = region_permutation_name[i]
	)
	on chk_model changed theState do
	(
		if theState == true then
		(
			chk_attach.checked = true
			chk_attach.enabled = true
			chk_uvw.checked = true
			chk_uvw.enabled = true
			chk_matlib.checked = true
			chk_matlib.enabled = true
			if chk_node.checked == true then
			(
				chk_weight.enabled = true
				chk_weight.checked = true
			)
			grp_model_options.enabled = true
		)
		else
		(
			chk_attach.checked = false
			chk_attach.enabled = false
			chk_uvw.checked = false
			chk_uvw.enabled = false
			chk_matlib.checked = false
			chk_matlib.enabled = false
			chk_weight.checked = false
			chk_weight.enabled = false
			grp_model_options.enabled = false
		)
	)
	on chk_node changed theState do
	(
		if theState == true then
		(
			if chk_model.checked == true do chk_weight.enabled = true
			chk_bone.enabled = true
			chk_bip.enabled = true
			lbl_node.enabled = true
			spn_node.enabled = true
			grp_node_marker_options.enabled = true
		)
		else
		(
			chk_weight.checked = false
			chk_weight.enabled = false
			chk_bone.checked = false
			chk_bone.enabled = false
			chk_bip.checked = false
			chk_bip.enabled = false
			lbl_node.enabled = false
			spn_node.enabled = false
			if chk_marker.checked == false then
			(
				grp_node_marker_options.enabled = false
			)
		)
	)
	on chk_marker changed theState do
	(
		if theState == true then
		(
			lbl_marker.enabled = true
			spn_marker.enabled = true
			grp_node_marker_options.enabled = true
		)
		else
		(
			lbl_marker.enabled = false
			spn_marker.enabled = false
			if chk_node.checked == false then
			(
				grp_node_marker_options.enabled = false
			)
		)
	)
	on chk_bone changed theState do
	(
		if theState == true then
		(
			chk_bip.checked = false
		)
	)
	on chk_bip changed theState do
	(
		if theState == true then
		(
			chk_bone.checked = false
		)
	)
	on import_button pressed do
	(
		region_index = listbox_region.selection
		permutation_index = listbox_permutation.selection
		LOD_index = radio_LOD.state
		LOD_switch = #(5, 4, 3, 2, 1)
		
		if chk_node.checked == false and chk_marker.checked == false and chk_model.checked == false then
		(
			messageBox "Error: You selected nothing to import!" title:"Import selection error"
		)
		
		global import_region_permutation = #()
		if radio_geometry.state == 1 then
		(
			permutation_name = region_permutation_name[region_index][permutation_index]
			for r = 1 to region_blocks do
			(
				for p = 1 to region_permutation_blocks[r] do
				(
					if permutation_name as name == region_permutation_name[r][p] as name then
					(
						append import_region_permutation #(r, p)
					)
				)
			)
		)
		else
		(
			if radio_geometry.state == 2 then
			(
				for p = 1 to region_permutation_blocks[region_index] do
				(
					append import_region_permutation #(region_index, p)
				)
			)
			else
			(
				append import_region_permutation #(region_index, permutation_index)
			)
		)
		
		if chk_node.checked == true or chk_marker.checked == true then
		(
			node_array = #()
			marker_array = #()
			
			for n = 1 to node_blocks do
			(
				node_array[n] = sphere radius:spn_node.value
				node_array[n].wirecolor = color 6 134 6
				node_array[n].name = node_name[n]
				if node_parent_node_index[n] != -1 do
				(
					node_array[n].parent = node_array[node_parent_node_index[n] + 1]
				)
				rot = (quat -node_rotation[n].x -node_rotation[n].y -node_rotation[n].z node_rotation[n].w)
				in coordsys parent node_array[n].rotation = rot
				in coordsys parent node_array[n].pos = node_translation[n]
			)
			
			if chk_bone.checked == true or chk_bip.checked == true then
			(
				for n = 1 to node_array.count do
				(
					if chk_bip.checked == false or (substring node_name[n] 1 5 as name == "bip01" as name) then
					(
						if node_first_child_node_index[n] == -1 then
						(
							myBone = BoneSys.createBone node_array[n].pos [node_array[n].pos.x + spn_node.value, node_array[n].pos.y, node_array[n].pos.z] [0,0,1]
							myBone.name = node_array[n].name
							myBone.width = spn_node.value
							myBone.height = spn_node.value
							myBone.taper = 50
						)
						else
						(
							myBone = BoneSys.createBone node_array[n].pos node_array[node_first_child_node_index[n] + 1].pos [0,0,1]
							myBone.name = node_array[n].name
							myBone.width = spn_node.value
							myBone.height = spn_node.value
							myBone.taper = 70
							
							if (myBone.name as name == "bip01 spine1" as name) then
							(
								myBone.length *= 0.8
								myBone.width = spn_node.value
								myBone.height = spn_node.value / 2
								myBone.taper = -180
							)
							if (myBone.name as name == "bip01 pelvis" as name) or (myBone.name as name == "bip01 spine" as name) then
							(
								myBone.width = spn_node.value
								myBone.height = spn_node.value / 2
								myBone.taper = -180
							)
							if (myBone.name as name == "frame bone24" as name) then
							(
								myBone.length = spn_node.value * 4
								myBone.width = spn_node.value * 4
								myBone.height = spn_node.value * 4
								myBone.taper = 100
							)
							if (myBone.name as name == "frame l wriste" as name) or (myBone.name as name == "frame r wriste" as name) then
							(
								myBone.length = 2.8
								myBone.width = spn_node.value
								myBone.height = spn_node.value * (.3)
								myBone.taper = -270
							)
							if (myBone.name as name == "frame l forearm" as name) or (myBone.name as name == "frame r forearm" as name) then
							(
								myBone.width = spn_node.value * 2
								myBone.height = spn_node.value * 2
							)
							if (myBone.name as name == "frame l upperarm" as name) or (myBone.name as name == "frame r upperarm" as name) then
							(
								myBone.width = spn_node.value * 3
								myBone.height = spn_node.value * 3
							)
							
						)
						
						delete node_array[n]
						node_array[n] = myBone
						
						if node_parent_node_index[n] != -1 then
						(
							myBone.parent = node_array[node_parent_node_index[n] + 1]
						)
						
						rot = (quat -node_rotation[n].x -node_rotation[n].y -node_rotation[n].z node_rotation[n].w)
						in coordsys parent myBone.rotation = rot
						in coordsys parent myBone.pos = node_translation[n]
					)
				)
			)
			
			if chk_marker.checked == true then
			(
				m = 0
				for b = 1 to marker_blocks do
				(
					for i = 1 to marker_instance_blocks[b] do
					(
						for p = 1 to import_region_permutation.count do
						(
							if (marker_instance_region_index[b][i] + 1) == import_region_permutation[p][1] and (marker_instance_permutation_index[b][i] + 1) == import_region_permutation[p][2] then
							(
								m += 1
								marker_array[m] = sphere radius:spn_marker.value
								marker_array[m].wirecolor = color 28 89 177
								marker_array[m].name = "#" + marker_name[b]
								marker_array[m].parent = node_array[marker_instance_node_index[b][i] + 1]
								rot = (quat -marker_instance_rotation[b][i].x -marker_instance_rotation[b][i].y -marker_instance_rotation[b][i].z marker_instance_rotation[b][i].w)
								in coordsys parent marker_array[m].rotation = rot
								in coordsys parent marker_array[m].pos = marker_instance_translation[b][i]
							)
						)
					)
				)
				for r = 1 to region_blocks do
				(
					for p = 1 to region_permutation_blocks[r] do
					(
						for b = 1 to region_permutation_marker_blocks[r][p] do
						(
							for i = 1 to import_region_permutation.count do
							(
								if (r == import_region_permutation[i][1]) and (p == import_region_permutation[i][2]) then
								(
									m += 1
									marker_array[m] = sphere radius:spn_marker.value
									marker_array[m].wirecolor = color 28 89 177
									marker_array[m].name = "#" + region_permutation_marker_name[r][p][b]
									marker_array[m].parent = node_array[region_permutation_marker_node_index[r][p][b] + 1]
									rot = (quat -region_permutation_marker_rotation[r][p][b].x -region_permutation_marker_rotation[r][p][b].y -region_permutation_marker_rotation[r][p][b].z region_permutation_marker_rotation[r][p][b].w)
									in coordsys parent marker_array[m].rotation = rot
									in coordsys parent marker_array[m].pos = region_permutation_marker_translation[r][p][b]
								)
							)
						)
					)
				)
			)
			
			if chk_node.checked == false then
			(
				for n = 1 to node_blocks do
				(
					delete node_array[n]
				)
			)
		)
		
		if chk_model.checked == true then
		(
			import_geometry_indices = #()
			for i = 1 to import_region_permutation.count do
			(
				import_geometry_indices[i] = (region_permutation_LOD_indices[import_region_permutation[i][1]][import_region_permutation[i][2]][LOD_switch[LOD_index]] + 1)
			)
			
			if chk_matlib.checked == true then
			(
				meditMaterials[1] = multimaterial()
				meditMaterials[1].materialList.count = shader_name.count
				for s = 1 to shader_name.count do
				(
					meditMaterials[1].names[s] = shader_name[s]
					meditMaterials[1].materialList[s].name = shader_name[s]
					meditMaterials[1].materialIDList[s] = s
				)
			)
			
			for geometry_index = 1 to import_geometry_indices.count do
			(
				g = import_geometry_indices[geometry_index]
				
				part_meshes = #()
				part_vertex_node_index = #()
				part_vertex_node_weight = #()
				
				for p = 1 to geometry_part_blocks[g] do
				(
					vertex_xyz = #()
					vertex_uvw = #()
					vertex_node_index = #()
					vertex_node_weight = #()
					vertex_order = #()
					triangles = #()
					
					vertex_xyz[geometry_part_uncompressed_vertex_blocks[g][p]] = 0
					vertex_uvw[geometry_part_uncompressed_vertex_blocks[g][p]] = 0
					
					fseek in_file geometry_part_data_offset[g][p] #seek_set
					
					for v = 1 to geometry_part_uncompressed_vertex_blocks[g][p] do
					(
						vertex_xyz[v] = readTrans()
						
						fseek in_file 36 #seek_cur
						
						if chk_uvw.checked == true then
						(
							u_coord = readFloatB() * u_scale
							v_coord = 1 - (readFloatB() * v_scale)
							vertex_uvw[v] = [u_coord,v_coord,0]
						)
						else
						(
							fseek in_file 8 #seek_cur
						)
						
						if chk_weight.checked == true then
						(
							node0_index = (readShortB "#signed") + 1
							node1_index = (readShortB "#signed") + 1
							
							if local_nodes == true then
							(
								vertex_node_index[v] = #()
								if node0_index == 0 then
								(
									vertex_node_index[v][1] = 0
								)
								else
								(
									vertex_node_index[v][1] = geometry_part_local_nodes[g][p][node0_index] + 1
								)
								if node1_index == 0 then
								(
									vertex_node_index[v][2] = 0
								)
								else
								(
									vertex_node_index[v][2] = geometry_part_local_nodes[g][p][node1_index] + 1
								)
							)
							else
							(
								vertex_node_index[v] = #(node0_index, node1_index)
							)
							
							append part_vertex_node_index vertex_node_index[v]
							
							node0_weight = readFloatB()
							node1_weight = readFloatB()
							vertex_node_weight[v] = #(node0_weight, node1_weight)
							
							append part_vertex_node_weight vertex_node_weight[v]
						)
						else
						(
							fseek in_file 12 #seek_cur
						)
					)
					
					fseek in_file (geometry_part_compressed_vertex_blocks[g][p] * 32) #seek_cur
					
					triangle_vertices = (geometry_part_triangle_blocks[g][p] * 3)
					for t = 1 to triangle_vertices do
					(
						append vertex_order ((readShortB "#signed") + 1)
					)
					
					vo_count = vertex_order.count
					if vertex_order[vo_count] == 0 do deleteItem vertex_order (vo_count)
					if vertex_order[vo_count-1] == 0 do deleteItem vertex_order (vo_count-1)
					
					for w = 1 to (vertex_order.count - 2) do
					(
						triangles[w] = [vertex_order[w],vertex_order[w+1],vertex_order[w+2]]
					)
					
					for r = 1 to triangles.count by 2 do
					(
						a = triangles[r][1]
						triangles[r][1] = triangles[r][3]
						triangles[r][3] = a
					)
					
					for d = triangles.count to 1 by -1 do
					(
						if (triangles[d][1] == triangles[d][2]) or (triangles[d][2] == triangles[d][3]) or (triangles[d][1] == triangles[d][3]) then
						(
							deleteItem triangles d
						)
					)
					
					if chk_uvw.checked != true then
					(
						m = mesh vertices:vertex_xyz faces:triangles
					)
					else
					(
						faces_matID = #()
						for t = 1 to triangles.count do
						(
							faces_matID[t] = geometry_part_shader_index[g][p] + 1
						)
						m = mesh vertices:vertex_xyz tverts:vertex_uvw faces:triangles materialIDs:faces_matID
						mmesh = m.mesh
						buildTVFaces mmesh
						for i = 1 to mmesh.numfaces do
						(
							setTVFace mmesh i (getFace mmesh i)
							setFaceSmoothGroup mmesh i 1
						)
						m.material = meditMaterials[1]
					)
					m.name = shader_name[geometry_part_shader_index[g][p] + 1]
					part_meshes[p] = m
					
					if chk_weight.checked == true and chk_attach.checked == false then
					(
						theSkin = Skin()
						max modify mode
						select m
						modPanel.addModToSelection theSkin
						
						if maxver[1] > 4200 then
						(
							theSkin.bone_Limit = 2
						)
						
						for n = 1 to node_array.count do
						(
							skinOps.addbone theSkin node_array[n] 1
						)
						
						subobjectLevel = 1
						
						skinVerts = skinOps.getNumberVertices theSkin
						for vt = 1 to skinVerts do
						(
							if vertex_node_index[vt][2] == 0 then
							(
								skinOps.ReplaceVertexWeights theSkin vt vertex_node_index[vt][1] vertex_node_weight[vt][1]
							)
							else
							(
								if vertex_node_index[vt][1] == 0 then
								(
									skinOps.ReplaceVertexWeights theSkin vt vertex_node_index[vt][2] vertex_node_weight[vt][2]
								)
								else
								(
									if vertex_node_index[vt][1] == vertex_node_index[vt][2] then
									(
										skinOps.ReplaceVertexWeights theSkin vt vertex_node_index[vt][1] 1.0
									)
									else
									(
										skinOps.ReplaceVertexWeights theSkin vt vertex_node_index[vt] vertex_node_weight[vt]
									)
								)
							)
						)
						
						max create mode
					)
					
				)
				
				if chk_attach.checked == true then
				(
					for a = 2 to part_meshes.count do
					(
						attach part_meshes[1] part_meshes[a]
					)
					part_meshes[1].name = region_name[import_region_permutation[geometry_index][1]]
					
					if chk_weight.checked == true then
					(
						theSkin = Skin()
						max modify mode
						select part_meshes[1]
						modPanel.addModToSelection theSkin
						
						if maxver[1] > 4200 then
						(
							theSkin.bone_Limit = 2
						)
						
						for n = 1 to node_array.count do
						(
							skinOps.addbone theSkin node_array[n] 1
						)
						
						subobjectLevel = 1
						
						skinVerts = skinOps.getNumberVertices theSkin
						for vt = 1 to skinVerts do
						(
							if part_vertex_node_index[vt][2] == 0 then
							(
								skinOps.ReplaceVertexWeights theSkin vt part_vertex_node_index[vt][1] part_vertex_node_weight[vt][1]
							)
							else
							(
								if part_vertex_node_index[vt][1] == 0 then
								(
									skinOps.ReplaceVertexWeights theSkin vt part_vertex_node_index[vt][2] part_vertex_node_weight[vt][2]
								)
								else
								(
									if part_vertex_node_index[vt][1] == part_vertex_node_index[vt][2] then
									(
										skinOps.ReplaceVertexWeights theSkin vt part_vertex_node_index[vt][1] 1.0
									)
									else
									(
										skinOps.ReplaceVertexWeights theSkin vt part_vertex_node_index[vt] part_vertex_node_weight[vt]
									)
								)
							)
						)
						
						max create mode
					)
				)
			)
		)
	)
)


CreateDialog roll

-- End of Script --