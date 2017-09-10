clearListener()

global importFilepath
if importFilepath==undefined then
	importFilepath= "C:\\Program Files\\Microsoft Games\\"+	\
			"Halo Custom Edition\\tags\\vehicles\\*.physics"

fn readFloatB in_file = -- anim importer's
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
	isNegative = mybitarray[1]
	for i = 9 to 2 by -1 do
		if mybitarray[i] do exp += 1.0 * 2.0^(9-i)
	
	exp -= 127.0
	for i = 10 to 32 by 1 do
		if mybitarray[i] then
			mantissaString += "1"
		else
			mantissaString += "0"
	
	for i = 1 to mantissaString.count do
	(
		myFloat += (mantissaString[i] as float) * 2.0^exp
		exp -= 1
	)
	if mybitarray[1] do myFloat = myFloat * -1.0
	myFloat
)

fn readShortB in_file strType skip2:false =	--	from import gbx
(	--	2 bytes, reverse order
	b1 = readByte in_file #unsigned
	b2 = readByte in_file #unsigned
	
	if skip2 then fSeek handle 2 #seek_cur
	
	bigEndianShort = (b1 * 256) + b2
	if strType == #signed then
		if bigEndianShort > 32768 then
			(65536 - bigEndianShort) * -1
		else
			bigEndianShort
	else
		bigEndianShort
)

fn readLongB in_file strType skip2:false =
(
	b1 = readByte in_file #unsigned
	b2 = readByte in_file #unsigned
	b3 = readByte in_file #unsigned
	b4 = readByte in_file #unsigned
	
	if skip2 then fSeek handle 2 #seek_cur
	
	bigEndianLong = (b1 * 16777216) + (b2 * 65536) + (b3 * 256) + (b4 * 1)
	if strType == "#signed" then
		if bigEndianLong as float > 2147483648 as float then
			(4294967296 - bigEndianLong) * -1
		else
			bigEndianLong
	else
		bigEndianLong
)

--		--		--		--		--		--		--		--		--		--		--

handle= 0

fn fPosGet = fTell handle
fn fPosSet p = fSeek handle p #seek_set
fn rByte = readByte handle #unsigned
fn rFloat pos:undefined offset:undefined = 
(
	if pos!=undefined then fSeek handle pos #seek_set
	if offset!=undefined then fSeek handle offset #seek_cur
	readFloatB handle
)
fn rShort pos:undefined signed:false offset:undefined = 
(
	if pos!=undefined then fPosSet pos
	if offset!=undefined then fSeek handle offset #seek_cur
	
	if signed then
		readShortB handle #signed
	else
		readShortB handle #unsigned
)
fn rLong pos:undefined signed:false = 
(
	if pos!=undefined then fPosSet pos
	if signed then
		readLongB handle #signed
	else
		readLongB handle #unsigned
)
fn rStr =
(
	p= fPosGet()
	s= readString handle
	fPosSet ( p+0x20 )
	s
)
fn rP3 = 	[rFloat(), rFloat(), rFloat()]

--		--		--		--		--		--		--		--		--		--		--
listPropertiesStruct
fn listProperties aStruct iStruct =
(
	s= aStruct as string
	tk=filterString s "\n\r"
--	throw a fit
	deleteItem tk 1	--	"#Struct:aStruct("
	tk=for s in tk collect trimLeft (filterString s ":")[1]
	sort tk
	listPropertiesStruct= iStruct
	for s in tk do 
	(
		v= readValue (StringStream ("listPropertiesStruct."+s))
		if not ((isKindOf v Array) or (isKindOf v MAXScriptFunction)) then
			format "%=%\n" s v
	)
	
	format "\n"
)

struct PhysicsTag
(
	radius,
	momentScale,
	mass,
	centerOfMass,
	density,
	gravityScale,
	groundFriction,
	groundDepth,
	groundDampFraction,
	groundNormalK1,
	groundNormalK0,
	waterFriction,
	waterDepth,
	waterDensity,
	airFriction,
	xxMoment,
	yyMoment,
	zzMoment,
	poweredMasspoints,
	masspoints,
	fn print iStruct = listProperties PhysicsTag iStruct
)

struct PoweredMassPoint
(
	name,
	agStrength,
	agOffset,
	agHeight,
	agDampFraction,
	agNormK1,
	agNormK0,
	fn print iStruct = listProperties PoweredMassPoint iStruct
)

