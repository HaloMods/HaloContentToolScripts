--***************************************************************************
--*					  Halo 2 Model Exporter by TheGhost						*
--*					   for 3ds Max v6+ and Halo 2 Vista						*
--***************************************************************************
--*		Features:															*
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


objs = #()
materials = #()

ass = undefined

exportFailed = false

maxver = maxVersion()

fn getFaceSmoothGroupB obj face =
(
	local sgroup_val = getFaceSmoothGroup obj face
	local sg_bitarray = #{}
	if sgroup_val < 0 do
	(
		sg_bitarray[32] = true
		sgroup_val -= 2^31
	)
	for i = 1 to 31 do
	(
		sg_bitarray[i] = (mod sgroup_val 2 > .5)
		sgroup_val /= 2
	)
	sg_bitarray as array
)

eps = 0.00001
fn numsAreClose n1 n2 =
(
	if (abs(n1 - n2) <= eps) then
	(
		true
	)
	else
	(
		false
	)
)

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

rollout roll "BlueStreak .ASS Exporter" width:326 height:439
(
	GroupBox grp1 "" pos:[7,0] width:312 height:34
	label lbl_title "BlueStreak .ASS Exporter" pos:[77,13] width:182 height:13
	edittext edt_info "" pos:[20,58] width:274 height:188 enabled:true
	button export_button "Export .ASS File" pos:[90,369] width:128 height:31
	label lbl_by "Script by TheGhost" pos:[5,421] width:101 height:14 enabled:false
	
	on roll open do
	(
		ClearListener()
		edt_info.text += "3ds Max version " + (maxver[1] / 1000.0) as string + " detected.\r\n"
	)
	on export_button pressed do
	(
		output_name = getSaveFileName caption:"Select File to Export" \
			filename: "C:\\Program Files\\Microsoft Games\\Halo 2 Map Editor\\data\\" \
			types:("BlueStreak ASS (*.ASS)|*.ASS|All Files (*.*)|*.*|")
		
		if (output_name == undefined) then
		(
			messageBox "Failed to create file path" title:"BlueStreak: Export error"
			exportFailed = true
		)
		
		if (exportFailed != true) then
		(
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
									local full_ssn = getSubMtlSlotName objs[i].material matID  -- the sub slot name is appended with the index, remove it
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
				format "%\n" ("\"" + materials[m].name as string + "\"") to:ass  -- shader name
				format "%\n\n" ("\"" + sub_slot_name[m] as string + "\"") to:ass  -- sub-material slot name
			)
			
			format "%\n" ";### OBJECTS ###" to:ass
			format "%\n" objs.count to:ass
			
			for j = 1 to objs.count do
			(
				format "\n%\n" (";OBJECT " + (j - 1) as string + " - '" + objs[j].name + "'") to:ass
				
				local tmesh = snapshotAsMesh objs[j]
				
				-- primative objects
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
					
					material_index -= 1  -- convert to 0-based
					if (classOf objs[j] == Sphere) then
					(
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
							format "%\n" "\"BOX\"" to:ass
							format "%\n" "\"\"" to:ass
							format "%\n" "\"\"" to:ass
							format "%\n" material_index to:ass
							format "%\t%\t%\n" (uniStr (objs[j].length / 2.0)) (uniStr (objs[j].width / 2.0)) (uniStr (objs[j].height / 2.0)) to:ass
						)
						else
						(
							format "%\n" "\"PILL\"" to:ass
							format "%\n" "\"\"" to:ass
							format "%\n" "\"\"" to:ass
							format "%\n" material_index to:ass
							format "%\n" (uniStr objs[j].height) to:ass
							format "%\n" (uniStr objs[j].radius) to:ass
						)
					)
				)
				
				-- mesh objects
				else
				(
					format "%\n" "\"MESH\"" to:ass
					format "%\n" "\"\"" to:ass
					format "%\n" "\"\"" to:ass
					
					
					global xyz = #()
					global ijk = #()
					global uvw = #()
					
					local vertIndex_uniqueVert_map = #()  -- multi-dimensional
					
					local numUniqueVerts = 0					
					global uniqueVert_vertIndex = #()
					global uniqueVert_normalID = #()
					global uniqueVert_tvertUV = #()  --pt2
					
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
						-- local SG = getFaceSmoothGroupB tmesh f
						
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
							
							
							
							
							/*
							local pos = getVert tmesh vert_index
							local norm = en.getNormal normal_index
							local tpos = getTVert tmesh tvert_index
							
							if (vertIndex_uniqueVert_map[vert_index] == undefined) then
							(
								vertIndex_uniqueVert_map[vert_index] = #(numUniqueVerts + 1)
								vert_indices[v] = numUniqueVerts + 1
								numUniqueVerts += 1
								append xyz pos
								append ijk norm
								append uvw tpos
							)
							else
							(
								local uniqueVert = true
								for c = 1 to vertIndex_uniqueVert_map[vert_index].count do
								(
									uniqueVertIndex = vertIndex_uniqueVert_map[vert_index][c]
									
									if ((numsAreClose norm.x ijk[uniqueVertIndex].x) \
										and (numsAreClose norm.y ijk[uniqueVertIndex].y) \
										and (numsAreClose norm.z ijk[uniqueVertIndex].z) \
										and (numsAreClose tpos.x uvw[uniqueVertIndex].x) \
										and (numsAreClose tpos.y uvw[uniqueVertIndex].y)) then
									(
										uniqueVert = false
										vert_indices[v] = uniqueVertIndex
									)
								)
								if (uniqueVert == true) then
								(
									append vertIndex_uniqueVert_map[vert_index] (numUniqueVerts + 1)
									vert_indices[v] = numUniqueVerts + 1
									numUniqueVerts += 1
									append xyz pos
									append ijk norm
									append uvw tpos
								)
							)
							*/
							--local uniqueVert = true
							
							/*
							if (vert_uniqueVert_index[vert_index] == undefined) then  -- every vertex index gets a unique slot; if it is empty, fill it
							(
								vert_uniqueVert_index[vert_index] = numUniqueVerts + 1
								vert_indices[v] = numUniqueVerts + 1
								numUniqueVerts += 1
								append xyz pos
								append ijk norm
								append uvw tpos
							)
							else
							(
								slotVertex = vert_uniqueVert_index[vert_index]  -- this is the index of the vert that exists in the slot, check to see if it's the same as the one being tested
								if ((numsAreClose norm.x ijk[slotVertex].x) \
									and (numsAreClose norm.y ijk[slotVertex].y) \
									and (numsAreClose norm.z ijk[slotVertex].z) \
									and (numsAreClose tpos.x uvw[slotVertex].x) \
									and (numsAreClose tpos.y uvw[slotVertex].y)) then
								(
									vert_uniqueVert_index[vert_index] = slotVertex
									vert_indices[v] = slotVertex
								)
								else
								(
									vert_uniqueVert_index[verts[v]] = numUniqueVerts + 1
									vert_indices[v] = numUniqueVerts + 1
									numUniqueVerts += 1
									append xyz pos
									append ijk norm
									append uvw tpos
								)
							)
							*/
							
							
							
							/*
							vNormal = [0,0,0]
							vNormal += getFaceNormal tmesh f
							simFaces = meshop.getFacesUsingVert tmesh verts[v] as array
							del_index = findItem simFaces f
							deleteItem simFaces del_index
							for s = 1 to simFaces.count do
							(
								affectNormal = false
								neiSG = getFaceSmoothGroupB tmesh simFaces[s]
								for aN = 1 to SG.count do
								(
									if (affectNormal == false) then
									(
										if (findItem neiSG SG[aN] != 0) then
										(
											affectNormal = true
										)
									)
								)
								if (affectNormal == true) then
								(
									vNormal += getFaceNormal tmesh simFaces[s]
								)
							)
							local norm = normalize(vNormal)
							*/
							
							/*
							local uniqueVert = true
							
							
							local checkArray = #()
							for s = 1 to simFaces.count do
							(
								if (simFaces[s] < f) then
								(
									for k = 1 to 3 do
									(
										if (findItem checkArray face_vert_indices[simFaces[s]][k] == 0) then
										(
											append checkArray face_vert_indices[simFaces[s]][k]
										)
									)
								)
							)
							for i = 1 to checkArray.count do
							(
								if (uniqueVert == true) then
								(
									if ((pt3isClose pos xyz[checkArray[i]] 3) and (pt3isClose norm ijk[checkArray[i]] 3) and (pt3isClose tpos uvw[checkArray[i]] 2)) then
									(
										uniqueVert = false
										vert_indices[v] = i
									)
								)
							)
							if (uniqueVert == true) then
							(
								append xyz pos
								append ijk norm
								append uvw tpos
								vert_indices[v] = numUniqueVerts + 1
							)
							
							*/
							
							
							
						)
						
						face_vert_indices[f] = vert_indices
						face_shader_index[f] = (findItem materials objs[j].material[matID])
						
						-- print f to:listener
					)
					
					local numAssVertices = numUniqueVerts
					
					format "%\n" numAssVertices to:ass
					
					for v = 1 to numAssVertices do
					(
						local xyz = in coordsys local (getVert objs[j] uniqueVert_vertIndex[v]) -- can't use tmesh for local vertex pos
						local ijk = in coordsys local (en.getNormal uniqueVert_normalID[v])
						local uv = uniqueVert_tvertUV[v]
						
						format "%\t%\t%\n" (uniStr xyz.x) (uniStr xyz.y) (uniStr xyz.z) to:ass
						format "%\t%\t%\n" (uniStr ijk.x) (uniStr ijk.y) (uniStr ijk.z) to:ass
						format "%\n" 0 to:ass  -- bone influence count
						format "%\n" 1 to:ass  -- texture vertex count
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
				-- end mesh object
				
				
			) -- end objects loop
			
			local numInstances = objs.count
			
			format "\n%\n" ";### INSTANCES ###" to:ass
			format "%\n\n" (numInstances + 1) to:ass  -- root also counts as instance, add 1
			
			-- scene root
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
				
				format "%\n" 0 to:ass  -- inheritance flag, unused
				
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
		
		
		
		if (exportFailed != true) then
		(
			
		)
		
		
		
		/*
		-- in future: re-initialize all variables
		
		ClearListener()
		
		clearSelection()		
		max select all
		all_objects_array = selection as array
		clearSelection()
		
		objectsInScene = all_objects_array.count
		for a = 1 to objectsInScene do  -- find the parent node, check for multiple root frames, check for no parent node
		(
			if (exportFailed != true) then
			(
				objName = all_objects_array[a].name
				
				if (substring objName 1 5 as name == "frame" as name) then
				(
					if (all_objects_array[a].parent == undefined) then
					(
						if frameRoot != undefined then
						(
							messagebox ("There are too many actors in the scene! Can not export single model.\r\n\r\n" \
								+ "Multiple root nodes:\r\n" + frameRoot as string + "\r\n" + all_objects_array[a] as string) \
								title:"BlueStreak Error 1"
							exportFailed = true
						)
						else
						(
							frameRoot = all_objects_array[a]
							edt_info.text += "Parent node: " + frameRoot as string + "\r\n"
						)
					)
				)				
			)
		)
		
		if (exportFailed != true) then
		(
			if (frameRoot == undefined) then
			(
				messageBox ("There are no actors to export!\r\n\r\n" \
					+ "Add a parent node called 'frame' and attach all geometry to it.") \
					title:"BlueStreak Error 2"
				exportFailed = true
			)
		)
		*/
		
		
	)
	
	
	/*
		if exportFailed != true then
		(
			if node_objects.count == 0 then
			(
				messageBox "There are no actors to export!" title:"BlueStreak Error 3"
				exportFailed = true
			)
			else
			(
				if marker_array == undefined and geometry_objects == undefined then
				(
					messageBox "There was no geometry to export." title:"BlueStreak Error 4"
					exportFailed = true
				)
			)
		)
		
		if exportFailed != true then
		(
			-- Sort the nodes the way Halo likes it. The hierarchy level number was added to the beginning of each object's name. Then sort alphabetically.
			for n = 1 to node_objects.count do
			(
				if node_array.count == 0 then
				(
					node_array[n] = node_objects[n]
				)
				else
				(
					added = false
					for c = 1 to node_array.count do
					(
						if added == false then
						(
							if node_objects[n].name as name < node_array[c].name as name then
							(
								insertItem node_objects[n] node_array c
								added = true
							)
							else
							(
								if c == node_array.count then
								(
									append node_array node_objects[n]
								)
							)
						)
					)
				)
			)
			for n = 1 to node_array.count do
			(
				node_array[n].name = substring node_array[n].name 3 -1
			)
			all_valid_nodes = true
			deletedName = " "
			for n = 2 to node_array.count do
			(
				if findItem node_array node_array[n].parent == 0 then
				(
					if all_valid_nodes == true then
					(
						deletedName = node_array[n].name
					)
					node_array[n] = undefined
					all_valid_nodes = false
				)
			)
			if all_valid_nodes == false then
			(
				messageBox ("Can't add frame node \"" + deletedName + "\" because it is hung from a geometry or marker node.") title:"BlueStreak Error"
			)
			for n = node_array.count to 1 by -1 do
			(
				if node_array[n] == undefined then
				(
					deleteItem node_array n
				)
			)
			-- All parent, child, and sibling node arrays are 1-based. When outputting they will be converted to 0-based.
			for n = 1 to node_array.count do
			(
				temp_child_indices = #()
				for c = 1 to node_array[n].children.count do
				(
					
					nodeChild = node_array[n].children[c]
					if nodeChild != undefined then
					(
						childIndex = findItem node_array nodeChild
						if childIndex != 0 then
						(
							append temp_child_indices (childIndex)
						)
					)
				)
				node_child_indices[n] = temp_child_indices
				if node_child_indices[n].count == 0 then
				(
					node_first_child_index[n] = 0
				)
				else
				(
					sort (node_child_indices[n])
					node_first_child_index[n] = node_child_indices[n][1]
				)
			)
			node_next_sibling_index[1] = 0
			for s = 1 to node_child_indices.count do
			(
				if (node_child_indices[s].count < 2 and node_child_indices[s][1] != undefined) then
				(
					node_next_sibling_index[node_child_indices[s][1]] = 0
				)
				else
				(
					for g = 1 to node_child_indices[s].count do
					(
						if g == node_child_indices[s].count then
						(
							node_next_sibling_index[node_child_indices[s][g]] = 0
						)
						else
						(
							node_next_sibling_index[node_child_indices[s][g]] = node_child_indices[s][g+1]
						)
					)
				)
			)
			for m = marker_array.count to 1 by -1 do
			(
				nodeParent = marker_array[m].parent
				while (substring nodeParent.name 1 5 as name != "frame" as name) and (substring nodeParent.name 1 5 as name != "bip01" as name) do
				(
					nodeParent = nodeParent.parent
				)
				parentIndex = findItem node_array nodeParent
				if parentIndex == 0 then
				(
					deleteItem marker_array m
				)
				else
				(
					marker_parent_index[m] = parentIndex
				)
			)
			for g = geometry_objects.count to 1 by -1 do
			(
				nodeParent = geometry_objects[g].parent
				while (substring nodeParent.name 1 5 as name != "frame" as name) and (substring nodeParent.name 1 5 as name != "bip01" as name) do
				(
					nodeParent = nodeParent.parent
				)
				parentIndex = findItem node_array nodeParent
				if parentIndex == 0 then
				(
					deleteItem geometry_objects g
				)
				else
				(
					geom_parent_index[g] = parentIndex
				)
			)
			for n = 1 to node_array.count do
			(
				if node_array[n].parent == undefined then
				(
					if classOf node_array[n] == Biped_Object then
					(
						node_translation[n] = biped.getTransform node_array[n] #pos
						node_rotation[n] = biped.getTransform node_array[n] #rotation
					)
					else
					(
						node_translation[n] = node_array[n].pos
						in coordsys parent rot = normalize (node_array[n].rotation)
						node_rotation[n] = (quat -rot.x -rot.y -rot.z rot.w)
					)
				)
				else
				(
					if classOf node_array[n] == Biped_Object then
					(
						m = mesh vertices:#() faces:#()  --two temporary meshes that serve as placeholders for the
						mp = mesh vertices:#() faces:#()  --biped bones since these methods can not be evoked on them
						m.parent = mp
						mpRot = biped.getTransform node_array[n].parent #rotation
						mp.rotation = (quat -mpRot.x -mpRot.y -mpRot.z mpRot.w)
						mp.pos = biped.getTransform node_array[n].parent #pos
						mRot = biped.getTransform node_array[n] #rotation
						m.rotation = (quat -mRot.x -mRot.y -mRot.z mRot.w)
						m.pos = biped.getTransform node_array[n] #pos
						in coordsys parent node_translation[n] = m.pos
						in coordsys parent rot = m.rotation
						node_rotation[n] = normalize (quat -rot.x -rot.y -rot.z rot.w)
						delete m
						delete mp
					)
					else
					(
						in coordsys parent node_translation[n] = node_array[n].pos
						in coordsys parent rot = node_array[n].rotation
						node_rotation[n] = normalize (quat -rot.x -rot.y -rot.z rot.w)
					)
				)
			)
			for m = 1 to marker_array.count do
			(
				in coordsys parent marker_translation[m] = marker_array[m].pos
				in coordsys parent rot = marker_array[m].rotation
				marker_rotation[m] = normalize (quat -rot.x -rot.y -rot.z rot.w)
			)
		)
		
		if exportFailed != true then
		(
			for g = 1 to geometry_objects.count do
			(
				tmesh = snapshotAsMesh geometry_objects[g]
				if classOf geometry_objects[g].material == Multimaterial then
				(
					for m = 1 to geometry_objects[g].material.count do
					(
						for f = 1 to getNumFaces tmesh do
						(
							matID = getFaceMatID tmesh f
							if findItem geom_materials geometry_objects[g].material[matID] == 0 then
							(
								append geom_materials geometry_objects[g].material[matID]
							)
						)
					)
				)
				else
				(
					if findItem geom_materials geometry_objects[g].material == 0 then
					(
						append geom_materials geometry_objects[g].material
					)
				)
			)
			
			if geometry_objects.count != 0 then
			(
				v = 0
				for g = 1 to geometry_objects.count do
				(
					numFaces += getNumFaces geometry_objects[g]
				)
				for g = 1 to geometry_objects.count do
				(
					tmesh = snapshotAsMesh geometry_objects[g]
					geom_mesh_faces[g] = getNumFaces tmesh
					if getNumTVerts tmesh > 0 do geom_object_has_tverts[g] = true
					
					if chk_weight.checked == true then
					(
						if classOf geometry_objects[g].modifiers[1] == Skin then
						(
							theSkin = geometry_objects[g].modifiers[1]
							numBones = skinOps.getNumberBones theSkin
							if numBones > 1 then
							(
								geom_object_has_skin[g] = true
								temp_bone_array = #()
								for b = 1 to numBones do
								(
									select geometry_objects[g]
									max modify mode
									subobjectLevel = 1
									boneName = skinOps.getBoneName theSkin b 0
									theNode = getNodeByName boneName exact:true ignoreCase:false
									nodeNum = findItem node_array theNode
									if nodeNum == 0 then
									(
										messageBox ("Warning: bone " + boneName + " in skin modifier is not a node.") title:"BlueStreak Error"
										append temp_bone_array 1
									)
									else
									(
										append temp_bone_array nodeNum
									)
								)
								geom_bone_array[g] = temp_bone_array
							)
						)
					)
										
					default_node0index = (geom_parent_index[g] - 1)
					
					face_verts = #()
					face_matID = #()
					face_SG = #()
					face_tverts = #()
					
					for f = 1 to geom_mesh_faces[g] do
					(
						face_verts[f] = getFace tmesh f
						face_matID[f] = getFaceMatID tmesh f
						face_SG[f] = getFaceSmoothGroupB tmesh f
						if geom_object_has_tverts[g] == true do face_tverts[f] = getTVFace tmesh f
						
						for vertices = 1 to 3 do
						(
							v += 1
							
							vert_pos[v] = getVert tmesh face_verts[f][vertices]
							
							if geom_object_has_skin[g] == true then
							(
								skinNode0 = skinOps.getVertexWeightBoneID theSkin face_verts[f][vertices] 1
								weightedNode0Index = geom_bone_array[g][skinNode0] - 1
								vert_node0index[v] = weightedNode0Index
								
								boneAffectNum = skinOps.getVertexWeightCount theSkin face_verts[f][vertices]
								if boneAffectNum > 2 do boneAffectWarning = true
								if boneAffectNum == 1 then
								(
									if boneAffectNum > 2 do boneAffectWarning = true
									vert_node1index[v] = -1
									vert_node1weight[v] = 0
								)
								else
								(
									skinNode1 = skinOps.GetVertexWeightBoneID theSkin face_verts[f][vertices] 2
									weightedNode1Index = geom_bone_array[g][skinNode1] - 1
									weightedNode1Weight = skinOps.GetVertexWeight theSkin face_verts[f][vertices] 2
									if weightedNode1Weight > 0.5 then
									(
										vert_node0index[v] = weightedNode1Index
										vert_node1index[v] = weightedNode0Index
										vert_node1weight[v] = (1.0 - weightedNode1Weight)
										
									)
									else
									(
										vert_node0index[v] = weightedNode0Index
										vert_node1index[v] = weightedNode1Index
										vert_node1weight[v] = weightedNode1Weight
									)
								)
							)
							else
							(
								vert_node0index[v] = default_node0index
								vert_node1index[v] = -1
								vert_node1weight[v] = 0
							)
							
							vNormal = [0,0,0]
							vNormal += getFaceNormal tmesh f
							simFaces = meshop.getFacesUsingVert tmesh face_verts[f][vertices] as array
							del_index = findItem simFaces f
							deleteItem simFaces del_index
							for s = 1 to simFaces.count do
							(
								affectNormal = false
								neiSG = getFaceSmoothGroupB tmesh simFaces[s]
								for aN = 1 to face_SG[f].count do
								(
									if affectNormal == false then
									(
										if findItem neiSG face_SG[f][aN] != 0 then
										(
											affectNormal = true
										)
									)
								)
								
								if affectNormal == true then
								(
									vNormal += getFaceNormal tmesh simFaces[s]
								)
							)
							vert_normal[v] = normalize(vNormal)
							
							if geom_object_has_tverts[g] == true then
							(
								tvert_pos[v] = getTVert tmesh face_tverts[f][vertices]
							)
							else
							(
								tvert_pos[v] = [0,0,0]
							)
						)
						append face_shader_index ((findItem geom_materials geometry_objects[g].material[face_matID[f]]) - 1)
					)
					max create mode
					clearSelection()
				)
				if boneAffectWarning == true then
				(
					messageBox "Warning: some vertices are weighted by more than two bones." title:"BlueStreak Error"
				)
			)
			else
			(
				messageBox "Warning: there was no geometry to export." title:"BlueStreak Error"
			)
		)
		
		
	
		
		if exportFailed != true then
		(
		
			-- Print the JMS file to JMS or the MAXScript Listener --
			
			if chk_jms.checked == true then
			(
				output_name = getSaveFileName caption:"Select File to Export" \
					filename: "C:\\Program Files\\Microsoft Games\\Halo Custom Edition\\data\\" \
					types:"BlueStreak Model Exporter (*.jms)|*.jms|All Files (*.*)|*.*|"
				
				if output_name != undefined then 
				(
					jms = createfile output_name
					validJMS = true
				)
				else
				(
					validJMS = false
					messageBox "You did not create or select a JMS file to save to. Export failed." \
						title: "JMS export terminated"
				)
			)
			else
			(
				ClearListener()
				jms = listener
				validJMS = true
			)
			
			if validJMS == true then
			(
				ProgressStart "Exporting JMS Data"
				start1 = timeStamp()
				
				node_count = node_array.count
				
				format "%\n%\n%\n" 8200 3251 node_count to:jms
				for n = 1 to node_count do
				(
					format "%\n" node_array[n].name to:jms
					format "%\n" (node_first_child_index[n] - 1) to:jms
					format "%\n" (node_next_sibling_index[n] - 1) to:jms
					format "%\t%\t%\t%\n" node_rotation[n].x node_rotation[n].y node_rotation[n].z node_rotation[n].w to:jms
					format "%\t%\t%\n" node_translation[n].x node_translation[n].y node_translation[n].z to:jms
				)
				
				mat_count = geom_materials.count
				format "%\n" mat_count to:jms
				for m = 1 to mat_count do
				(
					format "%\n%\n" geom_materials[m].name "<none>" to:jms
				)
				
				marker_count = marker_array.count
				format "%\n" marker_count to:jms
				for m = 1 to marker_count do
				(
					format "%\n-1\n" (substring marker_array[m].name 2 -1) to:jms
					format "%\n" (marker_parent_index[m] - 1) to:jms
					format "%\t%\t%\t%\n" marker_rotation[m].x marker_rotation[m].y marker_rotation[m].z marker_rotation[m].w to:jms
					format "%\t%\t%\n2.0\n" marker_translation[m].x marker_translation[m].y marker_translation[m].z to:jms
				)
				
				numVerts = vert_pos.count
				format "%\n%\n%\n" 1 "unnamed" numVerts to:jms
				
				totalCount = numVerts + numFaces
				
				for v = 1 to numVerts do
				(
					format "%\n" vert_node0index[v] to:jms
					format "%\t%\t%\n" vert_pos[v].x vert_pos[v].y vert_pos[v].z to:jms
					format "%\t%\t%\n" vert_normal[v].x vert_normal[v].y vert_normal[v].z to:jms
					format "%\n" vert_node1index[v] to:jms
					format "%\n" vert_node1weight[v] to:jms
					format "%\n" tvert_pos[v].x to:jms
					format "%\n0\n" tvert_pos[v].y to:jms
					ProgressUpdate ((v as float / totalCount) * 100.0)
				)
				
				format "%\n" numFaces to:jms
				
				c = 0
				for n = 1 to numFaces do
				(
					format "0\n%\n" face_shader_index[n] to:jms
					format "%\t%\t%\n" c (c+1) (c+2) to:jms
					c += 3
					ProgressUpdate (((numVerts + n as float) / totalCount) * 100.0)
				)
				
				end1 = timeStamp()
				
				if chk_jms.checked == true then
				(
					format ("JMS took % seconds to write.") ((end1 - start1) / 1000.0) to:listener
					close jms
				)
				
				ProgressEnd()
				
			)
		)
		
		if exportFailed == true then
		(
			messageBox "Export module failure" title:"Export"
		)
	)
	*/
	
	
)




CreateDialog roll

-- End of Script --