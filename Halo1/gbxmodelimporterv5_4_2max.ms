--**************************************************************************************
--* 		 GBXMODEL importer script for Max v5+ and Gmax version 1.0+	 		       *
--*								  by JamesD										       *
--*		Special thanks to Grenadiac, Viperneo and Bobindashadows, without them         *
--*		this script would have not have been possible :)						       *
--* 							http://www.halomods.com 						       *
--*			Current features:													       *
--*				- loads 1 LOD and normal model variation						       *
--*				- loads markers (spheres) and nodes (blocks)					       *
--*			Current bugs:														       
--*				- Degenerative triangles are not (100%)yet handled.				       *
--*				- Some models cause errors (reason is above)					       *
--*				- vertexorder_array is not cleared(accounts for doubling of model)     *
--*				- Does not handle matrix rotations (so only nodes of simple 	       *
--*				  models are rendered).											       *
--*			Instructions on use:												       *
--*				- Open up guerilla and open a gbxmodel tag.						       *
--*				- Export the tag to a txt file									       *
--*				- Run this script and open up the txt file you made				       *
--*				- Adjust the model as needed									       *
--**************************************************************************************
--* Submit bugs to james@halomods.com or contact me through irc.shadowfire.org 	       *
--* #halomods																	       *
--**************************************************************************************
--* Copyright (C) 2004 James Dickson 												   *
--* This program is free software; you can redistribute it and/or modify it under the  * 
--* terms of the GNU General Public License as published by the Free Software 		   *
--* Foundation; either version 2 of the License, or (at your option) any later version.* 
--* This program is distributed in the hope that it will be useful, but WITHOUT ANY    * 
--* WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A    * 
--* PARTICULAR PURPOSE. See the GNU General Public License for more details. You should* 
--* have received a copy of the GNU General Public License along with this program; if * 
--* not, write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,     * 
--* Boston, MA 02111-1307, USA. 													   *
--**************************************************************************************

--First up we declare some arrays to store the data in.
vertex_array = #() --this creates a new array to store the vertex information for a model.
triangle_array = #() --this is an array to store the triangle data.
uv_array = #()
buff_array = #() --this array is used to manipulate the data so it is useful.

node_array = #() --this array stores all the nodes of a model.
nodeparent = #() --stores the parent index number of the node.
noderotation = #()

marker_array = #() --holds all the markers information.
markerotation_array =#()
markertranslation = #() --stores the position of the markers.
parentnumber = #() --used to store parent info about the markers.

maxver = #() --array to store version of max, for debug purposes.
debug = newScript() --new in this version a debug window, so that errors can be spotted.


