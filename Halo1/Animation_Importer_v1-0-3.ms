--***************************************************************************
--*					   Animation Impoter by TheGhost						*
--*					   for 3ds Max v5+ and gmax v1.2						*
--***************************************************************************
--*		Features:															*
--*			- Load a Halo animation tag directly from 3ds max or gmax		*
--*			- Import animations from any animation tag, including biped,	*
--*				vehicle, weapon, FP, scenery, and cinematic animations.		*
--*			- Import and export all types of animations, including base,	*
--*				overlay, and replacement animations.						*
--*			- Export selected or all source animation files from tag into	*
--*				the recompilable (JMA, JMO, JMM, etc.) formats.				*
--*			- Recompiled animations are identical to the original tags;		*
--*				new anims can seamlessly be added to the animation graph.	*
--*			- Import animation into scene to bone or biped object rigs.		*
--*			- Character animations can be interpolated to import on an		*
--*				other rig (i.e. import Elite animations to Cyborg).			*
--*			- Optionally import frame info data and extra base frames.		*
--*			- Intuitive controls and easy use, but powerful functionality.	*
--*-------------------------------------------------------------------------*
--*	Instructions: Click the load button to load a .model_animations tag		*
--*	that was either included in the HEK or extracted from a map. Use the	*
--*	drop down list to select an animation and click "Export Animation" to	*
--*	export a source animation data file or "Import Animation into Scene"	*
--*	to import the animation to a character rig already set up in the scene.	*
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

node_name = #()
node_next_sib_index = #()
node_first_child_index = #()
node_parent_index = #()
node_array = #()

animation_name = #()
animation_type = #()
animation_frame_count = #()
animation_frame_size = #()
animation_frame_info_type = #()
animation_flags = #()
animation_frame_info_size = #()
node_trans_flag_data = #()
node_rotation_flag_data = #()
node_scale_flag_data = #()
animation_default_data_size = #()
animation_frame_data_size = #()

frame_info_offset = #()
default_data_offset = #()
frame_data_offset = #()

node_count = 0
node_list_checksum = 0
in_file = undefined
in_name = undefined
ceRoot = ""
tagLoc = ""
maxver = maxVersion()

node_default_rotation = #()
node_default_translation = #()
node_default_scale = #()

frame_node_rotation = #()
frame_node_translation = #()
frame_node_scale = #()

frame_info_dx = #()
frame_info_dy = #()
frame_info_dz = #()
frame_info_dyaw = #()