struct Masspoint
(
	name,
	poweredMasspoint,
	modelNode,
	flags,
	relativeMass,
	mass,
	relativeDensity,
	density,
	position,
	forward,
	up,
	frictionType,
	frictionPara,
	frictionPerp,
	radius,
	fn print iStruct = listProperties MassPoint iStruct
)

fn rPoweredMasspoint =
(
	p= fPosGet()
	pmpName= rStr()
	
	pmp= PoweredMassPoint	name:			pmpName		\
							agStrength:		(rFloat())	\
							agOffset:		(rFloat())	\
							agHeight:		(rFloat())	\
							agDampFraction:	(rFloat())	\
							agNormK1:		(rFloat())	\
							agNormK0:		(rFloat())
	
--	pmp.print pmp
	
	fPosSet ( p+0x80 )
	return pmp				
)

fn rMasspoint =		--	size: 0x80
(
	p= fPosGet()
	mpName= rStr()	--	size: 0x20
	
	mp= MassPoint	name:				mpName					\
					poweredMasspoint:	(rShort signed:true)	\
					modelNode:			(rShort())				\
					flags:				(rLong())				\
					relativeMass:		(rFloat())				\
					mass:				(rFloat())				\
					relativeDensity:	(rFloat())				\
					density:			(rFloat())				\
					position:			(100*(rP3()))			\
					forward:			(rP3())					\
					up:					(rP3())					\
					frictionType:		(rShort())				\
					frictionPara:		(rFloat offset:2)		\
					frictionPerp:		(rFloat())				\
					radius:				(100*rFloat())
	
--	mp.print mp
	
	fPosSet ( p+0x80 )
	return mp				
)

fn rPoweredMasspoints nPmp =
(
	for i=1 to nPmp collect 
		(rPoweredMasspoint())
	--	returns an array
)

fn rMasspoints nMp =
(
	for i=1 to nMp collect 
		(rMasspoint())
	--	returns an array
)

fn rPhysicsTag phyTag =
(
	handle= fOpen phyTag "rb"
	
	nPmp= rShort pos:0xAA
	nMp= rShort pos:0xB6
	
	fPosSet 0x108
	poweredMasspoints= 	rPoweredMasspoints nPmp
	masspoints= 		rMasspoints nMp
	
	phyTag= PhysicsTag	radius:(rFloat pos:0x40)			\
						momentScale:(rFloat())				\
						mass:(rFloat())						\
						centerOfMass:(100*rP3())			\
						density:(rFloat())					\
						gravityScale:(rFloat())				\
						groundFriction:(rFloat())			\
						groundDepth:(rFloat())				\
						groundDampFraction:(rFloat())		\
						groundNormalK1:(rFloat())			\
						groundNormalK0:(rFloat())			\
						waterFriction:(rFloat offset:4)		\
						waterDepth:(rFloat())				\
						waterDensity:(rFloat())				\
						airFriction:(rFloat offset:4)		\
						xxMoment:(rFloat offset:4)			\
						yyMoment:(rFloat())					\
						zzMoment:(rFloat())					\
						poweredMasspoints:poweredMasspoints	\
						masspoints:masspoints
	
--	phyTag.print phyTag
	
	fClose handle
	
	phyTag
)
fn objDepth o =
(
	i=0
	while o.parent!=undefined do
	(
		i+=1
		o=o.parent
	)
	return i
)

fn fnHaloSort o1 o2 =
(
	d1=objDepth o1
	d2=objDepth o2
	if d1<d2 then return -1
	if d1>d2 then return 1
	if o1.name<o2.name then return -1
	if o1.name>o2.name then return 1
	return 0
)
fn haloSort nodeObjects =
(
	qSort nodeObjects fnHaloSort
	return nodeObjects
)

fn getPhyImportFilepath =
(
	gofnCaption= "Locate physics tag"
	ifp= importFilepath
	fTypes= "*.physics|*.physics"
	
	getOpenFileName caption:gofnCaption filename:ifp types:fTypes
)

fn vecRot o mpForward mpUp =
(
	mpTrans= o.transform.row4
	m= matrix3 mpForward (cross mpUp mpForward ) mpUp mpTrans
	o.transform=m
)

pmpAttribs= attributes poweredMasspointAttributes
(
	parameters poweredMasspointParams rollout:poweredMasspointRollout
	(
		name	type:#string ui:etName
	)
	
	rollout poweredMasspointRollout "Powered Mass Point"
	(
		editText etName "Name:"
		on etName changed t do name= t
	)
)

