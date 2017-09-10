--***************************************************************************
--*						  JMS Exporter by TheGhost							*
--*					   for 3ds Max v5+ and gmax v1.2						*
--***************************************************************************
--*		Features:															*
--*			- Exports all types of model geometry							*
--*			- Exports perfect texture coordinates							*
--*			- Exports proper, well-calculated vertex normals				*
--*			- Exports all nodes and markers (for weapons, vehicles, etc.)	*
--*			- Exports biped systems or bones for character models			*
--*			- Exports vertex weights for fully rigged model!				*
--*			- Exports from gmax / 3ds max version independent				*
--*-------------------------------------------------------------------------*
--*	Instructions: Check the checkbox captioned "Export vertex weights" if	*
--*	you are exporting a rigged model. Select the method to export the JMS	*
--*	data, either writing to a JMS file or streaming through the listener	*
--*	(for gmax). Click the "Export JMS Data" button to begin.				*
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

all_objects_array = #()
all_object_names = #()

node_objects = #()
node_array = #()
node_translation = #()
node_rotation = #()
node_child_indices = #()
node_first_child_index = #()
node_next_sibling_index = #()

marker_array = #()
marker_parent_index = #()
marker_translation = #()
marker_rotation = #()

geometry_objects = #()
geom_parent_index = #()
geom_materials = #()
geom_bone_array = #()
geom_object_has_skin = #()
geom_object_has_tverts = #()
geom_mesh_faces = #()
face_verts = #()
face_matID = #()
face_SG = #()
face_tverts = #()
face_shader_index = #()

vert_pos = #()
vert_node0index = #()
vert_node1index = #()
vert_node1weight = #()
vert_normal = #()
tvert_pos = #()

exportFailed = false
sceneParent = undefined
nodeParent = undefined
numFaces = 0
boneAffectWarning = false
validJMS = false

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

rollout roll "JMS Model Exporter" width:209 height:254
(
	GroupBox grp1 "" pos:[7,0] width:194 height:32
	label lbl_title "BlueStreak: Halo Model Exporter" pos:[26,12] width:159 height:13
	
	GroupBox grp2 "User Information" pos:[8,37] width:193 height:40
	edittext edt_info "" pos:[13,53] width:176 height:18 enabled:false
	
	GroupBox grp3 "Export options" pos:[7,82] width:194 height:40
	checkbox chk_weight "Export vertex weights (rigged)" pos:[17,100] width:173 height:16 checked:true
	
	GroupBox grp4 "Export Method" pos:[7,127] width:194 height:103
	checkbox chk_jms "Save to JMS File  (3ds max only)" pos:[17,146] width:174 height:16 checked:true
	checkbox chk_stream "Stream with MAXScript Listener" pos:[17,165] width:174 height:16
	button go_button "Export JMS Data" pos:[38,188] width:128 height:31
	
	label lbl7 "Script by TheGhost" pos:[8,235] width:101 height:14 enabled:false
	label lbl8 "v1.0.1" pos:[167,236] width:36 height:14 enabled:false
	
	on roll open do
	(
		ClearListener()
		if maxver[1] <= 4200 then
		(
			edt_info.text = "  Max version " + (maxver[1] / 1000.0) as string + " (gmax) detected."
			chk_jms.checked = false
			chk_jms.enabled = false
			chk_stream.checked = true
		)
		else
		(
			edt_info.text = "  3ds Max version " + (maxver[1] / 1000.0) as string + " detected."
			chk_jms.enabled = true
			chk_jms.checked = true
			chk_stream.checked = false
		)
	)
	on chk_jms changed theState do
	(
		if theState == true then
		(
			chk_stream.checked = false
		)
		else
		(
			chk_stream.checked = true
		)
	)
	on chk_stream changed theState do
	(
		if theState == true then
		(
			chk_jms.checked = false
		)
		else
		(
			if chk_jms.enabled == true then
			(
				chk_jms.checked = true
			)
			else
			(
				chk_stream.checked = true
			)
		)
	)
	on go_button pressed do
	(
		all_objects_array = #()
		all_object_names = #()
		
		node_objects = #()
		node_array = #()
		node_translation = #()
		node_rotation = #()
		node_child_indices = #()
		node_first_child_index = #()
		node_next_sibling_index = #()
		
		marker_array = #()
		marker_parent_index = #()
		marker_translation = #()
		marker_rotation = #()
		
		geometry_objects = #()
		geom_parent_index = #()
		geom_materials = #()
		geom_bone_array = #()
		geom_object_has_skin = #()
		geom_object_has_tverts = #()
		geom_mesh_faces = #()
		face_verts = #()
		face_matID = #()
		face_SG = #()
		face_tverts = #()
		face_shader_index = #()
		
		vert_pos = #()
		vert_node0index = #()
		vert_node1index = #()
		vert_node1weight = #()
		vert_normal = #()
		tvert_pos = #()
		
		exportFailed = false
		sceneParent = undefined
		nodeParent = undefined
		numFaces = 0
		boneAffectWarning = false
		validJMS = false
		
		ClearListener()
		
		clearSelection()		
		max select all
		all_objects_array = selection as array
		clearSelection()
		objectsInScene = all_objects_array.count
		for n = 1 to objectsInScene do
		(
			all_object_names[n] = all_objects_array[n].name
		)
		for a = 1 to objectsInScene do
		(
			if exportFailed != true then
			(
				objName = all_objects_array[a].name
				
				if (substring objName 1 5 as name == "frame" as name) or (substring objName 1 5 as name == "bip01" as name) then
				(
					if (all_objects_array[a].parent == undefined) then
					(
						if sceneParent != undefined then
						(
							messagebox "There are too many actors in the scene! Can not export single model." title:"BlueStreak Error 1"
							exportFailed = true
						)
						else
						(
							sceneParent = all_objects_array[a]
							append node_objects all_objects_array[a]
							currCount = node_objects.count
							node_objects[currCount].name = "01" + node_objects[currCount].name
						)
					)
					else
					(
						testParent = all_objects_array[a].parent
						i = 1
						do (
							i += 1
							rootParent = testParent
							testParent = testParent.parent
						) while (testParent != undefined)
						
						if rootParent != sceneParent then
						(
							messagebox "There are too many actors in the scene!  Can not export single model." title:"BlueStreak Error 2"
							exportFailed = true
						)
						else
						(
							append node_objects all_objects_array[a]
							currCount = node_objects.count
							if i < 10 then
							(
								node_objects[currCount].name = "0" + i as string + node_objects[currCount].name
							)
							else
							(
								node_objects[currCount].name = i as string + node_objects[currCount].name
							)
						)
					)
				)
				else
				(
					if all_objects_array[a].parent != undefined then
					(
						if objName[1] == "#" then
						(
							testParent = all_objects_array[a].parent
							do (
								rootParent = testParent
								testParent = testParent.parent
							) while testParent != undefined
							
							if rootParent == sceneParent then
							(
								append marker_array all_objects_array[a]
							)
						)
						else
						(
							testParent = all_objects_array[a].parent
							do (
								rootParent = testParent
								testParent = testParent.parent
							) while testParent != undefined
							
							if rootParent == sceneParent then
							(
								append geometry_objects all_objects_array[a]
							)
						)
					)
				)
			)
		)
		
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
			for a = 1 to all_objects_array.count do
			(
				all_objects_array[a].name = all_object_names[a]
			)
		)
	)
)


CreateDialog roll

-- End of Script --