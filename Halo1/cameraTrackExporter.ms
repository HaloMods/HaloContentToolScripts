trakPath = getSaveFileName	caption:"Save Camera Track" \
							filename:"C:\\" \
							types:"Text file (*.txt)|*.txt|"
if (trakPath != undefined) then
(
	local trakFile = createFile trakPath
	local controlPoints = $'control_point*' as array
	
	format "camera_track\t%\n" (getFilenameFile trakPath) to:trakFile
	format "2\n" to:trakFile
	format "  flags\tlong flags\t0\n" to:trakFile
	format "  control points\tblock\t%\n" controlPoints.count to:trakFile
	for c = 1 to controlPoints.count do
	(
		local cp = controlPoints[c]
		
		format "   element %\n" (c - 1) to:trakFile
		format "    position\treal vector 3d\t%\t%\t%\n" (cp.position.x / 100.0) (cp.position.y / 100.0) (cp.position.z / 100.0) to:trakFile
		format "    orientation\treal quaternion\t%\t%\t%\t%\n" (-cp.rotation.x) (-cp.rotation.y) (-cp.rotation.z) (cp.rotation.w) to:trakFile
		format "   end element %\n" (c - 1) to:trakFile
	)
	
	close trakFile
)