mpAttribs= attributes masspointAttributes
(
	parameters masspointParams rollout:masspointRollout
	(
		pmp			type:#string	ui:etPMP
		
		parentName	type:#string	ui:etParent
		
		metallic	type:#boolean	ui:cbMetallic
		
		relMass		type:#float		ui:spRelMass 
		mass		type:#float		ui:spMass 
		
		relDens		type:#float		ui:spRelDens 
		dens		type:#float		ui:spDens 
		
		frType		type:#string	ui:etFrType 
		frPara		type:#float		ui:spFrPara 
		frPerp		type:#float		ui:spFrPerp 
	)
	
	rollout masspointRollout "Mass Point"
	(
		label lbParent "Model Node:" align:#left
		editText etParent "" width:160 offset:[-12,0]
		
		label lbPMP "Powered Mass Point:" align:#left
		editText etPMP "" width:160 offset:[-12,0]
		
		checkBox cbMetallic "Metallic:"
		
		spinner spRelMass "Relative Mass:"
		spinner spMass "Mass:"
		
		spinner spRelDens "Relative Density:"
		spinner spDens "Density:"
		
		editText etFrType "Friction Type:"
		spinner spFrPara "Friction Para:"
		spinner spFrPerp "Friction Perp:"
	)
)

frictionTypes= #("point","forward","left","up")
fn createMpSphere mp modelNodes poweredMasspoints =
(
	c= green
	if undefined != findString mp.name "left" then c= blue
	if undefined != findString mp.name "right" then c= red
	
	sph= sphere	name:		("#"+mp.name)	\
				pos:		mp.position		\
				radius:		mp.radius		\
				wirecolor:	c
				
	custAttributes.add sph mpAttribs #unique
	
	pmpi= 1+ mp.poweredMasspoint
	if pmpi>0 then
		pmpName= poweredMasspoints[pmpi].name
	else
		pmpName= ""
	
	sph.pmp=		pmpName
	sph.metallic=	(mp.flags!=0)
	sph.relMass=	mp.relativeMass
	sph.mass=		mp.mass
	sph.relDens=	mp.relativeDensity
	sph.dens=		mp.density
	sph.frType=		frictionTypes[1+ mp.frictionType]
	sph.frPara=		mp.frictionPara
	sph.frPerp=		mp.frictionPerp
	
	vecRot sph	mp.forward	\
				mp.up
	
	sph.parentName= ""
	mpParent= modelNodes[1+ mp.modelNode]
	if mpParent != undefined then 
	(
		sph.parent= mpParent
		sph.parentName= mpParent.name
	)
	
	
	sph	--	collect it
)

fn ImportPhysics =
(
	mpArray= (for o in objects \
		where (((o.name[1] == "#") and (isKindOf o Sphere)) and \
			(not (o.isHidden or o.isFrozen))) collect o)
	
	if mpArray.count > 0 then
	(
		select mpArray
		max tool zoomextents
		msg=	"If these are markers and you don't want to delete them, \n\r"
		msg+=	"and you don't want to answer this question again, \n\r"
		msg+=	"you could hide your markers."
		ync= yesNoCancelBox msg title:"Delete selected objects?"
		if ync == #yes then		delete mpArray
		if ync == #cancel then	return Ok
	)
	
	modelNodes= for o in ($frame* as array) where isValidNode o collect o
	modelNodes= for o in modelNodes where not (o.isHidden or o.isFrozen ) \
														collect o
	modelNodes= haloSort modelNodes
	
	if (ifp= getPhyImportFilepath()) != undefined then
	(
		importFilepath= ifp
		
		if undefined != (phyTag= rPhysicsTag importFilepath) then
		(
			if phyTag.masspoints.count>0 then
			(
				mpArray= for mp in phyTag.masspoints collect \
					createMpSphere mp modelNodes phyTag.poweredMasspoints
				
			--	custAttributes.add mpArray pmpAttribs
				
				someUnparented= false
				for mp in mpArray do if mp.parent==undefined then
					someUnparented= true
				
				if someUnparented then	--	all unparented
				(
					for mp in mpArray do 
						mp.parent= undefined 
					
					format "Masspoints unparented. Not enough nodes or something\n"
				)
				
				select mpArray
				max tool zoomextents
				
			)--	if phyTag.masspoints.count>0
			
		)--	if undefined != (phyTag= rPhysicsTag importFilepath)
		
	)--	if (ifp= getPhyImportFilepath()) != undefined
	
)

ImportPhysics()
