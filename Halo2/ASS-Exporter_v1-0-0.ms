--***************************************************************************
--*					 BlueStreak .ASS Exporter by TheGhost					*
--*					   for 3ds Max v6+ and Halo 2 Vista						*
--***************************************************************************
--*		Description: Exports an ASS representation of a 3ds max scene.		*
--*-------------------------------------------------------------------------*
--*	Submit bugs to TheGhost on the Halo 2 Vista forums. Visit the forums 	*
--* for additional help at http://www.h2vista.net.							*
--*-------------------------------------------------------------------------*
--* Copyright (C) 2006 Adam Papamarcos (mailto:papamarcos@gmail.com)		*
--*	This program is free software; you can redistribute it and/or modify it	*
--*	under the terms of the GNU General Public License as published by the	*
--*	Free Software Foundation; either version 2 of the License, or (at your	*
--*	option) any later version. This program is distributed in the hope that	*
--*	it will be useful, but WITHOUT ANY WARRANTY; without even the implied	*
--*	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See	*
--*	the GNU General Public License for more details. A full copy of this	*
--*	license is available at http://www.gnu.org/licenses/gpl.txt.			*
--*-------------------------------------------------------------------------*

-- Script Version 1.0.0

objs = #()
materials = #()
ass = undefined
exportFailed = false
maxver = maxVersion()

numDecimalPlaces = 10
fn uniStr dbl =
(
	local strRep = dbl as string
	if (findString strRep "e" == undefined) then
	(
		local strInd = findString strRep "."
		local currDecPlaces = strRep.count - strInd
		local zerosToAdd = numDecimalPlaces - currDecPlaces
		for z = 1 to zerosToAdd do
		(
			append strRep "0"
		)
	)
	strRep
)

eps = 0.00001
fn numsAreClose n1 n2 =
(
	(abs(n1 - n2) <= eps)
)


