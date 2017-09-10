struct binReader
(
	lastPath = "C:\\",
	path = undefined,
	file = undefined,
	endianness = undefined,
	length = 0,
	
	fn load filePath endian: =
	(
		local success = false
		
		path = filePath
		if (path != undefined) then
		(
			lastPath = getFilenamePath filePath
			try
			(
				file = fopen path "rb"
				
				fseek file 0 #seek_end
				length = ftell file
				fseek file 0 #seek_set
				
				if (endian == unsupplied) then (endianness = #little)
				else
				(
					endianness = case endian of
					(
						#big : #big
						default : #little
					)
				)
				
				success = true
			)
			catch ()
		)
		
		success
	),
	fn promptPath titleStr typeStr endian: =
	(
		local success = false
		local filePath = getOpenFileName	caption:titleStr \
											fileName:lastPath \
											types:typeStr
		
		if  (filePath != undefined) then
		(
			if (endian == unsupplied) then (success = load filePath)
			else (success = load filePath endian:endian)
		)
		
		success
	),
	fn unload =
	(
		try
		(
			path = undefined
			try (fclose file) catch ()
			file = undefined
			endianness = undefined
			length = 0
			true
		)
		catch (false)
	),
	
	fn getPosition = (ftell file),
	fn setPosition val = (fseek file val #seek_set),
	fn advPosition val = (fseek file val #seek_cur),
	
	fn readInt8 type: =
	(
		local readFormat = undefined
		if (type == unsupplied) then (readFormat = #unsigned)
		else
		(
			readFormat = case type of
			(
				#signed : #signed
				default : #unsigned
			)
		)
		
		readByte file readFormat
	),
	fn readInt16 type: =
	(
		local readFormat = undefined
		if (type == unsupplied) then (readFormat = #signed)
		else
		(
			readFormat = case type of
			(
				#unsigned : #unsigned
				default : #signed
			)
		)
		
		if (endian == #little) then
		(
			local byte2 = readByte file #unsigned
			local byte1 = readByte file #unsigned
		)
		else
		(
			local byte1 = readByte file #unsigned
			local byte2 = readByte file #unsigned
		)
		
		local returnValue = (byte1 * 256) + byte2
		if (readFormat == #signed) then
		(
			if (returnValue > 32768) then ((65536 - returnValue) * -1)
			else (returnValue)
		)
		else (returnValue)
	),
	fn readInt32 type: =
	(
		local readFormat = undefined
		if (type == unsupplied) then (readFormat = #signed)
		else
		(
			readFormat = case type of
			(
				#unsigned : #unsigned
				default : #signed
			)
		)
		
		if (endian == #little) then
		(
			local byte4 = readByte file #unsigned
			local byte3 = readByte file #unsigned
			local byte2 = readByte file #unsigned
			local byte1 = readByte file #unsigned
		)
		else
		(
			local byte1 = readByte file #unsigned
			local byte2 = readByte file #unsigned
			local byte3 = readByte file #unsigned
			local byte4 = readByte file #unsigned
		)
		
		local returnValue = (byte1 * 16777216) + (byte2 * 65536) + (byte3 * 256) + byte4
		if (readFormat == #signed) then
		(
			if (returnValue as float > 2147483648.0) then ((4294967296 - returnValue) * -1)
			else (returnValue)
		)
		else (returnValue)
	),
	
	fn readBitArray8 =
	(
		local flagBitArray = #{}
		local flagsRaw = readInt8 type:#unsigned
		for i = 1 to 8 do
		(
			local mask = bit.shift 1 (i - 1)
			local state = (bit.and flagsRaw mask) == mask
			flagBitArray[i] = state
		)
		flagBitArray
	),
	fn readBitArray16 =
	(
		local flagBitArray = #{}
		local flagsRaw = readInt16 type:#unsigned
		for i = 1 to 16 do
		(
			local mask = bit.shift 1 (i - 1)
			local state = (bit.and flagsRaw mask) == mask
			flagBitArray[i] = state
		)
		flagBitArray
	),
	fn readBitArray32 =
	(
		local flagBitArray = #{}
		local flagsRaw = readInt32 type:#unsigned
		for i = 1 to 32 do
		(
			local mask = bit.shift 1 (i - 1)
			local state = (bit.and flagsRaw mask) == mask
			flagBitArray[i] = state
		)
		flagBitArray
	),
	
	fn readFloat32 =
	(
		local floatBitArray = #{}
		if (endian == #little) then
		(
			local byte4 = readByte file #unsigned
			local byte3 = readByte file #unsigned
			local byte2 = readByte file #unsigned
			local byte1 = readByte file #unsigned
		)
		else
		(
			local byte1 = readByte file #unsigned
			local byte2 = readByte file #unsigned
			local byte3 = readByte file #unsigned
			local byte4 = readByte file #unsigned
		)
		
		for i = 8 to 1 by -1 do
		(
			floatBitArray[i] = (mod byte1 2) > 0.5
			byte1 /= 2
		)
		for i = 16 to 9 by -1 do
		(
			floatBitArray[i] = (mod byte2 2) > 0.5
			byte2 /= 2
		)
		for i = 24 to 17 by -1 do
		(
			floatBitArray[i] = (mod byte3 2) > 0.5
			byte3 /= 2
		)
		for i = 32 to 25 by -1 do
		(
			floatBitArray[i] = (mod byte4 2) > 0.5
			byte4 /= 2
		)
		local exponent = 0.0
		for i = 9 to 2 by -1 do
		(
			if floatBitArray[i] then (exponent += 2.0 ^ (9 - i))
		)
		exponent -= 127.0
		local returnValue = 2.0 ^ exponent
		exponent -= 1
		for i = 10 to 32 do
		(
			if floatBitArray[i] then (returnValue += 2.0 ^ exponent)
			exponent -= 1
		)
		if floatBitArray[1] then (returnValue * -1)
		else (returnValue)
	),
	
	fn readStringToNull =
	(
		local returnString = ""
		local complete = false
		while not complete do
		(
			local byte = readByte file #unsigned
			if (byte != 0) then
			(
				local char = bit.intAsChar byte
				returnString += char
			)
			else (complete = true)
		)
		returnString
	),
	fn readStringFixed length =
	(
		local returnString = ""
		for i = 1 to length do
		(
			local byte = readByte file #unsigned
			local char = bit.intAsChar byte
			returnString += char
		)
		returnString
	)
)

struct control_point
(
	position = [0.0,0.0,0.0],
	orientation = quat 0.0 0.0 0.0 1.0
)

controlPoints = #()
trakFile = binReader ()
trakFile.lastPath = "C:\\Program Files\\Microsoft Games\\Halo Custom Edition\\tags\\camera\\"
loaded = trakFile.promptPath "Load Camera Track" "Camera Track Tag (*.camera_track)|*.camera_track|" endian:#big
if loaded then
(
	trakFile.setPosition 0x46
	local controlPointCount = trakFile.readInt16 type:#unsigned
	trakFile.setPosition 0x70
	for c = 1 to controlPointCount do
	(
		controlPoints[c] = control_point ()
		local pos_x = trakFile.readFloat32 ()
		local pos_y = trakFile.readFloat32 ()
		local pos_z = trakFile.readFloat32 ()
		controlPoints[c].position = [pos_x,pos_y,pos_z] * 100
		local rot_i = trakFile.readFloat32 ()
		local rot_j = trakFile.readFloat32 ()
		local rot_k = trakFile.readFloat32 ()
		local rot_w = trakFile.readFloat32 ()
		controlPoints[c].orientation = inverse (quat rot_i rot_j rot_k rot_w)
		trakFile.advPosition 0x20
		
		local ctrlPoint = pyramid ()
		ctrlPoint.width = 25
		ctrlPoint.depth = 25
		ctrlPoint.height = 25
		ctrlPoint.objectOffsetRot = quat 0.0 -0.707107 0.0 0.707107
		ctrlPoint.wirecolor = color 86 86 86
		
		ctrlPoint.rotation = controlPoints[c].orientation
		ctrlPoint.position = controlPoints[c].position
		local numberString = if ((c - 1) < 10) then ("0" + (c - 1) as string) else ((c - 1) as string)
		ctrlPoint.name = "control_point" + numberString
	)
)
trakFile.unload ()