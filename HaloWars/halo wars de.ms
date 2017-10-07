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
fn ApplyNormals msh Normal_array = (
	max modify mode
	select msh
		
	--set smoothing group of all faces to 1 to get one normal per vertex
	for face = 1 to msh.numfaces do setFaceSmoothGroup msh face 1
		--set normals via edit normals modifier
		select msh
		addmodifier msh (Edit_Normals ()) ui:off
		msh.Edit_Normals.MakeExplicit selection:#{1..Normal_array.count}
		EN_convertVS = msh.Edit_Normals.ConvertVertexSelection
		EN_setNormal = msh.Edit_Normals.SetNormal
		normID = #{}
	
		--apply normals
		for v = 1 to Normal_array.count do
		(
			free normID
			EN_convertVS #{v} &normID
			for id in normID do EN_setNormal id Normal_array[v]
		)
		collapseStack msh
	max create mode

)

struct weight_data (
	boneids,weights
)

struct _polyInfo (
	vertCount,
	vertOffset,
	vertSize,
	vertLength,
	faceCount,
	faceOffset,
	matID,
	polyID,
	boneID,
	polyName
)

fname = GetOpenFileName caption:"Halo Wars" types:" (*.ugx)|*.ugx" historyCategory:""
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
null = readlonglong f

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

BNArr=#()
polyElmArr=#()
meshArr=#()
bbArr=#(#(),#())

