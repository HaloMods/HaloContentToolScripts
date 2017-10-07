--SleepyZay--

fn addHexaDecimalPadding nr = (
	case of (
		(nr <= 15): ("0" + ((bit.intAsHex(nr))as string))
		(nr > 15): ((bit.intAsHex(nr))as string)
	)
)	
fn ReadFixedString bstream fixedLen = (
   local str = ""
   For i = 1 to fixedLen do
   (
      str0 = ReadByte bstream #unsigned
      If str0!=0xFD AND str0!=0xFC do str+= bit.intAsChar str0
   )
   str
)
fn ReadFixedByteString bstream fixedLen = (
   local str = ""
   For i = 1 to fixedLen do
   (
      str += addHexaDecimalPadding (ReadByte bstream #unsigned)
	  If mod i 1 == 0 do str += " "
   )
   str
   print str
)
fn ReadBEShort fstream = (
short = readshort fstream #unsigned
short = bit.swapBytes short 2 1
b = (bit.get short 16)
for i = 17 to 32 do short = bit.set short i b
return short
)
fn ReadBElong fstream = (
long = readlong fstream
long = bit.swapBytes long 1 4
long = bit.swapBytes long 2 3
return long
)
fn ReadBEfloat fstream = (
return floatSwap2(readfloat fstream)
)
fn paddstring len instring = (
	instring=instring as string
	local str=""
	if instring.count <=len then (
		for i = 1 to (len-instring.count) do(
			str+="0"
		)
		str = (str+instring)
	)
	else (
		for i = 1 to len do(
			str+="0";str[i]=instring[i]
		)
	)
	str
)
fn printHex num = (
	print (bit.intashex(num))
)
fn printHere bstream = (
	Print ("Here @ 0x"+((bit.intAsHex(ftell bstream))as string))
)
fn getBoundBox bstream fscale = (
	currBBMax = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
	currBBMin = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
	currA = currBBMax - currBBMin
	
	bb = box()
	bb.width = abs(currA[1])
	bb.length = abs(currA[2])
	bb.height = abs(currA[3])
-- 	hide bb
	delete bb
)
fn getName bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	_name = readstring bstream
	fseek bstream backJump #seek_set
	return _name
)
fn ReadHalfFloat fstream = (
    hf=readshort fstream #unsigned
    sign = bit.get hf 16
    exponent = (bit.shift (bit.and hf (bit.hexasint "7C00")) -10) as integer - 16
    fraction = bit.and hf (bit.hexasint "03FF")
    if sign==true then sign = 1 else sign = 0
    exponentF = exponent + 127
    outputAsFloat = bit.or (bit.or (bit.shift fraction 13) \
    (bit.shift exponentF 23)) (bit.shift sign 31)
return bit.intasfloat outputasfloat*2
)


struct weight_data (
	boneids,weights
)

fname = GetOpenFileName caption:"Halo Wars 2" types:" (*.ugx)|*.ugx" historyCategory:""
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=25
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

magic = readfixedstring f 4
tableOffset = readbelong f
ukw = readlong f
fileSize = readbelong f
tableCount = readbeshort f
null = readbeshort f
ukw2 = readbelong f

dataType=#()
dataOffset=#()
dataLength=#()
fseek f tableOffset #seek_set
for x=1 to tableCount do (
	null = readbelong f
	dataType[x] = readbelong f
	dataOffset[x] = readbelong f
	dataLength[x] = readbelong f
	ukw2 = for y=1 to 4 collect (readbeshort f)
	
-- 	printHex dataType[x]
-- 	printHex dataOffset[x]
-- 	printHex dataLength[x]
-- 	format "\n"
)

faceCount=#()
faceOffset=#()
vertCount=#()
vertOffset=#()
vertLength=#()
vertSize=#()
ukwArr=#()
lodArr=#()

BNArr=#()
vertBufferArr=#()
uvBufferArr=#()
weightBufferArr=#()
faceBufferArr=#()