--Now we create the user interface, in this case a rollout.
rollout opengbxfile "Open gbxmodel file"
 (
  --Create a user interface.
  button fileopen "Open file" width:140 height:37
  checkbox allregions "Render all regions"
  checkbox importuvs "Import UV's for model" enabled:false
  
  --add a handler for the button.
  on fileopen pressed do
   (
    maxver = maxVersion()--this gets the information about max.
	
    --Print some debug info to the debug window.
    print "gbxmodel importer v5.4 by JamesD" to:debug
	print ("MAX Version "+ (maxver[1] as string)) to:debug
	print ("API Version "+ (maxver[2] as string)) to:debug
	print ("SDK Version "+ (maxver[3] as string)) to:debug
	
	--Now we create an open dialog and get a file
	in_name= getOpenFileName \ --this draws the open file dialog
   			filename: "c:\\program files\\microsoft games\\halo custom edition\\" \ --the default directory to look in
   			types: "gbxmodel export (*.txt)|*.txt|"--what types of files to look for
	
	--When the user presses the open button we varify and validate the file.
	if in_name != undefined then --check a file is selected.
	 (
	  in_file = openFile in_name --attempt to open the file.
	  if in_file != undefined then --make sure no opening errors.
	   (
	    print ("File opened: "+in_name) to:debug
		print "-----" to:debug
		
		--Now we read in the nodes of the model.
		if (skiptostring in_file "nodes") != undefined then
	    (
		 skiptostring in_file "block"
		 seek in_file ((filePos in_file)+1)
		 nodenum = readValue in_file
		 print "Node Block Information" to:debug
		 print ("number of nodes "+(nodenum as string)) to:debug
		 print "-----" to:debug
		 for num = 1 to nodenum do
		  (
		   skiptostring in_file "string"
		   seek in_file ((filePos in_file)+1)
		   node_array[num] = box length:2 width:2 height:2
		   node_array[num].name = readDelimitedString in_file "\n"
		   skiptostring in_file "parent"
		   skiptostring in_file "short block index"
		   seek in_file ((filePos in_file)+1)
		   skiptostring in_file "\t"
		   number = ((readValue in_file)+1)
		   if number != 0 then
		    (
		   	 nodeparent[num] = number
			)
		   skiptostring in_file "real point 3d"
		   seek in_file ((filePos in_file)+1)
		   x = ((readValue in_file)*100)
		   y = ((readValue in_file)*100)
		   z = ((readValue in_file)*100)
		   node_array[num].pos = [x,y,z]
		   skiptostring in_file "real quaternion"
		   seek in_file ((filePos in_file)+1)
		   w = readValue in_file
		   x = readValue in_file
		   y = readValue in_file
		   z = readValue in_file
		   noderotation[num] = [w,x,y,z]
		   print noderotation[num] to:debug
		  )
		)--end if nodes.
		
		--Now we do the same for markers.
		if (skiptostring in_file "markers") != undefined then
	    (
		 skiptostring in_file "block"
		 seek in_file ((filePos in_file)+1)
		 markernum = readValue in_file
		   print "Marker Block Information" to:debug
		   print ("Number of markers "+(markernum as string)) to:debug
		   print "------" to:debug
		 for num = 1 to markernum do
		  (
		   skiptostring in_file "string"
		   seek in_file ((filePos in_file)+1)
		   marker_array[num] = sphere radius:1
		   marker_array[num].name = "#"+(readDelimitedString in_file "\n")
		   skiptostring in_file "short block index"
		   seek in_file ((filePos in_file)+1)
		   skiptostring in_file "\t"
		   parentnumber[num] = ((readValue in_file)+1)
		   skiptostring in_file "real point 3d"
		   seek in_file ((filePos in_file)+1)
		   x = ((readValue in_file)*100)
		   y = ((readValue in_file)*100)
		   z = ((readValue in_file)*100)
		   markertranslation[num]=[x,y,z]
		  )
		)--end if markers.
		
		-- Now we do the moving and rotation of the nodes.
		for number = 2 to nodenum do
		 (
		  node_array[number].pos = (node_array[number].pos + node_array[nodeparent[number]].pos)
		  rotation = quat noderotation[number].w noderotation[number].x noderotation[number].y noderotation[number].z
		  rotate node_array[number] rotation
		  node_array[number].parent = node_array[nodeparent[number]]
		 )
		 
		-- Now we do the moving of the markers.
		for number = 1 to markernum do
		 ( 
		  marker_array[number].pos = ((node_array[parentnumber[number]].pos)+(markertranslation[number]))
		  marker_array[number].parent = node_array[parentnumber[number]]
		 )
		
		--Now we go to the geometry segment and read in how many there are.
	   skiptostring  in_file "geometries" --skips to the geometries section of the file
	   skiptostring  in_file "block"
	   seek in_file ((filePos in_file)+1)
	   value = readValue in_file
	   if allregions.checked == true then geometrycount = value else geometrycount = 1
	   print "Geometries" to:debug
	   print geometrycount to:debug
	   print "------" to:debug
	   	   
	   --Now the info is gathered.	   
	   for num1 = 1 to geometrycount do
	    (
		 
		 --Now we go to the parts and loop through those
		 skiptostring  in_file "parts" --then for each geometry we look for each part of it.
	     skiptostring  in_file "block"
		 seek in_file ((filePos in_file)+1)
		 partcount = readValue in_file --this then reads in the number of parts.
		 print "Parts" to:debug
	     print partcount to:debug
	     print "------" to:debug
		 
		 for num2 = 1 to partcount do
		  (
		   skiptostring  in_file "uncompressed vertices"--go to the vertice block.
		   skiptostring  in_file "block"
		   seek in_file ((filePos in_file)+1)
		   vertexcount = readValue in_file
		   print "Vertices" to:debug
	       print vertexcount to:debug
	       print "-------" to:debug
		   
		   --Now we read in the vert data.
		   for num3 = 1 to vertexcount do --then we loop through the number of vertices
		    (
		     skiptostring  in_file "real point 3d"
		     seek in_file ((filePos in_file)+1)
		  	 x = ((readValue in_file)*100)
		  	 y = ((readValue in_file)*100)
		  	 z = ((readValue in_file)*100)
		  	 vertex_array[num3] = [x,y,z]
		 	)--end do loop (vertexcount)
		 	
		   --Now we make the indicies
		   skiptostring in_file "triangles"
		   skiptostring in_file "block"
		   seek in_file ((filePos in_file)+1)
		   trianglecount = readValue in_file
		   print "Triangles" to:debug
	       print trianglecount to:debug
	       		   
		   --Now read in the triangles.
		   number = 1
		   for num4 = 1 to trianglecount do
		    (
			 skiptostring in_file "vertex0 index"
		     skiptostring in_file "short integer"
		     seek in_file ((filePos in_file)+1)
		     buff_array[number] = ((readValue in_file)+1)
			 number = number + 1
		     skiptostring in_file "vertex1 index"
		     skiptostring in_file "short integer"
		     seek in_file ((filePos in_file)+1)
		     buff_array[number] = ((readValue in_file)+1)
			 number = number + 1
		     skiptostring in_file "vertex2 index"
		     skiptostring in_file "short integer"
		     seek in_file ((filePos in_file)+1)
		     buff_array[number] = ((readValue in_file)+1)
			 number = number + 1
			)--end for trianglecount
			
		   --Now we do the winding.
		   triangle_array[1] = [(buff_array[1]),(buff_array[2]),(buff_array[3])]
		   for num5 = 2 to ((trianglecount*3)-4) do
		    (
			 triangle_array[num5] = [(buff_array[num5]),(buff_array[num5+1]),(buff_array[num5+2])]
			)--end for winding
		   
		   --Now we reverse everyother triangle.
			for num7=1 to triangle_array.count by 2 do
			 (
			  d = triangle_array[num7][1]
			  e = triangle_array[num7][2]
			  f = triangle_array[num7][3]
			  triangle_array[num7][1]=f
			  triangle_array[num7][2]=e
			  triangle_array[num7][3]=d
			 )--end reverse triangles.
			 
		   --Now the degenerative triangles are checked.
		   for num6=triangle_array.count to 1 by -1 do
		    (
			 a = triangle_array[num6][1]
			 b = triangle_array[num6][2]
			 c = triangle_array[num6][3]
			 if (a==b) or (b==c) or (a==c) then
			  (
			   deleteItem triangle_array num6
			  ) 
			 )--end degenerative triangle check.
			
		   --this makes the actual mesh. 
		   m = mesh vertices:vertex_array faces:triangle_array
		   
		  )--end for partcount.
		  
		)--end for geometrycount.
		
	   )--end if in_file
	 )--end if in_name
     messagebox ("Done!")
   )--end button pressed
 )--end rollout

--Now we draw the rollout to the screen.
Floater = newRolloutFloater "gbxmodel" 200 140
addRollout opengbxfile Floater