vertStart = 0
faceStart = 0
matCount = 0
for x=1 to tableCount do (
	subDataOffset=#()
	subDataCount=#()
	
	fseek f dataOffset[x] #seek_set
	format "type: 0x% offset: 0x% \n"	(bit.intashex(dataType[x])) (paddstring 5 (bit.intashex(dataOffset[x])))
	
	-- mesh info --
	if dataType[x] == 0x700 do (
		subTableCount = readshort f
		ukw2 = readshort f
		null = readlong f
		fseek f 0x30 #seek_cur
		ukw = readlong f
		null = readlong f
		
		for y=1 to 6 do (
			subDataCount[y] = readlonglong f
			subDataOffset[y] = readlonglong f + dataOffset[x]
-- 			format "% subDataCount: 0x% subDataOffset: 0x%\n" y (paddstring 2 (bit.intashex(subDataCount[y] as integer) )) (bit.intashex(subDataOffset[y] as integer))
			
			backJump = ftell f
			fseek f subDataOffset[y] #seek_set
			--mesh data --
			if y==1 do (
-- 				printHere f
				for z=1 to subDataCount[y] do (
					polyInfo = _polyInfo()
					
					polyInfo.matID = readlong f + 1
					polyInfo.polyID = readlong f + 1
					ukwID = readlong f + 1
					polyInfo.boneID = readlong f+ 1	--some polygon elements are bound to a single bone
					polyInfo.faceOffset = readlong f
					polyInfo.faceCount = readlong f
					polyInfo.vertOffset = readlong f
					polyInfo.vertLength = readlong f
					polyInfo.vertSize = readlong f
					polyInfo.vertCount = readlong f
					fseek f 0x10 #seek_cur
					polyInfo.polyName = getName f (readlong f + dataOffset[x])
					fseek f 0x5c #seek_cur
					
					if polyInfo.matID > matCount do matCount = polyInfo.matID
					if meshArr[polyInfo.polyID] == undefined do meshArr[polyInfo.polyID] = #()
					append meshArr[polyInfo.polyID] polyInfo
				)
-- 				printHere f
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
					newbone.showlinks = false
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
			-- link data --
			if y==3 do (
				polyElmIDOffset = #()
				polyElmCount = #()
				polyElmID = #()
				
				for z=1 to subDataCount[y] do (	--meshCount
					ukw = readlong f		--bone related
					ukw2 = readlong f		--bone related, two added together never goes higher than boneCount
					polyElmCount[z] = readlonglong f	-- total of polyElm's per mesh
					polyElmIDOffset[z] = readlonglong f + dataOffset[x]
				)
				
				for z=1 to subDataCount[y] do (
					fseek f polyElmIDOffset[z] #seek_set
					polyElmID[z] = for a=1 to polyElmCount[z] collect (readlong f)
				)
				
-- 				for a in polyElmID do print a #nomap
			)
			--mesh id--
			if y==4 do (
				meshID = for z=1 to subDataCount[y] collect (readlong f)
			)
			--min bound --
			if y==5 do (
				for z=1 to subDataCount[y] do (
					append bbArr[1] ([readfloat f,readfloat f,readfloat f]*fscale)
				)				
			)
			--max bound --
			if y==6 do (
				for z=1 to subDataCount[y] do (
					append bbArr[2] ([readfloat f,readfloat f,readfloat f]*fscale)
				)				
			)
			
			fseek f backJump #seek_set
		)
	)
	-- index data --
	if dataType[x] == 0x701 do (		
		faceStart = ftell f
	)
	-- vertex data --
	if dataType[x] == 0x702 do (
		vertStart = ftell f
	)
	format "\n"
)

mat = MultiMaterial numsubs:matCount showInViewport:true
meditMaterials[1] = mat
for x=1 to meshArr.count do (		--meshArr.count
	Vert_Array=#()
	Face_Array=#()
	UV_Array=#()
	Normal_Array=#()
	Weight_Array=#()
	Mat_Array=#()
	
	vertTotal = 0
	for a in meshArr[x] do (
		mat.materialList[a.matID].Diffuse = random black white
		mat.materialList[a.matID].specularLevel = 40
		mat.materialList[a.matID].glossiness = 30
		
		--verts --
		fseek f (a.vertOffset + vertStart) #seek_set
-- 		printHex a.vertSize
-- 		printHere f
		if a.vertSize == 0x18 do (
			for y=1 to a.vertCount do (
				w = (weight_data boneids:#() weights:#())
				
				vx = ReadHalfFloat f 
				vy = ReadHalfFloat f 
				vz = ReadHalfFloat f 
				p1 = ReadHalfFloat f
				nx = readfloat f 
				ny = readfloat f 
				nz = readfloat f 
				tu = ReadHalfFloat f
				tv = ReadHalfFloat f
				
				bone1 = a.boneID
				bone2 = 0
				bone3 = 0
				bone4 = 0
				weight1 = 255
				weight2 = 255
				weight3 = 255
				weight4 = 255
				
				maxweight = 0
				if(bone1 != 0) then
					maxweight += weight1
				if(bone2 != 0) then
					maxweight += weight2
				if(bone3 != 0) then
					maxweight += weight3
				if(bone4 != 0) then
					maxweight += weight4
					
				if(maxweight != 0) then (
					mxw = 255.0
					if(weight1 != 0) then (
						w1 = weight1 as float
						append w.boneids (bone1)
						append w.weights (w1 / mxw)
					)
					if(weight2 != 0) then (
						w2 = weight2 as float
						append w.boneids (bone2)
						append w.weights (w2 / mxw)
					)
					if(weight3 != 0) then (
						w3 = weight3 as float
						append w.boneids (bone3)
						append w.weights (w3 / mxw)
					)
					if(weight4 != 0) then (
						w4 = weight4 as float
						append w.boneids (bone4)
						append w.weights (w4 / mxw)
					)		
				)
				
				append Vert_array([vx,vy,vz]*fscale)
				append UV_array([tu,1-tv,0])
				append Normal_array([nx,ny,nz])
				append Weight_array w
			)
		)
		if a.vertSize == 0x1c do (
			for y=1 to a.vertCount do (
				w = (weight_data boneids:#() weights:#())
				
				vx = ReadHalfFloat f 
				vy = ReadHalfFloat f 
				vz = ReadHalfFloat f 
				p1 = ReadHalfFloat f
				nx = readfloat f 
				ny = readfloat f 
				nz = readfloat f 
				tu = ReadHalfFloat f
				tv = ReadHalfFloat f
				ukw = ReadHalfFloat f
				ukw2 = ReadHalfFloat f
				
				bone1 = a.boneID
				bone2 = 0
				bone3 = 0
				bone4 = 0
				weight1 = 255
				weight2 = 255
				weight3 = 255
				weight4 = 255
				
				maxweight = 0
				if(bone1 != 0) then
					maxweight += weight1
				if(bone2 != 0) then
					maxweight += weight2
				if(bone3 != 0) then
					maxweight += weight3
				if(bone4 != 0) then
					maxweight += weight4
					
				if(maxweight != 0) then (
					mxw = 255.0
					if(weight1 != 0) then (
						w1 = weight1 as float
						append w.boneids (bone1)
						append w.weights (w1 / mxw)
					)
					if(weight2 != 0) then (
						w2 = weight2 as float
						append w.boneids (bone2)
						append w.weights (w2 / mxw)
					)
					if(weight3 != 0) then (
						w3 = weight3 as float
						append w.boneids (bone3)
						append w.weights (w3 / mxw)
					)
					if(weight4 != 0) then (
						w4 = weight4 as float
						append w.boneids (bone4)
						append w.weights (w4 / mxw)
					)		
				)
				
				append Vert_array([vx,vy,vz]*fscale)
				append UV_array([tu,1-tv,0])
				append Normal_array([nx,ny,nz])
				append Weight_array w
			)
		)
		if a.vertSize == 0x20 do (
			for y=1 to a.vertCount do (
				w = (weight_data boneids:#() weights:#())
				
				vx = ReadHalfFloat f 
				vy = ReadHalfFloat f 
				vz = ReadHalfFloat f 
				p1 = ReadHalfFloat f
				nx = readfloat f 
				ny = readfloat f 
				nz = readfloat f 
				bone1 = readbyte f #unsigned 
				bone2 = readbyte f #unsigned
				bone3 = readbyte f #unsigned
				bone4 = readbyte f #unsigned
				weight1 = readbyte f #unsigned
				weight2 = readbyte f #unsigned
				weight3 = readbyte f #unsigned
				weight4 = readbyte f #unsigned
				tu = ReadHalfFloat f
				tv = ReadHalfFloat f
				
				maxweight = 0
				if(bone1 != 0) then
					maxweight += weight1
				if(bone2 != 0) then
					maxweight += weight2
				if(bone3 != 0) then
					maxweight += weight3
				if(bone4 != 0) then
					maxweight += weight4
					
				if(maxweight != 0) then (
					mxw = 255.0
					if(weight1 != 0) then (
						w1 = weight1 as float
						append w.boneids (bone1)
						append w.weights (w1 / mxw)
					)
					if(weight2 != 0) then (
						w2 = weight2 as float
						append w.boneids (bone2)
						append w.weights (w2 / mxw)
					)
					if(weight3 != 0) then (
						w3 = weight3 as float
						append w.boneids (bone3)
						append w.weights (w3 / mxw)
					)
					if(weight4 != 0) then (
						w4 = weight4 as float
						append w.boneids (bone4)
						append w.weights (w4 / mxw)
					)		
				)
				
				append Vert_array([vx,vy,vz]*fscale)
				append UV_array([tu,1-tv,0])
				append Normal_array([nx,ny,nz])
				append Weight_array w
			)
		)
		if a.vertSize == 0x24 do (
			for y=1 to a.vertCount do (
				w = (weight_data boneids:#() weights:#())
				
				vx = ReadHalfFloat f 
				vy = ReadHalfFloat f 
				vz = ReadHalfFloat f 
				p1 = ReadHalfFloat f
				nx = readfloat f 
				ny = readfloat f 
				nz = readfloat f
				b1 = readfloat f 
				b2 = readfloat f 
				b3 = readfloat f 
				tu = ReadHalfFloat f
				tv = ReadHalfFloat f
				
				bone1 = a.boneID
				bone2 = 0
				bone3 = 0
				bone4 = 0
				weight1 = 255
				weight2 = 255
				weight3 = 255
				weight4 = 255
				
				maxweight = 0
				if(bone1 != 0) then
					maxweight += weight1
				if(bone2 != 0) then
					maxweight += weight2
				if(bone3 != 0) then
					maxweight += weight3
				if(bone4 != 0) then
					maxweight += weight4
					
				if(maxweight != 0) then (
					mxw = 255.0
					if(weight1 != 0) then (
						w1 = weight1 as float
						append w.boneids (bone1)
						append w.weights (w1 / mxw)
					)
					if(weight2 != 0) then (
						w2 = weight2 as float
						append w.boneids (bone2)
						append w.weights (w2 / mxw)
					)
					if(weight3 != 0) then (
						w3 = weight3 as float
						append w.boneids (bone3)
						append w.weights (w3 / mxw)
					)
					if(weight4 != 0) then (
						w4 = weight4 as float
						append w.boneids (bone4)
						append w.weights (w4 / mxw)
					)		
				)
				
				append Vert_array([vx,vy,vz]*fscale)
				append UV_array([tu,1-tv,0])
				append Normal_array([nx,ny,nz])
				append Weight_array w
			)
		)
		if a.vertSize == 0x28 do (
			for y=1 to a.vertCount do (
				w = (weight_data boneids:#() weights:#())
				
				vx = ReadHalfFloat f 
				vy = ReadHalfFloat f 
				vz = ReadHalfFloat f 
				p1 = ReadHalfFloat f
				nx = readfloat f 
				ny = readfloat f 
				nz = readfloat f
				b1 = readfloat f 
				b2 = readfloat f 
				b3 = readfloat f 
				tu = ReadHalfFloat f
				tv = ReadHalfFloat f
				null = readlong f	--probably data here, never checked all buffers
				
				bone1 = a.boneID
				bone2 = 0
				bone3 = 0
				bone4 = 0
				weight1 = 255
				weight2 = 255
				weight3 = 255
				weight4 = 255
				
				maxweight = 0
				if(bone1 != 0) then
					maxweight += weight1
				if(bone2 != 0) then
					maxweight += weight2
				if(bone3 != 0) then
					maxweight += weight3
				if(bone4 != 0) then
					maxweight += weight4
					
				if(maxweight != 0) then (
					mxw = 255.0
					if(weight1 != 0) then (
						w1 = weight1 as float
						append w.boneids (bone1)
						append w.weights (w1 / mxw)
					)
					if(weight2 != 0) then (
						w2 = weight2 as float
						append w.boneids (bone2)
						append w.weights (w2 / mxw)
					)
					if(weight3 != 0) then (
						w3 = weight3 as float
						append w.boneids (bone3)
						append w.weights (w3 / mxw)
					)
					if(weight4 != 0) then (
						w4 = weight4 as float
						append w.boneids (bone4)
						append w.weights (w4 / mxw)
					)		
				)
				
				append Vert_array([vx,vy,vz]*fscale)
				append UV_array([tu,1-tv,0])
				append Normal_array([nx,ny,nz])
				append Weight_array w
			)
		)
		if a.vertSize == 0x2c do (
			for y=1 to a.vertCount do (
				w = (weight_data boneids:#() weights:#())
				
				vx = ReadHalfFloat f 
				vy = ReadHalfFloat f 
				vz = ReadHalfFloat f 
				p1 = ReadHalfFloat f
				nx = readfloat f 
				ny = readfloat f 
				nz = readfloat f
				b1 = readfloat f 
				b2 = readfloat f 
				b3 = readfloat f 
				bone1 = readbyte f #unsigned 
				bone2 = readbyte f #unsigned
				bone3 = readbyte f #unsigned
				bone4 = readbyte f #unsigned
				weight1 = readbyte f #unsigned
				weight2 = readbyte f #unsigned
				weight3 = readbyte f #unsigned
				weight4 = readbyte f #unsigned
				tu = ReadHalfFloat f
				tv = ReadHalfFloat f
				
				maxweight = 0
				if(bone1 != 0) then
					maxweight += weight1
				if(bone2 != 0) then
					maxweight += weight2
				if(bone3 != 0) then
					maxweight += weight3
				if(bone4 != 0) then
					maxweight += weight4
					
				if(maxweight != 0) then (
					mxw = 255.0
					if(weight1 != 0) then (
						w1 = weight1 as float
						append w.boneids (bone1)
						append w.weights (w1 / mxw)
					)
					if(weight2 != 0) then (
						w2 = weight2 as float
						append w.boneids (bone2)
						append w.weights (w2 / mxw)
					)
					if(weight3 != 0) then (
						w3 = weight3 as float
						append w.boneids (bone3)
						append w.weights (w3 / mxw)
					)
					if(weight4 != 0) then (
						w4 = weight4 as float
						append w.boneids (bone4)
						append w.weights (w4 / mxw)
					)		
				)
				
				append Vert_array([vx,vy,vz]*fscale)
				append UV_array([tu,1-tv,0])
				append Normal_array([nx,ny,nz])
				append Weight_array w
			)
		)
		if a.vertSize == 0x30 do (
			for y=1 to a.vertCount do (
				w = (weight_data boneids:#() weights:#())
				
				vx = ReadHalfFloat f 
				vy = ReadHalfFloat f 
				vz = ReadHalfFloat f 
				p1 = ReadHalfFloat f
				nx = readfloat f 
				ny = readfloat f 
				nz = readfloat f
				b1 = readfloat f 
				b2 = readfloat f 
				b3 = readfloat f 
				bone1 = readbyte f #unsigned 
				bone2 = readbyte f #unsigned
				bone3 = readbyte f #unsigned
				bone4 = readbyte f #unsigned
				weight1 = readbyte f #unsigned
				weight2 = readbyte f #unsigned
				weight3 = readbyte f #unsigned
				weight4 = readbyte f #unsigned
				tu = ReadHalfFloat f
				tv = ReadHalfFloat f
				ukw = readlong f
				
				maxweight = 0
				if(bone1 != 0) then
					maxweight += weight1
				if(bone2 != 0) then
					maxweight += weight2
				if(bone3 != 0) then
					maxweight += weight3
				if(bone4 != 0) then
					maxweight += weight4
					
				if(maxweight != 0) then (
					mxw = 255.0
					if(weight1 != 0) then (
						w1 = weight1 as float
						append w.boneids (bone1)
						append w.weights (w1 / mxw)
					)
					if(weight2 != 0) then (
						w2 = weight2 as float
						append w.boneids (bone2)
						append w.weights (w2 / mxw)
					)
					if(weight3 != 0) then (
						w3 = weight3 as float
						append w.boneids (bone3)
						append w.weights (w3 / mxw)
					)
					if(weight4 != 0) then (
						w4 = weight4 as float
						append w.boneids (bone4)
						append w.weights (w4 / mxw)
					)		
				)
				
				append Vert_array([vx,vy,vz]*fscale)
				append UV_array([tu,1-tv,0])
				append Normal_array([nx,ny,nz])
				append Weight_array w
			)
		)
		
		-- indices --
		fseek f ((a.faceOffset * 2) + faceStart) #seek_set
		for y=1 to a.faceCount do (
			fa = (ReadShort f #unsigned + 1) + vertTotal
			fb = (ReadShort f #unsigned + 1) + vertTotal
			fc = (ReadShort f #unsigned + 1) + vertTotal
			
			append Face_Array[fa,fb,fc]
			append Mat_Array a.matID
		)
		
		vertTotal += a.vertCount
	)
	
	msh = mesh vertices:Vert_array faces:Face_Array materialIDs:Mat_Array
	msh.numTVerts = UV_array.count
	msh.material = mat
	msh.transform = (matrix3 [-1,0,0] [0,0,1] [0,-1,0] [0,0,0])
	buildTVFaces msh
	for j = 1 to UV_array.count Do setTVert msh j UV_array[j]
	for j = 1 to Face_array.count Do setTVFace msh j Face_array[j]
	ApplyNormals msh Normal_Array
	
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
	for i = 1 to Weight_Array.count do (
		w = Weight_Array[i]
		bi = #() --bone index array
		wv = #() --weight value array
		
		for j = 1 to w.boneids.count do (
			boneid = w.boneids[j]
			weight = w.weights[j]
			
			if boneid == 0 do boneid += 1
			
			append bi boneid
			append wv weight
		)	
		
		skinOps.ReplaceVertexWeights skinMod i bi wv
	)
	
)

Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f