rollout roll "BlueStreak .ASS Exporter" width:255 height:293
(
	GroupBox grp1 "" pos:[7,-1] width:239 height:34
	label lbl_title "BlueStreak .ASS Exporter" pos:[61,13] width:129 height:13
	edittext edt_info "" pos:[3,40] width:243 height:191 enabled:true
	button export_button "Export .ASS File" pos:[63,239] width:128 height:31
	label lbl_by "Script by TheGhost" pos:[7,275] width:101 height:14 enabled:false
	label lbl5 "v1.0.0" pos:[211,275] width:38 height:14 enabled:false
	
	on roll open do
	(
		ClearListener()
		edt_info.text += "3ds Max version " + (maxver[1] / 1000.0) as string + " detected.\r\n"
	)
	on export_button pressed do
	(
		objs = #()
		materials = #()
		ass = undefined
		exportFailed = false
	
		local output_name = getSaveFileName caption:"Select File to Export" \
			filename: "C:\\Program Files\\Microsoft Games\\Halo 2 Map Editor\\data\\" \
			types:("BlueStreak ASS (*.ASS)|*.ASS|All Files (*.*)|*.*|")
		
		if (output_name == undefined) then
		(
			messageBox "Failed to create file path" title:"BlueStreak: Export error"
			exportFailed = true
		)
		
		if (exportFailed != true) then
		(
			edt_info.text += "Exporting to " + output_name + "\r\n\r\n"
			
			ass = createfile output_name
			format "%\n" ";### HEADER ###" to:ass
			format "%\n" 2 to:ass
			format "%\n" "\"MAX\"" to:ass
			format "%\n" ("\"" + (maxver[1] / 1000.0) as string + "\"") to:ass
			format "%\n" ("\"" + sysInfo.username as string + "\"") to:ass
			format "%\n\n" ("\"" + sysInfo.computername as string + "\"") to:ass
			
			clearListener()
			clearSelection()
			max select all
			objs = selection as array
			clearSelection()
			
			local sub_slot_name = #()
			
			for i = 1 to objs.count do
			(
				local tmesh = snapshotAsMesh objs[i]
				if (objs[i].material != undefined) then
				(
					if (classOf objs[i].material == Multimaterial) then
					(
						for m = 1 to objs[i].material.count do
						(
							local extent
							if (classOf objs[i] == Sphere or classOf objs[i] == Box or classOf objs[i] == Cylinder) then
							(
								extent = 1
							)
							else
							(
								extent = getNumFaces tmesh
							)
							
							for f = 1 to extent do
							(
								matID = getFaceMatID tmesh f
								if (findItem materials objs[i].material[matID] == 0) then
								(
									append materials objs[i].material[matID]
									local full_ssn = getSubMtlSlotName objs[i].material matID
									local ssn = substring full_ssn (4 + (matID as string).count) -1
									append sub_slot_name ssn
								)
							)
						)
					)
					else
					(
						if (findItem materials objs[i].material == 0) then
						(
							append materials objs[i].material
							append sub_slot_name ""
						)
					)
				)
			)
			
			format "%\n" ";### MATERIALS ###" to:ass
			format "%\n\n" materials.count to:ass
			
			for m = 1 to materials.count do
			(
				format "%\n" (";MATERIAL " + (m - 1) as string) to:ass
				format "%\n" ("\"" + materials[m].name as string + "\"") to:ass
				format "%\n\n" ("\"" + sub_slot_name[m] as string + "\"") to:ass
			)
			
			format "%\n" ";### OBJECTS ###" to:ass
			format "%\n" objs.count to:ass
			
			for j = 1 to objs.count do
			(
				format "\n%\n" (";OBJECT " + (j - 1) as string + " - '" + objs[j].name + "'") to:ass
				
				edt_info.text += ("Object " + j as string + ": \"" + objs[j].name + "\"\r\n")
				
				local tmesh = snapshotAsMesh objs[j]
				
				if (classOf objs[j] == Sphere or classOf objs[j] == Box or classOf objs[j] == Cylinder) then
				(
					local material_index
					
					if (classOf objs[j].material == Multimaterial) then
					(
						for m = 1 to objs[j].material.count do
						(
							matID = getFaceMatID tmesh 1
							material_index = findItem materials objs[j].material[matID]
						)
					)
					else
					(
						material_index = findItem materials objs[j].material
					)
					
					material_index -= 1
					if (classOf objs[j] == Sphere) then
					(
						edt_info.text += "Type: Sphere\r\n\r\n"
						format "%\n" "\"SPHERE\"" to:ass
						format "%\n" "\"\"" to:ass
						format "%\n" "\"\"" to:ass
						format "%\n" material_index to:ass
						format "%\n" (uniStr objs[j].radius) to:ass
					)
					else
					(
						if (classOf objs[j] == Box) then
						(
							edt_info.text += "Type: Box\r\n\r\n"
							format "%\n" "\"BOX\"" to:ass
							format "%\n" "\"\"" to:ass
							format "%\n" "\"\"" to:ass
							format "%\n" material_index to:ass
							format "%\t%\t%\n" (uniStr (objs[j].length / 2.0)) (uniStr (objs[j].width / 2.0)) (uniStr (objs[j].height / 2.0)) to:ass
						)
						else
						(
							edt_info.text += "Type: Pill\r\n\r\n"
							format "%\n" "\"PILL\"" to:ass
							format "%\n" "\"\"" to:ass
							format "%\n" "\"\"" to:ass
							format "%\n" material_index to:ass
							format "%\n" (uniStr objs[j].height) to:ass
							format "%\n" (uniStr objs[j].radius) to:ass
						)
					)
				)
				
				else
				(
					edt_info.text += "Type: Mesh\r\n"
					format "%\n" "\"MESH\"" to:ass
					format "%\n" "\"\"" to:ass
					format "%\n" "\"\"" to:ass
					
					local xyz = #()
					local ijk = #()
					local uvw = #()
					
					local vertIndex_uniqueVert_map = #()
					
					local numUniqueVerts = 0
					local uniqueVert_vertIndex = #()
					local uniqueVert_normalID = #()
					local uniqueVert_tvertUV = #()
					
					local face_vert_indices = #()
					local face_shader_index = #()
					
					local numFaces = getNumFaces tmesh
					local en = Edit_Normals()
					addModifier objs[j] en
					
					select objs[j]
					max modify mode
					subobjectLevel = 1
					
					for f = 1 to numFaces do
					(
						local verts = getFace tmesh f
						local tverts = getTVFace tmesh f
						local matID = getFaceMatID tmesh f
						
						local vert_indices = #()
						
						for v = 1 to 3 do
						(
							local vert_index = verts[v]
							local normal_index = en.getNormalID f v
							local tvert_index = tverts[v]
							
							local tvertUV = [(getTVert tmesh tvert_index).x,(getTVert tmesh tvert_index).y]
							
							if (vertIndex_uniqueVert_map[vert_index] == undefined) then
							(
								numUniqueVerts += 1
								vertIndex_uniqueVert_map[vert_index] = #(numUniqueVerts)
								vert_indices[v] = numUniqueVerts
								uniqueVert_vertIndex[numUniqueVerts] = vert_index
								uniqueVert_normalID[numUniqueVerts] = normal_index
								uniqueVert_tvertUV[numUniqueVerts] = tvertUV
							)
							else
							(
								local uniqueVert = true
								for c = 1 to vertIndex_uniqueVert_map[vert_index].count do
								(
									uniqueVertIndex = vertIndex_uniqueVert_map[vert_index][c]
									
									if (normal_index == uniqueVert_normalID[uniqueVertIndex] and (numsAreClose tvertUV.x uniqueVert_tvertUV[uniqueVertIndex].x) and (numsAreClose tvertUV.y uniqueVert_tvertUV[uniqueVertIndex].y)) then
									(
										uniqueVert = false
										vert_indices[v] = uniqueVertIndex
									)
								)
								if (uniqueVert == true) then
								(
									numUniqueVerts += 1
									append vertIndex_uniqueVert_map[vert_index] numUniqueVerts
									vert_indices[v] = numUniqueVerts
									uniqueVert_vertIndex[numUniqueVerts] = vert_index
									uniqueVert_normalID[numUniqueVerts] = normal_index
									uniqueVert_tvertUV[numUniqueVerts] = tvertUV
								)
							)
						)
						
						face_vert_indices[f] = vert_indices
						face_shader_index[f] = (findItem materials objs[j].material[matID])
					)
					
					edt_info.text += "Unique Vertices: " + numUniqueVerts as string + "\r\n"
					edt_info.text += "Number of Faces: " + numFaces as string + "\r\n\r\n"
					
					format "%\n" numUniqueVerts to:ass
					
					for v = 1 to numUniqueVerts do
					(
						local xyz = in coordsys local (getVert objs[j] uniqueVert_vertIndex[v])
						local ijk = in coordsys local (en.getNormal uniqueVert_normalID[v])
						local uv = uniqueVert_tvertUV[v]
						
						format "%\t%\t%\n" (uniStr xyz.x) (uniStr xyz.y) (uniStr xyz.z) to:ass
						format "%\t%\t%\n" (uniStr ijk.x) (uniStr ijk.y) (uniStr ijk.z) to:ass
						format "%\n" 0 to:ass
						format "%\n" 1 to:ass
						format "%\t%\n" (uniStr uv.x) (uniStr uv.y) to:ass
					)
					
					format "%\n" numFaces to:ass
					
					for f = 1 to numFaces do
					(
						format "%\n" (face_shader_index[f] - 1) to:ass
						format "%\n" (face_vert_indices[f][1] - 1) to:ass
						format "%\n" (face_vert_indices[f][2] - 1) to:ass
						format "%\n" (face_vert_indices[f][3] - 1) to:ass
					)
					
					max create mode
					clearSelection()
					deleteModifier objs[j] en
				)
			)
			
			local numInstances = objs.count
			
			edt_info.text += "Number of Instances: " + numInstances as string + "\r\n"
			
			format "\n%\n" ";### INSTANCES ###" to:ass
			format "%\n\n" (numInstances + 1) to:ass
			
			format "%\n" ";INSTANCE 0" to:ass
			format "%\n" -1 to:ass
			format "%\n" "\"Scene Root\"" to:ass
			format "%\n" -1 to:ass
			format "%\n" -1 to:ass
			format "%\n" 0 to:ass
			format "%\t%\t%\t%\n" "0.0000000000" "0.0000000000" "0.0000000000" "1.0000000000" to:ass
			format "%\t%\t%\n" "0.0000000000" "0.0000000000" "0.0000000000" to:ass
			format "%\n" "1.0000000000" to:ass
			format "%\t%\t%\t%\n" "0.0000000000" "0.0000000000" "0.0000000000" "1.0000000000" to:ass
			format "%\t%\t%\n" "0.0000000000" "0.0000000000" "0.0000000000" to:ass
			format "%\n\n" "1.0000000000" to:ass
			
			for i = 1 to numInstances do
			(
				format "%\n" (";INSTANCE " + (i as string)) to:ass
				format "%\n" (i - 1) to:ass
				format "%\n" ("\"" + objs[i].name + "\"") to:ass
				format "%\n" (123 + i) to:ass
				
				if (objs[i].parent == undefined) then
				(
					format "%\n" 0 to:ass
				)
				else
				(
					format "%\n" (findItem objs objs[i].parent) to:ass
				)
				
				format "%\n" 0 to:ass
				
				local rot = in coordsys parent objs[i].rotation
				local trans = in coordsys parent objs[i].pos
				local scal = in coordsys parent objs[i].scale
				format "%\t%\t%\t%\n" (uniStr rot.x) (uniStr rot.y) (uniStr rot.z) (uniStr rot.w) to:ass
				format "%\t%\t%\n" (uniStr trans.x) (uniStr trans.y) (uniStr trans.z) to:ass
				if (scal.x != scal.y or scal.y != scal.z) then
				(
					messageBox ("Warning: Object '" + objs[i].name + "' does not have a uniform scale in\r\n" \
						+ "the x, y, and z directions. This WILL cause undesired results!") \
						title: "BlueStreak: Critical error"
				)
				format "%\n" (uniStr scal.x) to:ass
				
				local offset_rot = objs[i].objectoffsetrot
				local offset_pos = objs[i].objectoffsetpos
				local offset_scale = objs[i].objectoffsetscale
				
				format "%\t%\t%\t%\n" (uniStr offset_rot.x) (uniStr offset_rot.y) (uniStr offset_rot.z) (uniStr offset_rot.w) to:ass
				format "%\t%\t%\n" (uniStr offset_pos.x) (uniStr offset_pos.y) (uniStr offset_pos.z) to:ass
				format "%\n\n" (uniStr offset_scale.x) to:ass
			)
			
			close ass
		)
	)
)

CreateDialog roll

-- End of Script --