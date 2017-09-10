--***************************************************************************
--*					  		.ASS Importer by TheGhost						*
--*					    for 3ds Max v6+ and Halo 2 Vista					*
--***************************************************************************


importFailed = false
in_file = undefined

assObjects = #()

maxver = maxVersion()

rollout roll "BlueStreak .ASS Importer" width:326 height:439
(
	GroupBox grp1 "" pos:[7,0] width:312 height:34
	label lbl_title "BlueStreak .ASS Importer" pos:[77,13] width:182 height:13
	edittext edt_info "" pos:[20,58] width:274 height:188 enabled:true
	button import_button "Import .ASS File" pos:[90,369] width:128 height:31
	label lbl_by "Script by TheGhost" pos:[5,421] width:101 height:14 enabled:false
	
	on roll open do
	(
		ClearListener()
		edt_info.text += "3ds Max version " + (maxver[1] / 1000.0) as string + " detected.\r\n"
	)
	on import_button pressed do
	(
		in_name = getOpenFileName caption:"Select File to Import" \
			filename: "C:\\Program Files\\Microsoft Games\\Halo 2 Map Editor\\data\\" \
			types:("BlueStreak ASS (*.ASS)|*.ASS|All Files (*.*)|*.*|")
		
		if (in_name == undefined) then
	 	(
			importFailed = true
		)
		
		if (importFailed != true) then
		(
			in_file = openFile in_name
			
			if (in_file == undefined) then
			(
				messageBox "Error in opening file!" title:"File opening error"
				importFailed = true
			)
			if (importFailed != true) then
			(
				seek in_file 0
				if (readDelimitedString in_file "\n" != ";### HEADER ###") then
				(
					messageBox "Error: Incorrect file type!\n\nPlease select an exported .ASS file.  " \
						title:"Incorrect file type error"
					importFailed = true
				)
			)
		)
		
		if (importFailed != true) then
		(
			edt_info.text += "Importing file: " + in_name + "\n"
			
			seek in_file 0
			
			skipToString in_file ";### OBJECTS ###\n"
			numObjects = readValue in_file
			edt_info.text += "Number of objects: " + (numObjects as string) + "\n"
			
			for n = 1 to numObjects do
			(
				skipToString in_file (";OBJECT " + ((n - 1) as string))
				skipToNextLine in_file
				local objType = readLine in_file
				edt_info.text += (objType as string) + "\n"
				if (objType == "\"SPHERE\"") then
				(
					skipToNextLine in_file
					skipToNextLine in_file
					local mat = readValue in_file
					local rad = readValue in_file
					local s = Sphere radius:rad
					assObjects[n] = s
				)
				if (objType == "\"BOX\"") then
				(
					skipToNextLine in_file
					skipToNextLine in_file
					local mat = readValue in_file
					local len = (readValue in_file) * 2
					local wid = (readValue in_file) * 2
					local hei = (readValue in_file) * 2
					local b = Box length:len width:wid height:hei
					assObjects[n] = b
				)
				if (objType == "\"PILL\"") then
				(
					skipToNextLine in_file
					skipToNextLine in_file
					local mat = readValue in_file
					local hei = readValue in_file
					local rad = readValue in_file
					local c = Cylinder height:hei radius:rad
					assObjects[n] = c
				)
				if (objType == "\"MESH\"") then
				(
					skipToNextLine in_file
					skipToNextLine in_file
					local numVerts = readValue in_file
					edt_info.text += "Number of verts: " + (numVerts as string) + "\n"
					
					local xyz = #()
					local ijk = #()
					local uvw = #()
					
					xyz.count = numVerts
					ijk.count = numVerts
					uvw.count = numVerts
					
					for v = 1 to numVerts do
					(
						xyz[v] = [readValue in_file, readValue in_file, readValue in_file]
						ijk[v] = [readValue in_file, readValue in_file, readValue in_file]
						skipToNextLine in_file
						skipToNextLine in_file
						uvw[v] = [readValue in_file, readValue in_file, 0]
					)
					
					local numFaces = readValue in_file
					edt_info.text += "Number of faces: " + (numFaces as string) + "\n"
					
					local matID = #()
					local verts = #()
					
					matID.count = numFaces
					verts.count = numFaces
					
					for f = 1 to numFaces do
					(
						matID[f] = (readValue in_file) + 1
						verts[f] = [(readValue in_file) + 1, (readValue in_file) + 1, (readValue in_file) + 1]
					)
					
					local m = mesh vertices:xyz tverts:uvw faces:verts materialIDs:matID
					local mmesh = m.mesh
					
					for v = 1 to numVerts do
					(
						setNormal mmesh v ijk[v]
					)
					
					buildTVFaces mmesh
					for f = 1 to numFaces do
					(
						setTVFace mmesh f (getFace mmesh f)
						setFaceSmoothGroup mmesh f 1
					)
					
					assObjects[n] = m
				)
			)
			
			skipToString in_file ";### INSTANCES ###\n"
			numInstances = readValue in_file
			edt_info.text += "Number of instance: " + (numInstances as string) + "\n"
			
			for i = 2 to numInstances do  -- start at 2: ignore scene root
			(
				skipToString in_file (";INSTANCE " + ((i - 1) as string))
				local objIndex = (readValue in_file) + 1
				skipToString in_file "\""
				local iname = readDelimitedString in_file "\""
				local uniqueInstanceID = readValue in_file
				local parentInstanceIndex = readValue in_file
				local inheritanceFlag = readValue in_file
				
				local rot = quat (readValue in_file) (readValue in_file) (readValue in_file) (readValue in_file)
				local trans = [readValue in_file, readValue in_file, readValue in_file]
				local uscale = readValue in_file
				
				local offset_rot = quat (readValue in_file) (readValue in_file) (readValue in_file) (readValue in_file)
				local offset_pos = [readValue in_file, readValue in_file, readValue in_file]
				local offset_scale = readValue in_file
				
				assObjects[objIndex].objectoffsetrot = offset_rot
				assObjects[objIndex].objectoffsetpos = offset_pos				
				assObjects[objIndex].objectoffsetscale = [offset_scale, offset_scale, offset_scale]
				
				if (parentInstanceIndex > 0) then
				(
					assObjects[objIndex].parent = assObjects[parentInstanceIndex]
				)
				
				in coordsys parent assObjects[objIndex].rotation = rot
				in coordsys parent assObjects[objIndex].pos = trans
				in coordsys parent assObjects[objIndex].scale = [uscale, uscale, uscale]
				
				assObjects[objIndex].name = iname
			)
			
			close in_file
		)
	)
	
)




CreateDialog roll

-- End of Script --