meshCount=0
for x=1 to tableCount do (
	subDataOffset=#()
	subDataCount=#()
	
	fseek f dataOffset[x] #seek_set
-- 	printHex dataType[x]
-- 	printHex dataOffset[x]
	
	-- model data --
	if dataType[x] == 0x700 do (
		subTableCount = readshort f
		ukw2 = readshort f
		null = readlong f
		fseek f 0x30 #seek_cur
		ukw = readlong f
		null = readlong f
		
		for y=1 to subTableCount do (
			subDataCount[y] = readlonglong f
			subDataOffset[y] = readlonglong f + dataOffset[x]
		)
		for y=1 to subTableCount do (
			fseek f subDataOffset[y] #seek_set
			--mesh info --
			if y==1 do (
-- 				printHere f
				meshCount = subDataCount[y]
				for z=1 to subDataCount[y] do (
					ukwArr[z] = for a=1 to 4 collect (readlong f)
					faceOffset[z] = readlong f
					faceCount[z] = readlong f
					vertOffset[z] = readlong f
					vertLength[z] = readlong f
					vertSize[z] = readlong f
					vertCount[z] = readlong f
					ukw = readlong f
					lodArr[z] = readfloat f
					fseek f 0x18 #seek_cur
				)
			)
			--bone data --
			if y==2 do (
				for z=1 to subDataCount[y] do (
					boneName = getName f (readlong f + dataOffset[x])
					null = readlong f
					m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
					m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
					m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
					m41 = readfloat f; m42 = readfloat f; m43 = readfloat f; m44 = readfloat f
					tfm = matrix3 [m11,m21,m31] [m12,m22,m32] [m13,m23,m33] [m14,m24,m34]	
					parentID = readlong f #unsigned + 1
					null = readlong f
					
					newBone = bonesys.createbone	\
					tfm.row4	\
					(tfm.row4 + 0.01 * (normalize tfm.row1)) \
					(normalize tfm.row3)
					newBone.width = 0.1
					newBone.height = 0.1
		 			newBone.wirecolor = white
					newbone.showlinks = true
					newBone.transform = tfm
					newBone.name = boneName
					
					pos = [m41,m42,m43]
					pos *= tfm
					newBone.pos.x += ((fscale)*pos.x)
					newBone.pos.y += ((-fscale)*pos.y)
					newBone.pos.z += ((-fscale)*pos.z)
					
					newBone.setBoneEnable false 0
					newBone.pos.controller = TCB_position ()
					newBone.rotation.controller = TCB_rotation ()
 					
					if (parentID != 0) then (
					newBone.parent = BNArr[parentID]
				   )
 					
					append BNArr newBone
				)
				rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
				for b in BNArr where b.parent==undefined do b.parent = rootRT
				rootRT.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
			)
			if y==3 do ()
			if y==4 do ()
			if y==5 do (	--markers?
				for z=1 to subDataCount[y] do (
					pos1 = ([readfloat f,readfloat f,readfloat f]*fscale)
					pos2 = ([readfloat f,readfloat f,readfloat f]*fscale)
				)				
				
			)
		)
	)
	-- face data --
	if dataType[x] == 0x701 do (
		for z=1 to meshCount do (
			Face_array=#()
			for a=1 to faceCount[z] do (
				fa=ReadShort f +1
				fb=ReadShort f +1
				fc=ReadShort f +1
				append Face_array[fa,fb,fc]
			)
			
			faceBufferArr[z] = Face_array
		)
	)
	-- vert data --
	if dataType[x] == 0x702 do (
		for z=1 to meshCount do (
			Vert_array=#()
			UV_array=#()
			Weight_array=#()
			
			printHex vertSize[z]
			printHere f
			
			if vertSize[z] == 0x08 do (
				for a=1 to vertCount[z] do (
					vx = ReadHalfFloat f 
					vy = ReadHalfFloat f 
					vz = ReadHalfFloat f 
					p1 = readshort f
					
					append Vert_array([vx,vy,vz]*fscale)
					append UV_array([0,0,0])
				)
			)
			if vertSize[z] == 0x14 do (
				for a=1 to vertCount[z] do (
					vx = ReadHalfFloat f 
					vy = ReadHalfFloat f 
					vz = ReadHalfFloat f 
					p1 = readshort f
					tu = ReadHalfFloat f
					tv = ReadHalfFloat f
					ukw = readfloat f
					ukw2 = readfloat f
					
					append Vert_array([vx,vy,vz]*fscale)
					append UV_array([tu,1-tv,0])
				)
			)
			if vertSize[z] == 0x18 do (
				for a=1 to vertCount[z] do (
					vx = ReadHalfFloat f 
					vy = ReadHalfFloat f 
					vz = ReadHalfFloat f 
					p1 = readshort f
					tu = ReadHalfFloat f
					tv = ReadHalfFloat f
					ukw = readfloat f
					ukw2 = readfloat f
					ukw3 = readfloat f
					
					append Vert_array([vx,vy,vz]*fscale)
					append UV_array([tu,1-tv,0])
				)
			)
			if vertSize[z] == 0x1c do (
				for a=1 to vertCount[z] do (
					w = (weight_data boneids:#() weights:#())
					
					vx = ReadHalfFloat f 
					vy = ReadHalfFloat f 
					vz = ReadHalfFloat f 
					p1 = readshort f
					tu = ReadHalfFloat f
					tv = ReadHalfFloat f
					ukw = readfloat f
					ukw2 = readfloat f
					bone1 = readbyte f #unsigned 
					bone2 = readbyte f #unsigned
					bone3 = readbyte f #unsigned
					bone4 = readbyte f #unsigned
					weight1 = readbyte f #unsigned
					weight2 = readbyte f #unsigned
					weight3 = readbyte f #unsigned
					weight4 = readbyte f #unsigned
					
					maxweight = 0
					if(bone1 != 0xFF) then
						maxweight = maxweight + weight1
					if(bone2 != 0xFF) then
						maxweight = maxweight + weight2
					if(bone3 != 0xFF) then
						maxweight = maxweight + weight3
					if(bone4 != 0xFF) then
						maxweight = maxweight + weight4
						
					if(maxweight != 0) then (
						mxw = 255.0
						if(bone1 != 0xFF) then (
							w1 = weight1 as float
							append w.boneids (bone1+1)
							append w.weights (w1 / mxw)
						)
						if(bone2 != 0xFF) then (
							w2 = weight2 as float
							append w.boneids (bone2+1)
							append w.weights (w2 / mxw)
						)
						if(bone3 != 0xFF) then (
							w3 = weight3 as float
							append w.boneids (bone3+1)
							append w.weights (w3 / mxw)
						)
						if(bone4 != 0xFF) then (
							w4 = weight4 as float
							append w.boneids (bone4+1)
							append w.weights (w4 / mxw)
						)		
					)
					
					append Vert_array([vx,vy,vz]*fscale)
					append UV_array([tu,1-tv,0])
					append Weight_array w
				)
			)
			
			vertBufferArr[z] = Vert_array
			uvBufferArr[z] = UV_array
			weightBufferArr[z] = Weight_array
		)
	)
)

for z=1 to meshCount do (
	msh = mesh vertices:vertBufferArr[z] faces:faceBufferArr[z]
	msh.numTVerts = uvBufferArr[z].count
	
-- 	msh.name = bit.intashex(lodArr[z]) as string
	msh.name = bit.intashex(vertSize[z]) as string
	msh.wirecolor = random black white
	msh.transform = (matrix3 [-1,0,0] [0,0,1] [0,-1,0] [0,0,0])
	buildTVFaces msh
	for j = 1 to uvBufferArr[z].count do setTVert msh j uvBufferArr[z][j]
	for j = 1 to faceBufferArr[z].count do setTVFace msh j faceBufferArr[z][j]
	
	-- Applying Skinning --
	max modify mode
	select msh
	skinMod = skin ()
	addModifier msh skinMod
	for i = 1 to BNArr.count do (
		
		maxbone = getnodebyname BNArr[i].name
		if i != BNArr.count then
			skinOps.addBone skinMod maxbone 0
		else
			skinOps.addBone skinMod maxbone 1
	)
	-- Applying Weights --
	modPanel.setCurrentObject skinMod
	for i = 1 to weightBufferArr[z].count do (
		w = weightBufferArr[z][i]
		bi = #() --bone index array
		wv = #() --weight value array
		
		for j = 1 to w.boneids.count do (
			boneid = w.boneids[j]
			weight = w.weights[j]
			append bi boneid
			append wv weight
		)	
		
		skinOps.ReplaceVertexWeights skinMod i bi wv
	)
-- 	if lodArr[z] == 0x14 do (hide msh)
)




Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f