fn readShortB strType =
(
	b1 = readByte in_file #unsigned
	b2 = readByte in_file #unsigned
	bigEndianShort = (b1 * 256) + (b2 * 1)
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
		if bigEndianLong > 8388608 then
		(
			(16777216 - bigEndianLong) * -1
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

fn readFlagData =
(
	local mybitarray = #{}
	local byte_array = #()
	byte_array[1] = readByte in_file #unsigned
	byte_array[2] = readByte in_file #unsigned
	byte_array[3] = readByte in_file #unsigned
	byte_array[4] = readByte in_file #unsigned
	byte_array[5] = readByte in_file #unsigned
	byte_array[6] = readByte in_file #unsigned
	byte_array[7] = readByte in_file #unsigned
	byte_array[8] = readByte in_file #unsigned
	bitString = ""
	string_byte_array = #()
	for n = 1 to 8 do
	(
		string_byte_array[n] = byte_array[n]
	)
	x_array = #(4,3,2,1,8,7,6,5)
	for n = 1 to 8 do
	(
		for i = 1 to 8 do
		(
			x = x_array[n]
			if (mod string_byte_array[x] 2 > .5) == true then
			(
				bitString += "1"
				string_byte_array[x] /= 2
			)
			else
			(
				bitString += "0"
				string_byte_array[x] /= 2
			)
		)
	)
	for i = 1 to node_count do
	(
		if bitString[i] == "1" then
		(
			mybitarray[i] = true
		)
		else
		(
			mybitarray[i] = false
		)
	)
	mybitarray
)

fn readFloatB =
(
	local mybitarray = #{}
	local exp = 0.0
	local mantissaString = "1"
	local myFloat = 0.0
	b1 = readByte in_file #unsigned
	b2 = readByte in_file #unsigned
	b3 = readByte in_file #unsigned
	b4 = readByte in_file #unsigned
	for i = 8 to 1 by -1 do
	(
		mybitarray[i] = (mod b1 2 > .5)
		b1 /= 2
	)
	for i = 16 to 9 by -1 do
	(
		mybitarray[i] = (mod b2 2 > .5)
		b2 /= 2
	)
	for i = 24 to 17 by -1 do
	(
		mybitarray[i] = (mod b3 2 > .5)
		b3 /= 2
	)
	for i = 32 to 25 by -1 do
	(
		mybitarray[i] = (mod b4 2 > .5)
		b4 /= 2
	)
	if mybitarray[1] == true do isNegative = true
	for i = 9 to 2 by -1 do
	(
		if mybitarray[i] == true do exp += 1.0 * 2.0^(9-i)
	)
	exp -= 127.0
	for i = 10 to 32 by 1 do
	(
		if mybitarray[i] == true then
		(
			mantissaString += "1"
		)
		else
		(
			mantissaString += "0"
		)
	)
	for i = 1 to mantissaString.count do
	(
		myFloat += (mantissaString[i] as float) * 2.0^exp
		exp -= 1
	)
	if mybitarray[1] == true do myFloat = myFloat * -1.0
	myFloat
)

fn readQuat =
(
	q1 = (readShortB "#signed") as float / 32767.0
	q2 = (readShortB "#signed") as float / 32767.0
	q3 = (readShortB "#signed") as float / 32767.0
	q4 = (readShortB "#signed") as float / 32767.0
	normalize (quat q1 q2 q3 q4)
)

fn readTrans =
(
	f1 = readFloatB()
	f2 = readFloatB()
	f3 = readFloatB()
	[f1,f2,f3]
)

fn getFlagArray num =
(
	local mybitarray = #{}
	for i = 1 to 3 do
	(
		mybitarray[i] = (mod num 2 > .5)
		num /= 2
	)
	mybitarray
)

fn parseAnimationData animID =
(
	node_default_rotation[node_count] = 0
	node_default_translation[node_count] = 0
	node_default_scale[node_count] = 0
	
	frame_count = animation_frame_count[animID]
	frame_info_type = animation_frame_info_type[animID]
	
	fseek in_file frame_info_offset[animID] #seek_set
	
	for f = 1 to frame_count do
	(
		if frame_info_type >= 1 then
		(
			frame_info_dx[f] = readFloatB() * 100.0
			frame_info_dy[f] = readFloatB() * 100.0
			
			if frame_info_type == 2 then
			(
				frame_info_dyaw[f] = radToDeg (readFloatB())
			)
			else
			(
				if frame_info_type == 3 then
				(
					frame_info_dz[f] = readFloatB() * 100.0
					frame_info_dyaw[f] = radToDeg (readFloatB())
				)
			)
		)
	)
	
	for n = 1 to node_count do
	(
		if node_rotation_flag_data[animID][n] == false then
		(
			node_default_rotation[n] = readQuat()
		)
		if node_trans_flag_data[animID][n] == false then
		(
			node_default_translation[n] = readTrans() * 100.0
		)
		if node_scale_flag_data[animID][n] == false then
		(
			theScale = readFloatB()
			node_default_scale[n] = [theScale,theScale,theScale]
		)
	)
	
	frame_node_rotation[frame_count] = 0
	frame_node_translation[frame_count] = 0
	frame_node_scale[frame_count] = 0
	
	for c = 1 to frame_count do
	(
		node_rotation = #()
		node_translation = #()
		node_scale = #()
		
		node_rotation[node_count] = 0
		node_translation[node_count] = 0
		node_scale[node_count] = 0
		
		for n = 1 to node_count do
		(
			if node_rotation_flag_data[animID][n] == true then
			(
				node_rotation[n] = readQuat()
			)
			else
			(
				node_rotation[n] = node_default_rotation[n]
			)
			
			if node_trans_flag_data[animID][n] == true then
			(
				node_translation[n] = readTrans() * 100.0
			)
			else
			(
				node_translation[n] = node_default_translation[n]
			)
			
			if node_scale_flag_data[animID][n] == true then
			(
				theScale = readFloatB()
				node_scale[n] = [theScale,theScale,theScale]
			)
			else
			(
				node_scale[n] = node_default_scale[n]
			)
		)
		
		frame_node_rotation[c] = node_rotation
		frame_node_translation[c] = node_translation
		frame_node_scale[c] = node_scale
		
	)
)

fn hasNoData animID =
(
	fseek in_file default_data_offset[animID] #seek_set
	test1 = readFloat in_file
	test2 = readFloat in_file
	test3 = readFloat in_file
	test4 = readFloat in_file
	(test1 == 0.0 and test2 == 0.0 and test3 == 0.0 and test4 == 0.0)
)

fn getAnimType animID =
(
	type = animation_type[animID]
	frame_info_type = animation_frame_info_type[animID]
	worldRelative = animation_flags[animID][2]
	
	if type == 0 then
	(
		if frame_info_type == 0 then
		(
			if worldRelative == false then
			(
				"JMM"
			)
			else
			(
				"JMW"
			)
		)
		else
		(
			if frame_info_type == 1 then
			(
				"JMA"
			)
			else
			(
				if frame_info_type == 2 then
				(
					"JMT"
				)
				else
				(
					"JMZ"
				)
			)
		)
	)
	else
	(
		if type == 1 then
		(
			"JMO"
		)
		else
		(
			"JMR"
		)
	)
)

fn rotateBipedCoordParent theNode rot =
(
	nodeParent = theNode.parent
	theRootNode = theNode.controller.rootNode
	if nodeParent == theRootNode or nodeParent == undefined then
	(
		biped.setTransform theRootNode #rotation (rot - (quat .5 .5 .5 .5)) true
	)
	else
	(
		parentRot = biped.getTransform nodeParent #rotation
		biped.setTransform theNode #rotation (rot + parentRot) true
	)
)

fn moveBipedCoordParent theNode trans =
(
	nodeParent = theNode.parent
	theRootNode = theNode.controller.rootNode
	if nodeParent == theRootNode or nodeParent == undefined then
	(
		biped.setTransform theRootNode #pos (trans) true
	)
)

rollout roll "Animation Importer" width:223 height:526
(
	GroupBox grp_title "" pos:[9,2] width:205 height:47
	label lbl_title "BlueStreak: Animation Importer" pos:[39,13] width:150 height:13
	label lbl_title2 "for 3ds max v5+ and gmax 1.2" pos:[40,28] width:148 height:13
	
	GroupBox grp_load "Load an Animation Tag" pos:[9,53] width:205 height:85
	button load_button "Load Animation File" pos:[44,72] width:130 height:31
	button unload_button "Unload Animation File" pos:[41,109] width:136 height:21 enabled:false
	
	GroupBox grp_animinfo "Animation Info" pos:[9,143] width:205 height:104 enabled:false
	dropdownList ddl_select "Select an Animation:" pos:[21,159] width:180 height:40 enabled:false
	label lbl_animtype "Animation Type:" pos:[48,205] width:82 height:13 enabled:false
	label lbl_framecount "Frame Count:" pos:[61,224] width:67 height:13 enabled:false
	edittext edt_frame_count "" pos:[127,224] width:50 height:15 enabled:false
	edittext edt_type "" pos:[127,204] width:50 height:15 enabled:false
	
	GroupBox grp_exportoptions "Export Animation Data Options" pos:[9,252] width:205 height:120 enabled:false
	checkbox chk_all "Export All Animations from Tag" pos:[21,288] width:168 height:17 enabled:false checked:false
	checkbox chk_jma "Export Data to File (3ds max only)" pos:[21,270] width:176 height:17 enabled:false checked:true
	checkbox chk_stream "Stream Data with Listener (gmax)" pos:[21,307] width:179 height:17 enabled:false
	button save_button "Export Animation Data" pos:[40,330] width:140 height:31 enabled:false
	
	GroupBox grp_importoptions "Import Animation Data Options" pos:[9,379] width:205 height:121 enabled:false
	checkbox chk_finfo "Import Frame Info (dx, dy, dyaw)" pos:[21,397] width:174 height:17 enabled:false
	checkbox chk_fbase "Import Extra Base Frame" pos:[21,415] width:177 height:17 enabled:false
	checkbox chk_fdefault "Import Overlay Default Frame" pos:[21,434] width:177 height:17 enabled:false
	button import_button "Import Animation into Scene" pos:[29,457] width:163 height:31 enabled:false
	
	label lbl_scriptby "Script by TheGhost" pos:[12,507] width:100 height:13 enabled:false
	label lbl_version "v1.0.3" pos:[178,508] width:34 height:13 enabled:false
	
	on roll open do
	(
		clearListener()
		if maxver[1] <= 4200 then
		(
			format ("Max version " + (maxver[1] / 1000.0) as string + " (gmax) detected.\n")
			chk_all.enabled = false
			chk_jma.checked = false
			chk_jma.enabled = false
			chk_stream.checked = true
		)
		else
		(
			format ("3ds Max version " + (maxver[1] / 1000.0) as string + " detected.\n")
		)
	)
	on roll close do
	(
		fclose in_file
	)
	on load_button pressed do
	(
		in_name = getOpenFileName \
			filename: "C:\\Program Files\\Microsoft Games\\Halo Custom Edition\\tags\\" \
			types: "Animation Tag (*.model_animations)|*.model_animations|All Tag Files (*.*)|*.*"
				
		if in_name != undefined then
		(
			in_file = fopen in_name "rb"
			if in_file == undefined then
			(
				messageBox "Error in opening file!" title:"File opening error"
			)
			else
			(
				node_name = #()
				node_next_sib_index = #()
				node_first_child_index = #()
				node_parent_index = #()
				animation_name = #()
				animation_type = #()
				animation_frame_count = #()
				animation_frame_size = #()
				animation_frame_info_type = #()
				animation_flags = #()
				animation_frame_info_size = #()
				node_trans_flag_data = #()
				node_rotation_flag_data = #()
				node_scale_flag_data = #()
				animation_default_data_size = #()
				animation_frame_data_size = #()
				frame_info_offset = #()
				default_data_offset = #()
				frame_data_offset = #()
				node_count = 0
				node_list_checksum = 0
				ClearListener()
				
				print ("Opened File: " + in_name)
				
				fseek in_file 36 #seek_set
				tag_type = readLong in_file
				print ("Tag type check: " + tag_type as string)
				
				if tag_type != 1920233057 then
				(
					messageBox "Error: Incorrect file type!\n\nPlease select a .model_animations tag.  " \
						title:"Incorrect file type error"
				)
				else
				(
					ss = in_name as StringStream
					skipToString ss "tags\\"
					startPos = filePos ss
					ceRoot = substring in_name 1 (startPos - 5)
					
					filenamePath = getFilenamePath in_name
					tagLoc = substring filenamePath (startPos+1) -1
					tagName = getFilenameFile in_name
							
					print ("-------------------------------------------------------")
					
					fseek in_file 67 #seek_set
					object_blocks = readByte in_file #unsigned
					print ("Object Blocks: " + object_blocks as string)
					
					fseek in_file 79 #seek_set
					unit_blocks = readByte in_file #unsigned
					print ("Unit Blocks: " + unit_blocks as string)
					
					fseek in_file 91 #seek_set
					weapon_blocks = readByte in_file #unsigned
					print ("Weapon Blocks: " + weapon_blocks as string)
					
					fseek in_file 103 #seek_set
					vehicle_blocks = readByte in_file #unsigned
					print ("Vehicle Blocks: " + vehicle_blocks as string)
					
					fseek in_file 115 #seek_set
					device_blocks = readByte in_file #unsigned
					print ("Device Blocks: " + device_blocks as string)
					
					fseek in_file 127 #seek_set
					unit_damage_blocks = readByte in_file #unsigned
					print ("Unit Damage Blocks: " + unit_damage_blocks as string)
					
					fseek in_file 139 #seek_set
					fp_weapon_blocks = readByte in_file #unsigned
					print ("FP Weapon Blocks: " + fp_weapon_blocks as string)
					
					fseek in_file 151 #seek_set
					sound_reference_blocks = readByte in_file #unsigned
					print ("Sound Refernce Blocks: " + sound_reference_blocks as string)
					
					fseek in_file 171 #seek_set
					node_blocks = readByte in_file #unsigned
					print ("Node Blocks: " + node_blocks as string)
										
					fseek in_file 183 #seek_set
					animation_blocks = readByte in_file #unsigned
					print ("Animation Blocks: " + animation_blocks as string)
					
					print ("-------------------------------------------------------")
					
					print ("Object block offset: " + (ftell in_file) as string)
					
					for i = 1 to object_blocks do
					(
						fseek in_file 20 #seek_cur
					)
					
					print ("Unit block offset: " + (ftell in_file) as string)
					
					unit_animations = #()
					unit_ikpoints = #()
					unit_weapons = #()
					
					for i = 1 to unit_blocks do
					(
						fseek in_file 75 #seek_cur
						unit_animations[i] = readByte in_file #unsigned
						fseek in_file 11 #seek_cur
						unit_ikpoints[i] = readByte in_file #unsigned
						fseek in_file 11 #seek_cur
						unit_weapons[i] = readByte in_file #unsigned
					)
					
					fseek in_file 8 #seek_cur
					
					for i = 1 to unit_blocks do
					(
						unit_weapon_animations = #()
						unit_weapon_ikpoints = #()
						unit_weapon_weapontypes = #()
						
						fseek in_file (unit_animations[i] * 2) #seek_cur
						fseek in_file (unit_ikpoints[i] * 64) #seek_cur
						
						for w = 1 to unit_weapons[i] do
						(
							fseek in_file 155 #seek_cur
							unit_weapon_animations[w] = readByte in_file #unsigned
							fseek in_file 11 #seek_cur
							unit_weapon_ikpoints[w] = readByte in_file #unsigned
							fseek in_file 11 #seek_cur
							unit_weapon_weapontypes[w] = readByte in_file #unsigned
							fseek in_file 8 #seek_cur
						)
						
						for w = 1 to unit_weapons[i] do
						(
							unit_weapon_weapontypes_animations = #()
							
							fseek in_file (unit_weapon_animations[w] * 2) #seek_cur
							fseek in_file (unit_weapon_ikpoints[w] * 64) #seek_cur
							for t = 1 to unit_weapon_weapontypes[w] do
							(
								fseek in_file 51 #seek_cur
								unit_weapon_weapontypes_animations[t] = readByte in_file #unsigned
								fseek in_file 8 #seek_cur
							)
							
							for t = 1 to unit_weapon_weapontypes[w] do
							(
								fseek in_file (unit_weapon_weapontypes_animations[t] * 2) #seek_cur
							)
						)
					)
					
					print ("Weapon block offset: " + (ftell in_file) as string)
					
					for w = 1 to weapon_blocks do
					(
						fseek in_file 19 #seek_cur
						weapon_animations = readByte in_file #unsigned
						fseek in_file 8 #seek_cur
						fseek in_file (weapon_animations * 2) #seek_cur
					)
					
					print ("Vehicle block offset: " + (ftell in_file) as string)
					
					for v = 1 to vehicle_blocks do
					(
						fseek in_file 95 #seek_cur
						vehicle_animations = readByte in_file #unsigned
						fseek in_file 11 #seek_cur
						vehicle_suspension_animations = readByte in_file #unsigned
						fseek in_file 8 #seek_cur
						fseek in_file (vehicle_animations * 2) #seek_cur
						fseek in_file (vehicle_suspension_animations * 20) #seek_cur
					)
					
					print ("Device block offset: " + (ftell in_file) as string)
					
					for d = 1 to device_blocks do
					(
						fseek in_file 87 #seek_cur
						device_animations = readByte in_file #unsigned
						fseek in_file 8 #seek_cur
						fseek in_file (device_animations * 2) #seek_cur
					)
					
					print ("Unit damage block offset: " + (ftell in_file) as string)
					
					fseek in_file (unit_damage_blocks * 2) #seek_cur
					
					print ("FP weapon block offset: " + (ftell in_file) as string)
					
					for f = 1 to fp_weapon_blocks do
					(
						fseek in_file 19 #seek_cur
						fp_weapon_animations = readByte in_file #unsigned
						fseek in_file 8 #seek_cur
						fseek in_file (fp_weapon_animations * 2) #seek_cur
					)
					
					print ("Sound reference block offset: " + (ftell in_file) as string)
					
					fseek in_file (sound_reference_blocks * 20) #seek_cur
					for s = 1 to sound_reference_blocks do
					(
						readString in_file
					)
					
					loadGBXmodel = false
					gbx_file = undefined
					if node_blocks == 0 then
					(
						gbx_name = ceRoot + "tags\\" + tagLoc + tagName + ".gbxmodel"
						gbx_file = fopen gbx_name "rb"
						if gbx_file == undefined then
						(
							loadGBXmodel = queryBox ("This model_animations tag has no defined nodes and its corresponding gbxmodel tag could be located.  \n\n" + \
								"It is not possible to import or save an animation without a defined node set. To continue loading the animation,  \n" + \
								"click 'Yes' and navigate to the animation's corresponding gbxmodel tag. Otherwise, click 'No' to cancel.") \
								title:"Animation processing error"
							if loadGBXmodel == true then
							(
								gbx_name = getOpenFileName \
									filename: (ceRoot + "tags\\" + tagLoc) \
									types: "GBXModel Tag (*.gbxmodel)|*.gbxmodel|All Tag Files (*.*)|*.*"
								if gbx_name != undefined then
								(
									gbx_file = fopen gbx_name "rb"
								)
								else
								(
									messageBox "Error in opening file! Animation loading terminated." title:"File opening error"
									loadGBXmodel = false
								)
							)
						)
						else
						(
							loadGBXmodel = true
						)
						
						if loadGBXmodel == true then
						(
							print ("Node data retrieved from GBXModel: " + gbx_name as string)
							fseek gbx_file 36 #seek_set
							tag_type = readLong gbx_file
							print ("GBXModel tag type check: " + tag_type as string)
							
							if tag_type != 845442925 then
							(
								messageBox "Error: Incorrect file type! Animation loading terminated.  " \
									title:"Incorrect file type error"
								loadGBXmodel = false
								fclose gbx_file
							)
						)
					)
					if node_blocks != 0 or loadGBXmodel != false then
					(
						print ("Node block offset: " + (ftell in_file) as string)
						
						if node_blocks != 0 then
						(
							for n = 1 to node_blocks do
							(
								offset = (ftell in_file)
								node_name[n] = readString in_file
								fseek in_file (offset + 32) #seek_set
								node_next_sib_index[n] = readShortB "#signed"
								node_first_child_index[n] = readShortB "#signed"
								node_parent_index[n] = readShortB "#signed"
								fseek in_file 26 #seek_cur
							)
						)
						else
						(
							fseek gbx_file 239 #seek_set
							gbx_marker_blocks = readByte gbx_file #unsigned
							fseek gbx_file 251 #seek_set
							gbx_node_blocks = readByte gbx_file #unsigned
							fseek gbx_file 296 #seek_set
							
							gbx_marker_instance_blocks = 0
							for m = 1 to gbx_marker_blocks do
							(
								fseek gbx_file 55 #seek_cur
								gbx_marker_instance_blocks += readByte gbx_file #unsigned
								fseek gbx_file 8 #seek_cur
							)
							
							fseek gbx_file (gbx_marker_instance_blocks * 32) #seek_cur
							
							for n = 1 to gbx_node_blocks do
							(
								offset = (ftell gbx_file)
								node_name[n] = readString gbx_file
								fseek gbx_file (offset + 33) #seek_set
								node_next_sib_index[n] = readByte gbx_file #signed
								fseek gbx_file 1 #seek_cur
								node_first_child_index[n] = readByte gbx_file #signed
								fseek gbx_file 1 #seek_cur
								node_parent_index[n] = readByte gbx_file #signed
								fseek gbx_file 118 #seek_cur
							)
							fclose gbx_file
						)
						
						print ("Animation block offset: " + (ftell in_file) as string)
						
						for a = 1 to animation_blocks do
						(
							offset = (ftell in_file)
							animation_name[a] = readString in_file
							fseek in_file (offset + 32) #seek_set
							animation_type[a] = readShortB "#unsigned"
							animation_frame_count[a] = readShortB "#unsigned"
							animation_frame_size[a] = readShortB "#unsigned"
							animation_frame_info_type[a] = readShortB "#unsigned"
							if a == 1 then
							(
								node_list_checksum = readLongB "#unsigned"
								node_count = readShortB "#unsigned"
							)
							else
							(
								fseek in_file 6 #seek_cur
							)
							fseek in_file 12 #seek_cur
							flags = readShortB "#unsigned"
							animation_flags[a] = getFlagArray flags
							fseek in_file 12 #seek_cur
							animation_frame_info_size[a] = readLongB "#unsigned"
							fseek in_file 16 #seek_cur
							node_trans_flag_data[a] = readFlagData()
							fseek in_file 8 #seek_cur
							node_rotation_flag_data[a] = readFlagData()
							fseek in_file 8 #seek_cur
							node_scale_flag_data[a] = readFlagData()
							fseek in_file 4 #seek_cur
							offset_to_compressed_data = readLongB "#unsigned"
							animation_default_data_size[a] = readLongB "#unsigned"
							fseek in_file 16 #seek_cur
							animation_frame_data_size[a] = readLongB "#unsigned"
							fseek in_file 16 #seek_cur
						)
						
						for a = 1 to animation_blocks do
						(
							frame_info_offset[a] = ftell in_file
							fseek in_file animation_frame_info_size[a] #seek_cur
							default_data_offset[a] = ftell in_file
							fseek in_file animation_default_data_size[a] #seek_cur
							frame_data_offset[a] = ftell in_file
							fseek in_file animation_frame_data_size[a] #seek_cur
						)
						
						print ("-------------------------------------------------------")
						
						unload_button.enabled = true
						grp_animinfo.enabled = true
						ddl_select.enabled = true
						ddl_select.items = animation_name
						ddl_select.selection = 1
						lbl_animtype.enabled = true
						lbl_framecount.enabled = true
						edt_type.text = " " + getAnimType 1
						edt_frame_count.text = " " + animation_frame_count[1] as string
						
						if maxver[1] > 4200 then
						(
							chk_all.enabled = true
							chk_jma.enabled = true
						)
						
						grp_exportoptions.enabled = true
						chk_stream.enabled = true
						save_button.enabled = true
							
						grp_importoptions.enabled = true
						import_button.enabled = true
						chk_finfo.enabled = true
						
						if animation_type[1] == 1 then
						(
							chk_finfo.checked = false
							chk_finfo.enabled = false
							chk_fbase.checked = false
							chk_fbase.enabled = false
							chk_fdefault.enabled = true
							chk_fdefault.checked = true
						)
						else
						(
							if animation_frame_info_type[1] >= 1 then
							(
								chk_finfo.enabled = true
							)
							else
							(
								chk_finfo.checked = false
								chk_finfo.enabled = false
							)
							chk_fbase.enabled = true
							chk_fdefault.enabled = false
							chk_fdefault.checked = false
						)
						
						if animation_flags[1][1] == true and (hasNoData 1) == true then
						(
							messageBox ("Error: Animation is compressed and has lost its uncompressed data (i.e. it was extracted from a map).  \n\n" + \
								"Animation data cannot be read or processed. ") \
								title: "Compressed data error"
							save_button.enabled = false
							import_button.enabled = false
						)
						
					)
				)
			)
		)
	)
	on unload_button pressed do
	(
		unload_button.enabled = false
		grp_animinfo.enabled = false
		ddl_select.selected = " "
		ddl_select.enabled = false
		lbl_animtype.enabled = false
		lbl_framecount.enabled = false
		edt_type.text = " "
		edt_frame_count.text = " "
		
		grp_exportoptions.enabled = false
		chk_all.enabled = false
		chk_jma.enabled = false
		chk_stream.enabled = false
		save_button.enabled = false
		
		grp_importoptions.enabled = false
		import_button.enabled = false
		chk_finfo.enabled = false
		chk_fdefault.enabled = false
		chk_fbase.enabled = false
		
		fclose in_file
	)
	on ddl_select selected i do
	(
		save_button.enabled = true
		import_button.enabled = true
		animType = getAnimType i
		edt_type.text = " " + animType
		edt_frame_count.text = " " + animation_frame_count[i] as string
		if animation_type[i] == 1 then
		(
			chk_finfo.checked = false
			chk_finfo.enabled = false
			chk_fbase.checked = false
			chk_fbase.enabled = false
			chk_fdefault.enabled = true
			chk_fdefault.checked = true
		)
		else
		(
			if animation_frame_info_type[i] >= 1 then
			(
				chk_finfo.enabled = true
			)
			else
			(
				chk_finfo.checked = false
				chk_finfo.enabled = false
			)
			chk_fbase.enabled = true
			chk_fdefault.enabled = false
			chk_fdefault.checked = false
		)
		if animation_flags[i][1] == true and (hasNoData i) == true then
		(
			messageBox ("Error: Animation is compressed and has lost its uncompressed data (i.e. it was extracted from a map).  \n\n" + \
				"Animation data cannot be read or processed. ") \
				title: "Compressed data error"
			save_button.enabled = false
			import_button.enabled = false
		)
	)
	on chk_jma changed theState do
	(
		if theState == true then
		(
			chk_stream.checked = false
			chk_all.enabled = true
		)
		else
		(
			chk_stream.checked = true
			chk_all.checked = false
			chk_all.enabled = false
		)
	)
	on chk_stream changed theState do
	(
		if theState == true then
		(
			chk_jma.checked = false
			chk_all.checked = false
			chk_all.enabled = false
		)
		else
		(
			if chk_jma.enabled == true then
			(
				chk_jma.checked = true
				chk_all.enabled = true
			)
			else
			(
				chk_stream.checked = true
			)
		)
	)
	on save_button pressed do
	(
		if chk_jma.checked == true then
		(
			if chk_all.checked == true then
			(
				output_name = getSavePath caption:"Select a folder in which to save all animations." \
					initialDir:(ceRoot + "data\\" + tagLoc + "animations\\")
			)
			else
			(
				theID = ddl_select.selection
				output_name = getSaveFileName caption:"Select File to Export" \
					filename: (ceRoot + "data\\" + tagLoc + "animations\\" + animation_name[theID]) \
					types:("BlueStreak Animation Exporter (*." + (getAnimType theID) + ")|*." + (getAnimType theID) + "|All Files (*.*)|*.*|")
			)
		)
		
		if output_name == undefined and chk_jma.checked == true then
		(
			messageBox "Failed to create file path" title:"Export error"
		)
		else
		(
			start1 = timeStamp()
			ProgressStart "Exporting Animation Data"
			
			save_array = #()
			
			if chk_all.checked == true then
			(
				for i = 1 to animation_name.count do
				(
					append save_array i
				)
			)
			else
			(
				theID = ddl_select.selection
				save_array[1] = theID
			)
			
			animation_blocks = save_array.count
			for a = 1 to animation_blocks do
			(
				animID = save_array[a]
				parseAnimationData animID
				animType = getAnimType animID
				frame_count = animation_frame_count[animID]
				frame_info_type = animation_frame_info_type[animID]
				
				if chk_jma.checked == true then
				(
					if chk_all.checked == true then
					(
						jma = createfile (output_name + "\\" + animation_name[animID] + "." + animType)
					)
					else
					(
						jma = createfile output_name
					)
				)
				else
				(
					ClearListener()
					jma = listener
				)
				
				-- Start animation file writing --
				
				format "%\n" 16392 to:jma
				format "%\n" (frame_count + 1) to:jma
				format "%\n" 30 to:jma
				format "%\n" 1 to:jma
				format "%\n" "unnamedActor" to:jma
				format "%\n" node_count to:jma
				format "%\n" node_list_checksum to:jma
				
				for n = 1 to node_count do
				(
					format "%\n" node_name[n] to:jma
					format "%\n" node_first_child_index[n] to:jma
					format "%\n" node_next_sib_index[n] to:jma
				)
				if animation_type[animID] == 1 then
				(
					for n = 1 to node_count do
					(
						if node_trans_flag_data[animID][n] == true then
						(
							format "%\t%\t%\n" 0.0 0.0 0.0 to:jma
						)
						else
						(
							format "%\t%\t%\n" node_default_translation[n].x node_default_translation[n].y node_default_translation[n].z to:jma
						)
						if node_rotation_flag_data[animID][n] == true then
						(
							format "%\t%\t%\t%\n" 0.0 0.0 0.0 1.0 to:jma
						)
						else
						(
							format "%\t%\t%\t%\n" node_default_rotation[n].x node_default_rotation[n].y node_default_rotation[n].z node_default_rotation[n].w to:jma
						)
						if node_scale_flag_data[animID][n] == true then
						(
							format "%\n" 1.0 to:jma
						)
						else
						(
							format "%\n" node_default_scale[n].x to:jma
						)
					)
				)
				for f = 1 to frame_count do
				(
					for n = 1 to node_count do
					(
						if n == 1 and frame_info_type >= 1 then
						(
							dx = 0
							dy = 0
							dz = 0
							for i = 1 to (f-1) do
							(
								dx += frame_info_dx[i]
							)
							for i = 1 to (f-1) do
							(
								dy += frame_info_dy[i]
							)
							if frame_info_type == 3 then
							(
								for i = 1 to (f-1) do
								(
									dz += frame_info_dz[i]
								)
							)
							otrans = frame_node_translation[f][n]
							trans = [otrans.x + dx, otrans.y + dy, otrans.z + dz]
							format "%\t%\t%\n" trans.x trans.y trans.z to:jma
						)
						else
						(
							format "%\t%\t%\n" frame_node_translation[f][n].x frame_node_translation[f][n].y frame_node_translation[f][n].z to:jma
						)
						
						if n == 1 and frame_info_type >= 2 then
						(
							dyaw = 0
							for i = 1 to (f-1) do
							(
								dyaw += frame_info_dyaw[i]
							)
							rot = (angleaxis -dyaw [1,0,0]) as quat + frame_node_rotation[f][n]
							format "%\t%\t%\t%\n" rot.x rot.y rot.z rot.w to:jma
						)
						else
						(
							rot = frame_node_rotation[f][n]
							format "%\t%\t%\t%\n" rot.x rot.y rot.z rot.w to:jma
						)
						
						format "%\n" frame_node_scale[f][n].x to:jma
					)
					ProgressUpdate ((((f as float / frame_count) + a as float) / animation_blocks) * 100.0)
				)
				if animation_type[animID] == 0 or animation_type[animID] == 2 then
				(
					for n = 1 to node_count do
					(
						if n == 1 and frame_info_type >= 1 then
						(
							dx = 0
							dy = 0
							dz = 0
							for i = 1 to frame_count do
							(
								dx += frame_info_dx[i]
							)
							for i = 1 to frame_count do
							(
								dy += frame_info_dy[i]
							)
							if frame_info_type == 3 then
							(
								for i = 1 to frame_count do
								(
									dz += frame_info_dz[i]
								)
							)
							otrans = frame_node_translation[1][n]
							trans = [otrans.x + dx, otrans.y + dy, otrans.z + dz]
							format "%\t%\t%\n" trans.x trans.y trans.z to:jma
						)
						else
						(
							format "%\t%\t%\n" frame_node_translation[1][n].x frame_node_translation[1][n].y frame_node_translation[1][n].z to:jma
						)
						
						if n == 1 and frame_info_type >= 2 then
						(
							dyaw = 0
							for i = 1 to frame_count do
							(
								dyaw += frame_info_dyaw[i]
							)
							rot = (angleaxis -dyaw [1,0,0]) as quat + frame_node_rotation[1][n]
							format "%\t%\t%\t%\n" rot.x rot.y rot.z rot.w to:jma
						)
						else
						(
							format "%\t%\t%\t%\n" frame_node_rotation[1][n].x frame_node_rotation[1][n].y frame_node_rotation[1][n].z frame_node_rotation[1][n].w to:jma
						)
						
						format "%\n" frame_node_scale[1][n].x to:jma
					)
				)
				
				-- End animation file writing --
				
				if chk_jma.checked == true then
				(
					close jma
				)
				
			)
			
			ProgressEnd()
			
			end1 = timeStamp()
			print ("Export time: " + ((end1 - start1) as float / 1000.0) as string + " seconds")
		)
	)
	on chk_finfo changed theState do
	(
		if theState == true and chk_fbase.enabled == true then
		(
			chk_fbase.checked = true
		)
	)
	on chk_fbase changed theState do
	(
		if theState == true and chk_finfo.enabled == true then
		(
			chk_finfo.checked = true
		)
	)
	on import_button pressed do
	(
		errorString = "Error: The following problems prevented the animation from importing:  \n\n"
		warningString = "Warning: The following issues may require your attention:  \n\n"
		import_failed = false
		show_warning = false
		
		animID = ddl_select.selection
		parseAnimationData animID
		animType = getAnimType animID
		frame_count = animation_frame_count[animID]
		frame_info_type = animation_frame_info_type[animID]
		
		dontImportNode = #()
		
		for n = 1 to node_count do
		(
			if maxver[1] > 4200 then
			(
				if (getNodeByName node_name[n] all:true).count > 1 then
				(
					messageBox ("Warning: Found multiple nodes with the name '" + node_name[n] + "'. The first will be used for animating.") \
						title:"Multiple node error"
				)
			)
			theNode = getNodeByName node_name[n]
			if theNode != undefined then
			(
				node_array[n] = theNode
				if theNode.parent != undefined then
				(
					if (theNode.parent != getNodeByName node_name[node_parent_index[n]+1]) and (node_name[n] as name != node_name[node_parent_index[n]+1] as name) then
					(
						warningString += "Node '" + node_name[n] + "' should be a child of node '" + node_name[node_parent_index[n]+1] + "'.  \n"
						show_warning = true
					)
				)
			)
			else
			(
				warningString += "Couldn't find node '" + node_name[n] + "' in scene.  \n"
				append dontImportNode n
				show_warning = true
			)
		)
		
		if import_failed == true then
		(
			messageBox errorString title:"Import failed"
		)
		else
		(
			if show_warning == true then
			(
				if (queryBox (warningString + "\nProceed?") title:"Import caution") == true then
				(
					import_failed = false
				)
				else
				(
					import_failed = true
				)
			)
			if import_failed == true then
			(
				messageBox "You cancelled the animation import.  " title:"Import failed"
			)
			else
			(
				start2 = timeStamp()
				max create mode
				
				if chk_fbase.checked == true or chk_fdefault.checked == true then
				(
					animationRange = (interval 0 frame_count)
				)
				else
				(
					animationRange = (interval 0 (frame_count - 1))
				)
				animButtonState = true
				sliderTime = 0
				
				for n = 1 to node_count do
				(
					if findItem dontImportNode n == 0 then
					(
						if classOf node_array[n] == Biped_Object then
						(
							biped.deleteKeys node_array[n].controller #allKeys
							node_array[n].controller.rootNode.controller.figureMode = false
						)
						else
						(
							deleteKeys node_array[n].controller #allKeys
						)
					)
				)
				if (animation_type[animID] == 1) and chk_fdefault.checked == true then
				(
					for n = 1 to node_count do
					(
						if findItem dontImportNode n == 0 then
						(
							select node_array[n]
							if node_rotation_flag_data[animID][n] == true then
							(
								if classOf node_array[n] == Biped_Object then
								(
									rotateBipedCoordParent node_array[n] (quat 0.0 0.0 0.0 1.0)
								)
								else
								(
									in coordsys parent node_array[n].rotation = (quat 0.0 0.0 0.0 1.0)
								)
							)
							else
							(
								rot = node_default_rotation[n]
								mod_rot = (quat -rot.x -rot.y -rot.z rot.w)
								if classOf node_array[n] == Biped_Object then
								(
									rotateBipedCoordParent node_array[n] rot
								)
								else
								(
									in coordsys parent node_array[n].rotation = mod_rot
								)
							)
							if node_trans_flag_data[animID][n] == true then
							(
								if classOf node_array[n] == Biped_Object then
								(
									moveBipedCoordParent node_array[n] [0.0,0.0,0.0]
								)
								else
								(
									in coordsys parent node_array[n].pos = [0.0,0.0,0.0]
								)
							)
							else
							(
								if classOf node_array[n] == Biped_Object then
								(
									moveBipedCoordParent node_array[n] node_default_translation[n]
								)
								else
								(
									in coordsys parent node_array[n].pos = node_default_translation[n]
								)
							)
							
							if node_scale_flag_data[animID][n] == true then
							(
								if classOf node_array[n] != Biped_Object then
								(
									in coordsys parent node_array[n].scale = 1.0
								)
							)
							else
							(
								if classOf node_array[n] != Biped_Object then
								(
									in coordsys parent node_array[n].scale = node_default_scale[n]
								)
							)
							clearSelection()
						)
					)
					sliderTime += 1
				)
				for f = 1 to frame_count do
				(
					for n = 1 to node_count do
					(
						if findItem dontImportNode n == 0 then
						(
							select node_array[n]
							if n == 1 and frame_info_type >= 2 then
							(
								dyaw = 0
								if chk_finfo.checked == true then
								(
									for i = 1 to (f-1) do
									(
										dyaw += frame_info_dyaw[i]
									)
								)
								rot = (angleaxis -dyaw [1,0,0]) as quat + frame_node_rotation[f][n]
								mod_rot = (quat -rot.x -rot.y -rot.z rot.w)
								if classOf node_array[n] == Biped_Object then
								(
									rotateBipedCoordParent node_array[n] rot
								)
								else
								(
									in coordsys parent node_array[n].rotation = mod_rot
								)
							)
							else
							(
								rot = frame_node_rotation[f][n]
								mod_rot = (quat -rot.x -rot.y -rot.z rot.w)
								if classOf node_array[n] == Biped_Object then
								(
									rotateBipedCoordParent node_array[n] rot
								)
								else
								(
									in coordsys parent node_array[n].rotation = mod_rot
								)
							)
							
							if n == 1 and frame_info_type >= 1 then
							(
								dx = 0
								dy = 0
								dz = 0
								if chk_finfo.checked == true then
								(
									for i = 1 to (f-1) do
									(
										dx += frame_info_dx[i]
									)
									for i = 1 to (f-1) do
									(
										dy += frame_info_dy[i]
									)
									if frame_info_type == 3 then
									(
										for i = 1 to (f-1) do
										(
											dz += frame_info_dz[i]
										)
									)
								)
								otrans = frame_node_translation[f][n]
								trans = [otrans.x + dx, otrans.y + dy, otrans.z + dz]
								if classOf node_array[n] == Biped_Object then
								(
									moveBipedCoordParent node_array[n] trans
								)
								else
								(
									in coordsys parent node_array[n].pos = trans
								)
							)
							else
							(
								if classOf node_array[n] == Biped_Object then
								(
									moveBipedCoordParent node_array[n] frame_node_translation[f][n]
								)
								else
								(
									in coordsys parent node_array[n].pos = frame_node_translation[f][n]
								)
							)
							
							if classOf node_array[n] != Biped_Object then
							(
								in coordsys parent node_array[n].scale = frame_node_scale[f][n]
							)
							
							clearSelection()
						)
					)
					sliderTime += 1
				)
				if (animation_type[animID] == 0 or animation_type[animID] == 2) and chk_fbase.checked == true then
				(
					for n = 1 to node_count do
					(
						if findItem dontImportNode n == 0 then
						(
							select node_array[n]
							if n == 1 and frame_info_type >= 2 then
							(
								dyaw = 0
								if chk_finfo.checked == true then
								(
									for i = 1 to frame_count do
									(
										dyaw += frame_info_dyaw[i]
									)
								)
								rot = (angleaxis -dyaw [1,0,0]) as quat + frame_node_rotation[1][n]
								mod_rot = (quat -rot.x -rot.y -rot.z rot.w)
								if classOf node_array[n] == Biped_Object then
								(
									rotateBipedCoordParent node_array[n] rot
								)
								else
								(
									in coordsys parent node_array[n].rotation = mod_rot
								)
							)
							else
							(
								rot = frame_node_rotation[1][n]
								mod_rot = (quat -rot.x -rot.y -rot.z rot.w)
								if classOf node_array[n] == Biped_Object then
								(
									rotateBipedCoordParent node_array[n] rot
								)
								else
								(
									in coordsys parent node_array[n].rotation = mod_rot
								)
							)
							
							if n == 1 and frame_info_type >= 1 then
							(
								dx = 0
								dy = 0
								dz = 0
								if chk_finfo.checked == true then
								(
									for i = 1 to frame_count do
									(
										dx += frame_info_dx[i]
									)
									for i = 1 to frame_count do
									(
										dy += frame_info_dy[i]
									)
									if frame_info_type == 3 then
									(
										for i = 1 to frame_count do
										(
											dz += frame_info_dz[i]
										)
									)
								)
								otrans = frame_node_translation[1][n]
								trans = [otrans.x + dx, otrans.y + dy, otrans.z + dz]
								if classOf node_array[n] == Biped_Object then
								(
									moveBipedCoordParent node_array[n] trans
								)
								else
								(
									in coordsys parent node_array[n].pos = trans
								)
							)
							else
							(
								if classOf node_array[n] == Biped_Object then
								(
									moveBipedCoordParent node_array[n] frame_node_translation[1][n]
								)
								else
								(
									in coordsys parent node_array[n].pos = frame_node_translation[1][n]
								)
							)
							
							if classOf node_array[n] != Biped_Object then
							(
								in coordsys parent node_array[n].scale = frame_node_scale[1][n]
							)
							
							clearSelection()
						)
					)
					sliderTime += 1
				)
				
				animButtonState = false
				
				end2 = timeStamp()
				print ("Animation took " + ((end2 - start2) as float / 1000.0) as string + " seconds to import.")
			)
		)
	)
)


CreateDialog roll

-- End of Script --