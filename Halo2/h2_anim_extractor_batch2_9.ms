-- begin structure definitions

struct listItem_anim (id, name, extension, checked)
struct export_node (name, index, rotation, position, parentIndex, firstChildIndex, nextSiblingIndex)
struct tag (id, class, metaOffset, metaSize, path, metaIndex)
struct map (tags, primaryMagic, secondaryMagic, name, indexOffset, stringIDIndexOffset, stringIDTableOffset, indexSize, metaSize, fileTableOffset, primaryMagicConstant, objectIndexOffset, objectCount)
struct jmad_rawLocInfo (size, offset, location)
struct jmad_animRawAnimatedInfo (rot, rotKeys, trans, transKeys, scale, scaleKeys)
struct jmad_animRawAnimatedHeader (codec, codecOffset, rotNodeCount, transNodeCount, scaleNodeCount, animRate, rotInfoOffset, transInfoOffset, scaleInfoOffset, rotKeysOffset, transKeysOffset, scaleKeysOffset, unkOffset)
struct jmad_animRawStaticInfo (rot, trans, scale)
struct jmad_animRawStaticHeader (rotNodeCount, transNodeCount, scaleNodeCount, rotInfoOffset, transInfoOffset, scaleInfoOffset)
struct jmad_animRawFrameInfo (dx, dy, dz, dyaw)
struct jmad_animRaw (statRotFlags, statTransFlags, statScaleFlags, animRotFlags, animTransFlags, animScaleFlags, frameInfos, staticHeader, staticInfo, animatedHeader, animatedInfo)
struct jmad_anim (name, type, frameInfoType, frameCount, internalFlags, staticNodeFlags, animatedNodeFlags, movementNodes, compressedStaticNodeSize, compressedAnimatedNodeSize, rawLocInfoIndex, rawAnimOffset, rawAnimLocation, raw)
struct jmad_node (name, nextSiblingIndex, firstChildIndex, parentIndex)
struct jmad (nodes, anims, rawLocInfos)

-- end structure definitions
-- begin enumerated values

enumLocation = #("internal","mainmenu","shared","single_player_shared")
enumAnimationType = #("base","overlay","replacement")
enumFrameInfoType = #("none","dx,dy","dx,dy,dyaw","dx,dy,dz,dyaw")

-- end enumerated values

itemArray = #()
minState = false
lastPath = "C:\\"
lastScenePath = "C:\\"
nodeListChecksum = 0

mapPath = undefined
mapFile = undefined
sharedFile = undefined
spSharedFile = undefined
mainmenuFile = undefined
sharedCheck = false
spSharedCheck = false
mainmenuCheck = false
mapIndex = undefined
originScene = undefined
saveDir = undefined

rootSceneNode = undefined
nodeArrayExport = #()
nodeArray = #()


fn reverseString inString =
(
	local outString = ""
	for i = inString.count to 1 by -1 do
	(
		outString += inString[i]
	)
	outString
)

fn reverseArray inArray =
(
	local outArray = #()
	for i = inArray.count to 1 by -1 do
	(
		append outArray inArray[i]
	)
	outArray
)

fn reverseBinBytes inBin =
(
	local outBin = ""
	for i = 1 to inBin.count by 8 do (outBin += reverseString (substring inBin i 8))
	outBin
)

fn correctHex inHex =
(
	local outHex = ""
	if (inHex.count < 2) then (outHex = "0" + inHex)
	else (outHex = inHex)
	outHex
)

fn hexToBin inHex =
(
	local hexKey = #(#0,#1,#2,#3,#4,#5,#6,#7,#8,#9,#A,#B,#C,#D,#E,#F)
	local binKey = #("0000","0001","0010","0011","0100","0101","0110","0111","1000","1001","1010","1011","1100","1101","1110","1111")
	local outBin = ""
	for i = 1 to inHex.count do
	(
		index = (findItem hexKey (inHex[i] as name))
		outBin += binKey[index]
	)
	outBin
)

fn bitarrayToString inBitarray stringLength =
(
	local outString = ""
	for i = 1 to stringLength do
	(
		if inBitarray[i] then (outString += "1")
		else (outString += "0")
	)
	outString
)

fn binToBitarray inBin =
(
	local outBitarray = #{}
	for i = 1 to inBin.count do
	(
		if (inBin[i] == "1") then (outBitarray[i] = true)
		else (outBitarray[i] = false)
	)
	outBitarray
)

fn readShortL file strType =
(
	b1 = readByte file #unsigned
	b2 = readByte file #unsigned
	littleEndianShort = (b2 * 256) + b1
	if strType == "#signed" then
	(
		if littleEndianShort > 32768 then
		(
			(65536 - littleEndianShort) * -1
		)
		else
		(
			littleEndianShort
		)
	)
	else
	(
		littleEndianShort
	)
)

fn readLongL file strType =
(
	b1 = readByte file #unsigned
	b2 = readByte file #unsigned
	b3 = readByte file #unsigned
	b4 = readByte file #unsigned
	littleEndianLong = (b4 * 16777216) + (b3 * 65536) + (b2 * 256) + (b1 * 1)
	if strType == "#signed" then
	(
		if littleEndianLong as float > 2147483648 as float then
		(
			(4294967296 - littleEndianLong) * -1
		)
		else
		(
			littleEndianLong
		)
	)
	else
	(
		littleEndianLong
	)
)

fn readFloatL file =
(
	local myBitArray = #{}
	b4 = readByte file #unsigned
	b3 = readByte file #unsigned
	b2 = readByte file #unsigned
	b1 = readByte file #unsigned
	for i = 8 to 1 by -1 do
	(
		myBitArray[i] = (mod b1 2 > .5)
		b1 /= 2
	)
	for i = 16 to 9 by -1 do
	(
		myBitArray[i] = (mod b2 2 > .5)
		b2 /= 2
	)
	for i = 24 to 17 by -1 do
	(
		myBitArray[i] = (mod b3 2 > .5)
		b3 /= 2
	)
	for i = 32 to 25 by -1 do
	(
		myBitArray[i] = (mod b4 2 > .5)
		b4 /= 2
	)
	
	local exp = 0.0
	for i = 9 to 2 by -1 do
	(
		if myBitArray[i] == true then
		(
			exp += 2.0 ^ (9 - i)
		)
	)
	exp -= 127.0
	
	local myFloat = 2.0 ^ exp
	exp -= 1
	for i = 10 to 32 do
	(
		if myBitArray[i] == true then
		(
			myFloat += 2.0 ^ exp
		)
		exp -= 1
	)
	if myBitArray[1] == true then
	(
		-myFloat
	)
	else
	(
		myFloat
	)
)

fn readCharSet file charCount =
(
	local outString = ""
	for i = 1 to charCount do
	(
		outString += bit.intAsChar (readByte file #unsigned)
	)
	outString
)

fn parseFlagArray inNum =
(
	local outBitArray = #{}
	inBin = hexToBin (bit.intAsHex inNum)
	flagData = reverseBinBytes (substring inBin (inBin.count - 7) 8)
	for i = 1 to flagData.count do (outBitArray[i] = (flagData[i] == "1"))
	outBitArray
)

fn getStringByID stringID =
(
	local outString = ""
	currentPos = ftell mapFile
	fseek mapFile (mapIndex.stringIDIndexOffset + (stringID * 4)) #seek_set
	stringOffset = readLongL mapFile "#unsigned"
	fseek mapFile (mapIndex.stringIDTableOffset + stringOffset) #seek_set
	outString = readString mapFile
	fseek mapFile currentPos #seek_set
	outString
)

fn getRawLocationByOffset rawOffset =
(
	local outArray = #()
	outArray[1] = bit.and rawOffset 0x3FFFFFFF
	loc = bit.and rawOffset 0xC0000000
	case loc of
	(
		0x00000000 : (outArray[2] = 0) -- internal
		0x40000000 : (outArray[2] = 1) -- mainmenu
		0x80000000 : (outArray[2] = 2) -- shared
		0xC0000000 : (outArray[2] = 3) -- sp shared
	)
	outArray
)

fn getAnimExtension useAnim =
(
	case useAnim.type of
	(
		0 :
		(
			case useAnim.frameInfoType of
			(
				0 :
				(
					if (useAnim.internalFlags[2]) then ("JMW")
					else ("JMM")
				)
				1 : ("JMA")
				2 : ("JMT")
				3 : ("JMZ")
			)
		)
		1 : ("JMO")
		2 : ("JMR")
	)
)

fn deleteControllerKeys useController frameStart =
(
	index = 1
	complete = false
	while not complete do
	(
		try
		(
			if (useController.keys[index].time >= frameStart) then
			(
				deleteKey useController.keys index
				index = 1
			)
			else (index += 1)
			if (index > useController.keys.count) then (complete = true)
		)
		catch (complete = true)
	)
)

fn replaceSubstringInstances useString replaceFrom replaceTo =
(
	currentString = useString
	index = 1
	complete = false
	while not complete do
	(
		if (substring currentString index replaceFrom.count as name == replaceFrom as name) then
		(
			preString = substring currentString 1 (index - 1)
			postString = substring currentString (index + replaceFrom.count) -1
			currentString = preString + replaceTo + postString
			index = 1
		)
		else (index += 1)
		if (index > (currentString.count - replaceFrom.count + 1)) then (complete = true)
	)
	currentString
)

fn changeSaveNameToCE useName =
(
	currentName = useName
	currentName = replaceSubstringInstances currentName "combat:" "stand:"
	currentName = replaceSubstringInstances currentName "patrol:" "alert:"
	currentName = replaceSubstringInstances currentName ":aim_still_up" ":aim_still"
	currentName = replaceSubstringInstances currentName ":aim_move_up" ":aim_move"
	currentName = replaceSubstringInstances currentName ":melee_strike_1" ":melee%0"
	currentName = replaceSubstringInstances currentName ":melee_strike_2" ":melee%1"
	currentName = replaceSubstringInstances currentName ":melee_strike_3" ":melee%2"
	currentName = replaceSubstringInstances currentName ":var" "%"
	currentName = replaceSubstringInstances currentName ":support:" ":support_low:"
	currentName = replaceSubstringInstances currentName ":missile:" ":support_high:"
	currentName = replaceSubstringInstances currentName ":ds:" ":sb:"
	currentName = replaceSubstringInstances currentName ":csr:" ":bm:"
	currentName
)

fn validateSaveName useName =
(
	local outName = useName
	for i = 1 to outName.count where (outName[i] == ":") do (outName[i] = " ")
	for j = 1 to outName.count where (outName[j] == "_") do (outName[j] = "-")
	outName
)

fn getAvailableFilePath useDir useName useExt fixNames =
(
	local returnPath = ""
	if fixNames then (useNameFixed = validateSaveName (changeSaveNameToCE useName))
	else (useNameFixed = validateSaveName useName)
	if (not (doesFileExist (useDir + "\\" + useNameFixed + "." + useExt))) then (returnPath = (useDir + "\\" + useNameFixed + "." + useExt))
	else
	(
		suffix = 0
		while (doesFileExist (useDir + "\\" + useNameFixed + suffix as string + "." + useExt)) do (suffix += 1)
		returnPath = (useDir + "\\" + useNameFixed + suffix as string + "." + useExt)
	)
	returnPath
)


rollout h2AnimTool "Halo 2 Animation Tool - Zteam" width:600 height:550
(
	groupBox group_map "Map File: No map loaded" pos:[7,2] width:535 height:46
	button map_sel "Load" pos:[16,19] width:50 height:20
	button map_clr "Clear" pos:[72,19] width:50 height:20 enabled:false
	editText map_text "" pos:[125,19] width:408 height:20 enabled:false
	
	groupBox group_min "" pos:[550,2] width:43 height:46
	button minimize "Min" pos:[558,16] width:27 height:24
	
	groupBox group_tags "Animation Tags" pos:[7,50] width:586 height:174
	listBox tags_list "" pos:[15,66] width:350 height:11
	groupBox group_tagsDbg "Debug" pos:[373,60] width:212 height:156
	button tagsDbg_prntJmad "Print Jmad Tag Info" pos:[381,76] width:196 height:42 enabled:false
	checkBox tagsDbg_prntJmad_node "Node" pos:[382,125] width:45 height:14 enabled:false
	checkBox tagsDbg_prntJmad_anim "Animation" pos:[437,125] width:65 height:14 enabled:false
	checkBox tagsDbg_prntJmad_raw "Raw Loc." pos:[512,125] width:64 height:14 enabled:false
	groupBox group_tagsDbgStats "Statistics" pos:[381,144] width:121 height:64
	label tagsDbgStats_node "Node Blocks: " pos:[390,159] width:105 height:12
	label tagsDbgStats_anim "Anim. Blocks: " pos:[390,174] width:105 height:12
	label tagsDbgStats_raw "Raw Loc. Blocks: " pos:[390,189] width:105 height:12
	groupBox group_tagsDbgNodeList "Node List" pos:[509,144] width:68 height:64
	button tagsDbgNodeList_save "Save" pos:[517,160] width:52 height:18 enabled:false
	button tagsDbgNodeList_sync "Sync" pos:[517,183] width:52 height:18 enabled:false
	
	activeXControl tabStrip "MSComctlLib.TabStrip.2" pos:[7,224] width:586 height:20
	groupBox group_params "" pos:[7,238] width:586 height:297
	
	listBox imp_animList "" pos:[15,252] width:250 height:13 visible:false
	groupBox group_impDbg "Debug" pos:[273,246] width:166 height:182 visible:false
	button impDbg_prntAnim "Print Animation Info" pos:[281,262] width:150 height:35 enabled:false visible:false
	checkBox impDbg_prntAnim_head "Header" pos:[282,304] width:54 height:14 enabled:false visible:false
	checkBox impDbg_prntAnim_frm "Frame Info" pos:[361,304] width:69 height:14 enabled:false visible:false
	checkBox impDbg_prntAnim_stat "Stat. Info" pos:[282,322] width:62 height:14 enabled:false visible:false
	checkBox impDbg_prntAnim_anim "Anim. Info" pos:[361,322] width:66 height:14 enabled:false visible:false
	groupBox group_impDbgProps "Properties" pos:[281,341] width:150 height:79 visible:false
	label impDbgProps_type "Type: " pos:[290,356] width:132 height:13 visible:false
	label impDbgProps_frmType "Fr. Info Type: " pos:[290,371] width:132 height:13 visible:false
	label impDbgProps_frmCount "Fr. Count: " pos:[290,386] width:132 height:13 visible:false
	label impDbgProps_codec "Codec: " pos:[290,401] width:132 height:12 visible:false
	
	groupBox group_impNodeStates "Node States" pos:[446,246] width:139 height:70 visible:false
	button impNodeStates_save "Save Node States" pos:[454,262] width:123 height:20 enabled:false visible:false
	button impNodeStates_sync "Sync Node States" pos:[454,288] width:123 height:20 enabled:false visible:false
	groupBox group_impParams "Import Parameters" pos:[446,317] width:139 height:111 visible:false
	checkBox impParams_frmInfo "Import Frame Info" pos:[455,333] width:101 height:14 enabled:false visible:false
	checkBox impParams_copyZero "Copy Frame 0 to End" pos:[455,351] width:121 height:14 enabled:false visible:false
	label impParams_stFrm_lbl "Start on Frame:" pos:[454,371] width:73 height:13 enabled:false visible:false
	spinner impParams_stFrm "" pos:[530,369] width:47 height:16 range:[0,9999,0] type:#integer scale:1 enabled:false visible:false
	button imp_importAnim "Import Animation" pos:[454,390] width:123 height:30 enabled:false visible:false
	
	groupBox group_btc_locs "Locations" pos:[15,246] width:570 height:101 visible:false
	label btc_locs_orig_lbl "Origin MAX Scene:" pos:[24,262] width:90 height:13 visible:false
	button btc_locs_origSel "Load" pos:[24,278] width:50 height:20 visible:false
	button btc_locs_origClr "Clear" pos:[80,278] width:50 height:20 enabled:false visible:false
	editText btc_locs_origText "" pos:[133,278] width:443 height:20 enabled:false visible:false
	label btc_locs_save_lbl "Exported Files Directory:" pos:[24,302] width:114 height:13 visible:false
	button btc_locs_saveSel "Pick" pos:[24,318] width:50 height:20 visible:false
	button btc_locs_saveClr "Clear" pos:[80,318] width:50 height:20 enabled:false visible:false
	editText btc_locs_saveText "" pos:[133,318] width:443 height:20 enabled:false visible:false
	
	activeXControl btc_exportQueue "MSComctlLib.ListViewCtrl.2" pos:[15,355] width:400 height:172
	groupBox group_btc_exportCmds "" pos:[423,349] width:162 height:80 visible:false
	button btc_exportCmds_chkAll "+ All" pos:[431,363] width:30 height:20 visible:false
	button btc_exportCmds_uncAll "- All" pos:[469,363] width:30 height:20 visible:false
	button btc_exportCmds_chkSel "+ Sel" pos:[508,363] width:30 height:20 visible:false
	button btc_exportCmds_uncSel "- Sel" pos:[547,363] width:30 height:20 visible:false
	label btc_exportCmds_filterText_lbl "Filter List by String:" pos:[431,386] width:89 height:13 visible:false
	editText btc_exportCmds_filterText "" pos:[427,401] width:150 height:20 visible:false
	
	groupBox group_btc_export "Export Parameters" pos:[423,431] width:162 height:96 visible:false
	checkBox btc_export_saveMax "Save MAX Scenes" pos:[432,448] width:109 height:14 checked:true visible:false
	checkBox btc_export_saveBtz "Save Blitzkrieg Exports" pos:[432,466] width:127 height:14 checked:true visible:false
	button btc_exportAnims "Export Animations" pos:[431,488] width:146 height:30 enabled:false visible:false
	
	fn minimizeToggle =
	(
		if minState then
		(
			h2AnimTool.width = 600
			if (tabStrip.selectedItem.index == 1) then (h2AnimTool.height = 451)
			else (h2AnimTool.height = 550)
			group_map.visible = true
			map_sel.visible = true
			map_clr.visible = true
			minimize.pos = [558,16]
			minimize.caption = "Min"
		)
		else
		(
			h2AnimTool.width = 41
			h2AnimTool.height = 38
			group_map.visible = false
			map_sel.visible = false
			map_clr.visible = false
			minimize.pos = [7,7]
			minimize.caption = "Max"
		)
		minState = not minState
	)
	
	fn changeParamList =
	(
		defaultState = (tabStrip.selectedItem.index == 1)
		
		if defaultState then
		(
			h2AnimTool.height = 451
			group_params.height = 198
			btc_exportQueue.pos = [999,999]
		)
		else
		(
			h2AnimTool.height = 550
			group_params.height = 297
			btc_exportQueue.pos = [15,355]
		)

		imp_animList.visible = defaultState
		group_impDbg.visible = defaultState
		impDbg_prntAnim.visible = defaultState
		impDbg_prntAnim_head.visible = defaultState
		impDbg_prntAnim_frm.visible = defaultState
		impDbg_prntAnim_stat.visible = defaultState
		impDbg_prntAnim_anim.visible = defaultState
		group_impDbgProps.visible = defaultState
		impDbgProps_type.visible = defaultState
		impDbgProps_frmType.visible = defaultState
		impDbgProps_frmCount.visible = defaultState
		impDbgProps_codec.visible = defaultState
		group_impNodeStates.visible = defaultState
		group_impParams.visible = defaultState
		impNodeStates_save.visible = defaultState
		impNodeStates_sync.visible = defaultState
		impParams_frmInfo.visible = defaultState
		impParams_copyZero.visible = defaultState
		impParams_stFrm_lbl.visible = defaultState
		impParams_stFrm.visible = defaultState
		imp_importAnim.visible = defaultState

		group_btc_locs.visible = not defaultState
		btc_locs_orig_lbl.visible = not defaultState
		btc_locs_origSel.visible = not defaultState
		btc_locs_origClr.visible = not defaultState
		btc_locs_origText.visible = not defaultState
		btc_locs_save_lbl.visible = not defaultState
		btc_locs_saveSel.visible = not defaultState
		btc_locs_saveClr.visible = not defaultState
		btc_locs_saveText.visible = not defaultState
		group_btc_exportCmds.visible = not defaultState
		btc_exportCmds_chkAll.visible = not defaultState
		btc_exportCmds_uncAll.visible = not defaultState
		btc_exportCmds_chkSel.visible = not defaultState
		btc_exportCmds_uncSel.visible = not defaultState
		btc_exportCmds_filterText_lbl.visible = not defaultState
		btc_exportCmds_filterText.visible = not defaultState
		btc_exportCmds_filterText.enabled = not defaultState
		group_btc_export.visible = not defaultState
		btc_export_saveMax.visible = not defaultState
		btc_export_saveBtz.visible = not defaultState
		btc_exportAnims.visible = not defaultState
	)
	
	fn populateTagList =
	(
		temp_tagList = for i in mapIndex.tags where (i.class as name == "jmad" as name) collect i.path
		sort temp_tagList
		tags_list.items = temp_tagList
	)
	fn clearTagList = (tags_list.items = #())
	
	fn populateAnimList useTag =
	(
		imp_animList.items = for i in useTag.metaIndex.anims collect i.name
		imp_animList.selection = 1
	)
	fn clearAnimList = (imp_animList.items = #())
	
	fn getSelectedTag =
	(
		getTagArray = for i = 1 to mapIndex.tags.count where ((mapIndex.tags[i].class as name == "jmad" as name) and (tags_list.selected as name == mapIndex.tags[i].path as name)) collect mapIndex.tags[i]
		getTagArray[1]
	)
	
	fn adjustExportItem item =
	(
		itemArray[item.tag].checked = item.checked
		--found = true
		--for i = 1 to itemArray.count where (item.text as name == itemArray[i].name as name) while not found do
		--(
		--	itemArray[i].checked = item.checked
		--	found = true
		--)
	)
	
	fn adjustExportQueue =
	(
		checkedCount = 0
		if (itemArray.count != 0) then
		(
			if (btc_exportQueue.listItems.count > 8) then (btc_exportQueue.columnHeaders[1].width = 9125)
			else (btc_exportQueue.columnHeaders[1].width = 9550)
			for i in itemArray where i.checked do (checkedCount += 1)
			if (checkedCount > 1) then (btc_exportAnims.caption = "Export Animations")
			else (btc_exportAnims.caption = "Export Animation")
			queueHeader = stringStream ""
			format "Queue (%/%) - Displaying % " checkedCount itemArray.count btc_exportQueue.listItems.count to:queueHeader
			if (btc_exportQueue.listItems.count == 1) then (format "Item" to:queueHeader)
			else (format "Items" to:queueHeader)
			btc_exportQueue.columnHeaders[1].text = queueHeader as string
		)
		else (btc_exportQueue.columnHeaders[1].text = "Queue")
		saveEnabled = (saveDir != undefined)
		btc_export_saveMax.enabled = saveEnabled
		btc_export_saveMax.checked = saveEnabled
		btc_export_saveBtz.enabled = saveEnabled
		btc_export_saveBtz.checked = saveEnabled
		if ((checkedCount < 1) or (originScene == undefined) or (saveDir == undefined)) then (btc_exportAnims.enabled = false)
		else (btc_exportAnims.enabled = true)
	)
	
	fn setCheckedByExtension extension checkedState =
	(
		for i in btc_exportQueue.listItems where (i.listSubItems[1].text as name == extension as name) do
		(
			i.checked = checkedState
			adjustExportItem i
		)
		adjustExportQueue ()
	)
	
	fn populateExportQueue =
	(
		btc_exportQueue.checkboxes = true
		btc_exportQueue.fullRowSelect = true
		btc_exportQueue.gridLines = true
		btc_exportQueue.multiSelect = true
		btc_exportQueue.appearance = #ccFlat
		btc_exportQueue.view = #lvwReport
		btc_exportQueue.labelEdit = #lvwManual
		btc_exportQueue.columnHeaders.add ()
		btc_exportQueue.columnHeaders[1].text = "Queue"
		btc_exportQueue.columnHeaders[1].width = 9550
		btc_exportQueue.columnHeaders.add ()
		btc_exportQueue.columnHeaders[2].text = "Type"
		btc_exportQueue.columnHeaders[2].width = 1000
	)
	
	fn clearExportQueue =
	(
		itemArray = #()
		btc_exportQueue.listItems.clear ()
		adjustExportQueue ()
	)
	
	fn populateExportQueueItems =
	(
		btc_exportQueue.listItems.clear ()
		for i = 1 to itemArray.count do
		(
			if (btc_exportCmds_filterText.text != "") then
			(
				if (btc_exportCmds_filterText.text as name == (substring itemArray[i].name 1 btc_exportCmds_filterText.text.count as name)) then
				(
					btc_exportQueue.listItems.add ()
					addedItem = btc_exportQueue.listItems[btc_exportQueue.listItems.count]
					addedItem.tag = itemArray[i].id
					addedItem.text = itemArray[i].name
					addedItem.checked = itemArray[i].checked
					addedItem.listSubItems.add ()
					addedItem.listSubItems[1].text = itemArray[i].extension
				)
			)
			else
			(
				btc_exportQueue.listItems.add ()
				addedItem = btc_exportQueue.listItems[btc_exportQueue.listItems.count]
				addedItem.tag = itemArray[i].id
				addedItem.text = itemArray[i].name
				addedItem.checked = itemArray[i].checked
				addedItem.listSubItems.add ()
				addedItem.listSubItems[1].text = itemArray[i].extension
			)
		)
		adjustExportQueue ()
	)
	
	fn mapExportQueueItems useTag =
	(
		for i = 1 to useTag.metaIndex.anims.count do
		(
			useAnim = useTag.metaIndex.anims[i]
			itemArray[i] = listItem_anim ()
			itemArray[i].id = i
			itemArray[i].name = useAnim.name
			itemArray[i].extension = getAnimExtension useAnim
			itemArray[i].checked = true
		)
		populateExportQueueItems ()
	)
	
	fn clrOrigScn =
	(
		btc_locs_origClr.enabled = false
		btc_locs_origText.text = ""
		originScene = undefined
		
		adjustExportQueue ()
	)
	
	fn selOrigScn =
	(
		try
		(
			clrOrigScn ()
			originScene = getOpenFileName	caption:"Select Origin MAX Scene" \
											filename:lastScenePath \
											types:"MAX Scene (*.MAX)|*.MAX|"
			if (originScene != undefined) then
			(
				lastScenePath = getFilenamePath originScene
				
				btc_locs_origClr.enabled = true
				btc_locs_origText.text = originScene
			)
		)
		catch (clrOrigScn ())
		
		adjustExportQueue ()
	)
	
	fn clrSaveDir =
	(
		btc_locs_saveClr.enabled = false
		btc_locs_saveText.text = ""
		saveDir = undefined
		
		adjustExportQueue ()
	)
	
	fn selSaveDir =
	(
		try
		(
			clrSaveDir ()
			saveDir = getSavePath caption:"Select Save Directory"
			if (saveDir != undefined) then
			(
				btc_locs_saveClr.enabled = true
				btc_locs_saveText.text = saveDir
			)
		)
		catch (clrSaveDir ())
		
		adjustExportQueue ()
	)
	
	fn indexAnimRaw useAnim =
	(
		case useAnim.rawAnimLocation of
		(
			0 : useMap = mapFile
			1 : useMap = mainmenuFile
			2 : useMap = sharedFile
			3 : useMap = spSharedFile
		)
		rawIndex = jmad_animRaw ()
		fseek useMap useAnim.rawAnimOffset #seek_set
		fseek useMap (useAnim.compressedStaticNodeSize + useAnim.compressedAnimatedNodeSize) #seek_cur
		if (useAnim.staticNodeFlags != 0) then
		(
			staticDataSize = useAnim.staticNodeFlags/3
			staticRotationFlagsStr = ""
			for i = 1 to staticDataSize do (staticRotationFlagsStr += correctHex (bit.intAsHex (readByte useMap #unsigned)))
			rawIndex.statRotFlags = binToBitarray (reverseBinBytes (hexToBin staticRotationFlagsStr))
			staticTranslationFlagsStr = ""
			for j = 1 to staticDataSize do (staticTranslationFlagsStr += correctHex (bit.intAsHex (readByte useMap #unsigned)))
			rawIndex.statTransFlags = binToBitarray (reverseBinBytes (hexToBin staticTranslationFlagsStr))
			staticScaleFlagsStr = ""
			for k = 1 to staticDataSize do (staticScaleFlagsStr += correctHex (bit.intAsHex (readByte useMap #unsigned)))
			rawIndex.statScaleFlags = binToBitarray (reverseBinBytes (hexToBin staticScaleFlagsStr))
		)
		else
		(
			rawIndex.statRotFlags = #{}
			rawIndex.statTransFlags = #{}
			rawIndex.statScaleFlags = #{}
		)
		if (useAnim.animatedNodeFlags != 0) then
		(
			animatedDataSize = useAnim.animatedNodeFlags/3
			animatedRotationFlagsStr = ""
			for i = 1 to animatedDataSize do (animatedRotationFlagsStr += correctHex (bit.intAsHex (readByte useMap #unsigned)))
			rawIndex.animRotFlags = binToBitarray (reverseBinBytes (hexToBin animatedRotationFlagsStr))
			animatedTranslationFlagsStr = ""
			for j = 1 to animatedDataSize do (animatedTranslationFlagsStr += correctHex (bit.intAsHex (readByte useMap #unsigned)))
			rawIndex.animTransFlags = binToBitarray (reverseBinBytes (hexToBin animatedTranslationFlagsStr))
			animatedScaleFlagsStr = ""
			for k = 1 to animatedDataSize do (animatedScaleFlagsStr += correctHex (bit.intAsHex (readByte useMap #unsigned)))
			rawIndex.animScaleFlags = binToBitarray (reverseBinBytes (hexToBin animatedScaleFlagsStr))
		)
		else
		(
			rawIndex.animRotFlags = #{}
			rawIndex.animTransFlags = #{}
			rawIndex.animScaleFlags = #{}
		)
		if (useAnim.frameInfoType > 0) then
		(
			rawIndex.frameInfos = #()
			for i = 1 to useAnim.frameCount do
			(
				temp_frameInfo = jmad_animRawFrameInfo ()
				temp_frameInfo.dx = (readFloatL useMap) * 100.0
				temp_frameInfo.dy = (readFloatL useMap) * 100.0
				if (useAnim.frameInfoType == 2) then (temp_frameInfo.dyaw = radToDeg (readFloatL useMap))
				else
				(
					if (useAnim.frameInfoType == 3) then
					(
						temp_frameInfo.dz = (readFloatL useMap) * 100.0
						temp_frameInfo.dyaw = radToDeg (readFloatL useMap)
					)
				)
				rawIndex.frameInfos[i] = temp_frameInfo
			)
		)
		if (useAnim.staticNodeFlags != 0) then
		(
			temp_staticHeader = jmad_animRawStaticHeader ()
			fseek useMap useAnim.rawAnimOffset #seek_set
			fseek useMap 1 #seek_cur
			temp_staticHeader.rotNodeCount = readByte useMap #unsigned
			temp_staticHeader.transNodeCount = readByte useMap #unsigned
			temp_staticHeader.scaleNodeCount = readByte useMap #unsigned
			fseek useMap 8 #seek_cur
			if (temp_staticHeader.transNodeCount > 0) then (temp_staticHeader.transInfoOffset = readLongL useMap "#unsigned")
			else (fseek useMap 4 #seek_cur)
			if (temp_staticHeader.scaleNodeCount > 0) then (temp_staticHeader.scaleInfoOffset = readLongL useMap "#unsigned")
			else (fseek useMap 4 #seek_cur)
			fseek useMap 12 #seek_cur
			rawIndex.staticHeader = temp_staticHeader
			
			temp_staticInfo = jmad_animRawStaticInfo ()
			temp_staticInfo.rot = #()
			for i = 1 to temp_staticHeader.rotNodeCount do
			(
				temp_rotI = (readShortL useMap "#signed")/32767.0
				temp_rotJ = (readShortL useMap "#signed")/32767.0
				temp_rotK = (readShortL useMap "#signed")/32767.0
				temp_rotW = (readShortL useMap "#signed")/32767.0
				temp_rot = normalize (quat temp_rotI temp_rotJ temp_rotK temp_rotW)
				temp_staticInfo.rot[i] = temp_rot
			)
			temp_staticInfo.trans = #()
			for j = 1 to temp_staticHeader.transNodeCount do
			(
				temp_transX = (readFloatL useMap) * 100.0
				temp_transY = (readFloatL useMap) * 100.0
				temp_transZ = (readFloatL useMap) * 100.0
				temp_trans = [temp_transX,temp_transY,temp_transZ]
				temp_staticInfo.trans[j] = temp_trans
			)
			temp_staticInfo.scale = #()
			for k = 1 to temp_staticHeader.scaleNodeCount do
			(
				temp_scaleComponent = readFloatL useMap
				temp_scale = [temp_scaleComponent,temp_scaleComponent,temp_scaleComponent]
				temp_staticInfo.scale[k] = temp_scale
			)
			rawIndex.staticInfo = temp_staticInfo
		)
		if (useAnim.animatedNodeFlags != 0) then
		(
			temp_animatedHeader = jmad_animRawAnimatedHeader ()
			fseek useMap (useAnim.rawAnimOffset + useAnim.compressedStaticNodeSize) #seek_set
			temp_animatedHeader.codecOffset = ftell useMap
			temp_animatedHeader.codec = readByte useMap #unsigned
			temp_animatedHeader.rotNodeCount = readByte useMap #unsigned
			temp_animatedHeader.transNodeCount = readByte useMap #unsigned
			temp_animatedHeader.scaleNodeCount = readByte useMap #unsigned
			fseek useMap 4 #seek_cur
			temp_animatedHeader.animRate = readFloatL useMap
			codec = temp_animatedHeader.codec
			if ((codec == 3) or (codec == 8)) then
			(
				if (temp_animatedHeader.transNodeCount > 0) then (temp_animatedHeader.transInfoOffset = readLongL useMap "#unsigned")
				else (fseek useMap 4 #seek_cur)
				if (temp_animatedHeader.scaleNodeCount > 0) then (temp_animatedHeader.scaleInfoOffset = readLongL useMap "#unsigned")
				else (fseek useMap 4 #seek_cur)
				fseek useMap 12 #seek_cur
				
				temp_animatedInfo = jmad_animRawAnimatedInfo ()
				temp_animatedInfo.rot = #()
				for n = 1 to temp_animatedHeader.rotNodeCount do
				(
					temp_nodeRot = #()
					for f = 1 to useAnim.frameCount do
					(
						if (codec == 3) then
						(
							temp_rotI = (readShortL useMap "#signed")/32767.0
							temp_rotJ = (readShortL useMap "#signed")/32767.0
							temp_rotK = (readShortL useMap "#signed")/32767.0
							temp_rotW = (readShortL useMap "#signed")/32767.0
						)
						else
						(
							temp_rotI = readFloatL useMap
							temp_rotJ = readFloatL useMap
							temp_rotK = readFloatL useMap
							temp_rotW = readFloatL useMap
						)
						temp_rot = normalize (quat temp_rotI temp_rotJ temp_rotK temp_rotW)
						temp_nodeRot[f] = temp_rot
					)
					temp_animatedInfo.rot[n] = temp_nodeRot
				)
				temp_animatedInfo.trans = #()
				for n = 1 to temp_animatedHeader.transNodeCount do
				(
					temp_nodeTrans = #()
					for f = 1 to useAnim.frameCount do
					(
						temp_transX = (readFloatL useMap) * 100.0
						temp_transY = (readFloatL useMap) * 100.0
						temp_transZ = (readFloatL useMap) * 100.0
						temp_trans = [temp_transX,temp_transY,temp_transZ]
						temp_nodeTrans[f] = temp_trans
					)
					temp_animatedInfo.trans[n] = temp_nodeTrans
				)
				temp_animatedInfo.scale = #()
				for n = 1 to temp_animatedHeader.scaleNodeCount do
				(
					temp_nodeScale = #()
					for f = 1 to useAnim.frameCount do
					(
						temp_scaleComponent = readFloatL useMap
						temp_scale = [temp_scaleComponent,temp_scaleComponent,temp_scaleComponent]
						temp_nodeScale[f] = temp_scale
					)
					temp_animatedInfo.scale[n] = temp_nodeScale
				)
				rawIndex.animatedInfo = temp_animatedInfo
			)
			if ((codec == 4) or (codec == 5) or (codec == 6) or (codec == 7)) then
			(
				case of
				(
					((temp_animatedHeader.rotNodeCount > 0) and (temp_animatedHeader.transNodeCount > 0) and (temp_animatedHeader.scaleNodeCount > 0)) :
					(
						fseek useMap 8 #seek_cur
						temp_animatedHeader.rotKeysOffset = readLongL useMap "#unsigned"
						temp_animatedHeader.transKeysOffset = readLongL useMap "#unsigned"
						temp_animatedHeader.scaleKeysOffset = readLongL useMap "#unsigned"
						temp_animatedHeader.rotInfoOffset = readLongL useMap "#unsigned"
						temp_animatedHeader.transInfoOffset = readLongL useMap "#unsigned"
						temp_animatedHeader.scaleInfoOffset = readLongL useMap "#unsigned"
						fseek useMap 4 #seek_cur
						
						temp_animatedInfo = jmad_animRawAnimatedInfo ()
						fseek useMap (temp_animatedHeader.codecOffset + temp_animatedHeader.rotKeysOffset) #seek_set
						temp_animatedInfo.rotKeys = #()
						for i = 1 to temp_animatedHeader.rotNodeCount do (temp_animatedInfo.rotKeys[i] = #())
						index1 = 1
						complete1 = false
						while not complete1 do
						(
							index2 = 1
							complete2 = false
							key = 0
							previousValue = 0
							while not complete2 do
							(
								if ((codec == 5) or (codec == 7)) then (key = readShortL useMap "#unsigned")
								else (key = readByte useMap #unsigned)
								if ((previousValue > key) or (key > (useAnim.frameCount - 1))) then
								(
									if ((codec == 5) or (codec == 7)) then (fseek useMap -2 #seek_cur)
									else (fseek useMap -1 #seek_cur)
									complete2 = true
								)
								else
								(
									previousValue = key
									temp_animatedInfo.rotKeys[index1][index2] = key
									index2 += 1
								)
							)
							if (index1 == temp_animatedHeader.rotNodeCount) then (complete1 = true)
							else (index1 += 1)
							if ((ftell useMap) == (temp_animatedHeader.codecOffset + temp_animatedHeader.transKeysOffset)) then (complete1 = true)
						)
						fseek useMap (temp_animatedHeader.codecOffset + temp_animatedHeader.transKeysOffset) #seek_set
						temp_animatedInfo.transKeys = #()
						for i = 1 to temp_animatedHeader.transNodeCount do (temp_animatedInfo.transKeys[i] = #())
						index1 = 1
						complete1 = false
						while not complete1 do
						(
							index2 = 1
							complete2 = false
							key = 0
							previousValue = 0
							while not complete2 do
							(
								if ((codec == 5) or (codec == 7)) then (key = readShortL useMap "#unsigned")
								else (key = readByte useMap #unsigned)
								if ((previousValue > key) or (key > (useAnim.frameCount - 1))) then
								(
									if ((codec == 5) or (codec == 7)) then (fseek useMap -2 #seek_cur)
									else (fseek useMap -1 #seek_cur)
									complete2 = true
								)
								else
								(
									previousValue = key
									temp_animatedInfo.transKeys[index1][index2] = key
									index2 += 1
								)
							)
							if (index1 == temp_animatedHeader.transNodeCount) then (complete1 = true)
							else (index1 += 1)
							if ((ftell useMap) == (temp_animatedHeader.codecOffset + temp_animatedHeader.scaleKeysOffset)) then (complete1 = true)
						)
						fseek useMap (temp_animatedHeader.codecOffset + temp_animatedHeader.scaleKeysOffset) #seek_set
						temp_animatedInfo.scaleKeys = #()
						for i = 1 to temp_animatedHeader.scaleNodeCount do (temp_animatedInfo.scaleKeys[i] = #())
						index1 = 1
						complete1 = false
						while not complete1 do
						(
							index2 = 1
							complete2 = false
							key = 0
							previousValue = 0
							while not complete2 do
							(
								if ((codec == 5) or (codec == 7)) then (key = readShortL useMap "#unsigned")
								else (key = readByte useMap #unsigned)
								if ((previousValue > key) or (key > (useAnim.frameCount - 1))) then
								(
									if ((codec == 5) or (codec == 7)) then (fseek useMap -2 #seek_cur)
									else (fseek useMap -1 #seek_cur)
									complete2 = true
								)
								else
								(
									previousValue = key
									temp_animatedInfo.scaleKeys[index1][index2] = key
									index2 += 1
								)
							)
							if (index1 == temp_animatedHeader.scaleNodeCount) then (complete1 = true)
							else (index1 += 1)
							if ((ftell useMap) == (temp_animatedHeader.codecOffset + temp_animatedHeader.rotInfoOffset)) then (complete1 = true)
						)
						fseek useMap (temp_animatedHeader.codecOffset + temp_animatedHeader.rotInfoOffset) #seek_set
						temp_animatedInfo.rot = #()
						for n = 1 to temp_animatedHeader.rotNodeCount do
						(
							temp_nodeRot = #()
							for f = 1 to temp_animatedInfo.rotKeys[n].count do
							(
								temp_rotI = (readShortL useMap "#signed")/32767.0
								temp_rotJ = (readShortL useMap "#signed")/32767.0
								temp_rotK = (readShortL useMap "#signed")/32767.0
								temp_rotW = (readShortL useMap "#signed")/32767.0
								temp_rot = normalize (quat temp_rotI temp_rotJ temp_rotK temp_rotW)
								temp_nodeRot[f] = temp_rot
							)
							temp_animatedInfo.rot[n] = temp_nodeRot
						)
						if ((codec == 6) or (codec == 7)) then
						(
							temp_animatedInfo.rotKeys = reverseArray temp_animatedInfo.rotKeys
							temp_animatedInfo.rot = reverseArray temp_animatedInfo.rot
						)
						temp_animatedInfo.trans = #()
						for n = 1 to temp_animatedHeader.transNodeCount do
						(
							temp_nodeTrans = #()
							for f = 1 to temp_animatedInfo.transKeys[n].count do
							(
								temp_transX = (readFloatL useMap) * 100.0
								temp_transY = (readFloatL useMap) * 100.0
								temp_transZ = (readFloatL useMap) * 100.0
								temp_trans = [temp_transX,temp_transY,temp_transZ]
								temp_nodeTrans[f] = temp_trans
							)
							temp_animatedInfo.trans[n] = temp_nodeTrans
						)
						if ((codec == 6) or (codec == 7)) then
						(
							temp_animatedInfo.transKeys = reverseArray temp_animatedInfo.transKeys
							temp_animatedInfo.trans = reverseArray temp_animatedInfo.trans
						)
						temp_animatedInfo.scale = #()
						for n = 1 to temp_animatedHeader.scaleNodeCount do
						(
							temp_nodeScale = #()
							for f = 1 to temp_animatedInfo.scaleKeys[n].count do
							(
								temp_scaleComponent = readFloatL useMap
								temp_scale = [temp_scaleComponent,temp_scaleComponent,temp_scaleComponent]
								temp_nodeScale[f] = temp_scale
							)
							temp_animatedInfo.scale[n] = temp_nodeScale
						)
						if ((codec == 6) or (codec == 7)) then
						(
							temp_animatedInfo.scaleKeys = reverseArray temp_animatedInfo.scaleKeys
							temp_animatedInfo.scale = reverseArray temp_animatedInfo.scale
						)
						rawIndex.animatedInfo = temp_animatedInfo
					)
					((temp_animatedHeader.rotNodeCount > 0) and (temp_animatedHeader.transNodeCount > 0) and (temp_animatedHeader.scaleNodeCount == 0)) :
					(
						fseek useMap 4 #seek_cur
						temp_animatedHeader.rotKeysOffset = readLongL useMap "#unsigned"
						fseek useMap 4 #seek_cur
						temp_animatedHeader.transKeysOffset = readLongL useMap "#unsigned"
						temp_animatedHeader.unkOffset = readLongL useMap "#unsigned"
						temp_animatedHeader.rotInfoOffset = readLongL useMap "#unsigned"
						temp_animatedHeader.transInfoOffset = readLongL useMap "#unsigned"
						fseek useMap 8 #seek_cur
						
						temp_animatedInfo = jmad_animRawAnimatedInfo ()
						fseek useMap (temp_animatedHeader.codecOffset + temp_animatedHeader.rotKeysOffset) #seek_set
						temp_animatedInfo.rotKeys = #()
						for i = 1 to temp_animatedHeader.rotNodeCount do (temp_animatedInfo.rotKeys[i] = #())
						index1 = 1
						complete1 = false
						while not complete1 do
						(
							index2 = 1
							complete2 = false
							key = 0
							previousValue = 0
							while not complete2 do
							(
								if ((codec == 5) or (codec == 7)) then (key = readShortL useMap "#unsigned")
								else (key = readByte useMap #unsigned)
								if ((previousValue > key) or (key > (useAnim.frameCount - 1))) then
								(
									if ((codec == 5) or (codec == 7)) then (fseek useMap -2 #seek_cur)
									else (fseek useMap -1 #seek_cur)
									complete2 = true
								)
								else
								(
									previousValue = key
									temp_animatedInfo.rotKeys[index1][index2] = key
									index2 += 1
								)
							)
							if (index1 == temp_animatedHeader.rotNodeCount) then (complete1 = true)
							else (index1 += 1)
							if ((ftell useMap) == (temp_animatedHeader.codecOffset + temp_animatedHeader.transKeysOffset)) then (complete1 = true)
						)
						fseek useMap (temp_animatedHeader.codecOffset + temp_animatedHeader.transKeysOffset) #seek_set
						temp_animatedInfo.transKeys = #()
						for i = 1 to temp_animatedHeader.transNodeCount do (temp_animatedInfo.transKeys[i] = #())
						index1 = 1
						complete1 = false
						while not complete1 do
						(
							index2 = 1
							complete2 = false
							key = 0
							previousValue = 0
							while not complete2 do
							(
								if ((codec == 5) or (codec == 7)) then (key = readShortL useMap "#unsigned")
								else (key = readByte useMap #unsigned)
								if ((previousValue > key) or (key > (useAnim.frameCount - 1))) then
								(
									if ((codec == 5) or (codec == 7)) then (fseek useMap -2 #seek_cur)
									else (fseek useMap -1 #seek_cur)
									complete2 = true
								)
								else
								(
									previousValue = key
									temp_animatedInfo.transKeys[index1][index2] = key
									index2 += 1
								)
							)
							if (index1 == temp_animatedHeader.transNodeCount) then (complete1 = true)
							else (index1 += 1)
							if ((ftell useMap) == (temp_animatedHeader.codecOffset + temp_animatedHeader.unkOffset)) then (complete1 = true)
						)
						temp_animatedInfo.scaleKeys = #()
						fseek useMap (temp_animatedHeader.codecOffset + temp_animatedHeader.rotInfoOffset) #seek_set
						temp_animatedInfo.rot = #()
						for n = 1 to temp_animatedHeader.rotNodeCount do
						(
							temp_nodeRot = #()
							for f = 1 to temp_animatedInfo.rotKeys[n].count do
							(
								temp_rotI = (readShortL useMap "#signed")/32767.0
								temp_rotJ = (readShortL useMap "#signed")/32767.0
								temp_rotK = (readShortL useMap "#signed")/32767.0
								temp_rotW = (readShortL useMap "#signed")/32767.0
								temp_rot = normalize (quat temp_rotI temp_rotJ temp_rotK temp_rotW)
								temp_nodeRot[f] = temp_rot
							)
							temp_animatedInfo.rot[n] = temp_nodeRot
						)
						if ((codec == 6) or (codec == 7)) then
						(
							temp_animatedInfo.rotKeys = reverseArray temp_animatedInfo.rotKeys
							temp_animatedInfo.rot = reverseArray temp_animatedInfo.rot
						)
						temp_animatedInfo.trans = #()
						for n = 1 to temp_animatedHeader.transNodeCount do
						(
							temp_nodeTrans = #()
							for f = 1 to temp_animatedInfo.transKeys[n].count do
							(
								temp_transX = (readFloatL useMap) * 100.0
								temp_transY = (readFloatL useMap) * 100.0
								temp_transZ = (readFloatL useMap) * 100.0
								temp_trans = [temp_transX,temp_transY,temp_transZ]
								temp_nodeTrans[f] = temp_trans
							)
							temp_animatedInfo.trans[n] = temp_nodeTrans
						)
						if ((codec == 6) or (codec == 7)) then
						(
							temp_animatedInfo.transKeys = reverseArray temp_animatedInfo.transKeys
							temp_animatedInfo.trans = reverseArray temp_animatedInfo.trans
						)
						temp_animatedInfo.scale = #()
						rawIndex.animatedInfo = temp_animatedInfo
					)
					((temp_animatedHeader.rotNodeCount == 0) and (temp_animatedHeader.transNodeCount > 0) and (temp_animatedHeader.scaleNodeCount > 0)) :
					(
						fseek useMap 8 #seek_cur
						temp_animatedHeader.transKeysOffset = readLongL useMap "#unsigned"
						fseek useMap 4 #seek_cur
						temp_animatedHeader.scaleKeysOffset = readLongL useMap "#unsigned"
						temp_animatedHeader.transInfoOffset = readLongL useMap "#unsigned"
						fseek useMap 4 #seek_cur
						temp_animatedHeader.scaleInfoOffset = readLongL useMap "#unsigned"
						fseek useMap 4 #seek_cur
						
						temp_animatedInfo = jmad_animRawAnimatedInfo ()
						temp_animatedInfo.rotKeys = #()
						fseek useMap (temp_animatedHeader.codecOffset + temp_animatedHeader.transKeysOffset) #seek_set
						temp_animatedInfo.transKeys = #()
						for i = 1 to temp_animatedHeader.transNodeCount do (temp_animatedInfo.transKeys[i] = #())
						index1 = 1
						complete1 = false
						while not complete1 do
						(
							index2 = 1
							complete2 = false
							key = 0
							previousValue = 0
							while not complete2 do
							(
								if ((codec == 5) or (codec == 7)) then (key = readShortL useMap "#unsigned")
								else (key = readByte useMap #unsigned)
								if ((previousValue > key) or (key > (useAnim.frameCount - 1))) then
								(
									if ((codec == 5) or (codec == 7)) then (fseek useMap -2 #seek_cur)
									else (fseek useMap -1 #seek_cur)
									complete2 = true
								)
								else
								(
									previousValue = key
									temp_animatedInfo.transKeys[index1][index2] = key
									index2 += 1
								)
							)
							if (index1 == temp_animatedHeader.transNodeCount) then (complete1 = true)
							else (index1 += 1)
							if ((ftell useMap) == (temp_animatedHeader.codecOffset + temp_animatedHeader.scaleKeysOffset)) then (complete1 = true)
						)
						fseek useMap (temp_animatedHeader.codecOffset + temp_animatedHeader.scaleKeysOffset) #seek_set
						temp_animatedInfo.scaleKeys = #()
						for i = 1 to temp_animatedHeader.scaleNodeCount do (temp_animatedInfo.scaleKeys[i] = #())
						index1 = 1
						complete1 = false
						while not complete1 do
						(
							index2 = 1
							complete2 = false
							key = 0
							previousValue = 0
							while not complete2 do
							(
								if ((codec == 5) or (codec == 7)) then (key = readShortL useMap "#unsigned")
								else (key = readByte useMap #unsigned)
								if ((previousValue > key) or (key > (useAnim.frameCount - 1))) then
								(
									if ((codec == 5) or (codec == 7)) then (fseek useMap -2 #seek_cur)
									else (fseek useMap -1 #seek_cur)
									complete2 = true
								)
								else
								(
									previousValue = key
									temp_animatedInfo.scaleKeys[index1][index2] = key
									index2 += 1
								)
							)
							if (index1 == temp_animatedHeader.scaleNodeCount) then (complete1 = true)
							else (index1 += 1)
							if ((ftell useMap) == (temp_animatedHeader.codecOffset + temp_animatedHeader.transInfoOffset)) then (complete1 = true)
						)
						temp_animatedInfo.rot = #()
						fseek useMap (temp_animatedHeader.codecOffset + temp_animatedHeader.transInfoOffset) #seek_set
						temp_animatedInfo.trans = #()
						for n = 1 to temp_animatedHeader.transNodeCount do
						(
							temp_nodeTrans = #()
							for f = 1 to temp_animatedInfo.transKeys[n].count do
							(
								temp_transX = (readFloatL useMap) * 100.0
								temp_transY = (readFloatL useMap) * 100.0
								temp_transZ = (readFloatL useMap) * 100.0
								temp_trans = [temp_transX,temp_transY,temp_transZ]
								temp_nodeTrans[f] = temp_trans
							)
							temp_animatedInfo.trans[n] = temp_nodeTrans
						)
						if ((codec == 6) or (codec == 7)) then
						(
							temp_animatedInfo.transKeys = reverseArray temp_animatedInfo.transKeys
							temp_animatedInfo.trans = reverseArray temp_animatedInfo.trans
						)
						temp_animatedInfo.scale = #()
						for n = 1 to temp_animatedHeader.scaleNodeCount do
						(
							temp_nodeScale = #()
							for f = 1 to temp_animatedInfo.scaleKeys[n].count do
							(
								temp_scaleComponent = readFloatL useMap
								temp_scale = [temp_scaleComponent,temp_scaleComponent,temp_scaleComponent]
								temp_nodeScale[f] = temp_scale
							)
							temp_animatedInfo.scale[n] = temp_nodeScale
						)
						if ((codec == 6) or (codec == 7)) then
						(
							temp_animatedInfo.scaleKeys = reverseArray temp_animatedInfo.scaleKeys
							temp_animatedInfo.scale = reverseArray temp_animatedInfo.scale
						)
						rawIndex.animatedInfo = temp_animatedInfo
					)
					((temp_animatedHeader.rotNodeCount > 0) and (temp_animatedHeader.transNodeCount == 0) and (temp_animatedHeader.scaleNodeCount == 0)) :
					(
						temp_animatedHeader.rotKeysOffset = readLongL useMap "#unsigned"
						fseek useMap 12 #seek_cur
						temp_animatedHeader.unkOffset = readLongL useMap "#unsigned"
						temp_animatedHeader.rotInfoOffset = readLongL useMap "#unsigned"
						fseek useMap 12 #seek_cur
						
						temp_animatedInfo = jmad_animRawAnimatedInfo ()
						fseek useMap (temp_animatedHeader.codecOffset + temp_animatedHeader.rotKeysOffset) #seek_set
						temp_animatedInfo.rotKeys = #()
						for i = 1 to temp_animatedHeader.rotNodeCount do (temp_animatedInfo.rotKeys[i] = #())
						index1 = 1
						complete1 = false
						while not complete1 do
						(
							index2 = 1
							complete2 = false
							key = 0
							previousValue = 0
							while not complete2 do
							(
								if ((codec == 5) or (codec == 7)) then (key = readShortL useMap "#unsigned")
								else (key = readByte useMap #unsigned)
								if ((previousValue > key) or (key > (useAnim.frameCount - 1))) then
								(
									if ((codec == 5) or (codec == 7)) then (fseek useMap -2 #seek_cur)
									else (fseek useMap -1 #seek_cur)
									complete2 = true
								)
								else
								(
									previousValue = key
									temp_animatedInfo.rotKeys[index1][index2] = key
									index2 += 1
								)
							)
							if (index1 == temp_animatedHeader.rotNodeCount) then (complete1 = true)
							else (index1 += 1)
							if ((ftell useMap) == (temp_animatedHeader.codecOffset + temp_animatedHeader.unkOffset)) then (complete1 = true)
						)
						temp_animatedInfo.transKeys = #()
						temp_animatedInfo.scaleKeys = #()
						fseek useMap (temp_animatedHeader.codecOffset + temp_animatedHeader.rotInfoOffset) #seek_set
						temp_animatedInfo.rot = #()
						for n = 1 to temp_animatedHeader.rotNodeCount do
						(
							temp_nodeRot = #()
							for f = 1 to temp_animatedInfo.rotKeys[n].count do
							(
								temp_rotI = (readShortL useMap "#signed")/32767.0
								temp_rotJ = (readShortL useMap "#signed")/32767.0
								temp_rotK = (readShortL useMap "#signed")/32767.0
								temp_rotW = (readShortL useMap "#signed")/32767.0
								temp_rot = normalize (quat temp_rotI temp_rotJ temp_rotK temp_rotW)
								temp_nodeRot[f] = temp_rot
							)
							temp_animatedInfo.rot[n] = temp_nodeRot
						)
						if ((codec == 6) or (codec == 7)) then
						(
							temp_animatedInfo.rotKeys = reverseArray temp_animatedInfo.rotKeys
							temp_animatedInfo.rot = reverseArray temp_animatedInfo.rot
						)
						temp_animatedInfo.trans = #()
						temp_animatedInfo.scale = #()
						rawIndex.animatedInfo = temp_animatedInfo
					)
					((temp_animatedHeader.rotNodeCount == 0) and (temp_animatedHeader.transNodeCount > 0) and (temp_animatedHeader.scaleNodeCount == 0)) :
					(
						fseek useMap 4 #seek_cur
						temp_animatedHeader.transKeysOffset = readLongL useMap "#unsigned"
						fseek useMap 8 #seek_cur
						temp_animatedHeader.unkOffset = readLongL useMap "#unsigned"
						temp_animatedHeader.transInfoOffset = readLongL useMap "#unsigned"
						fseek useMap 12 #seek_cur
						
						temp_animatedInfo = jmad_animRawAnimatedInfo ()
						temp_animatedInfo.rotKeys = #()
						fseek useMap (temp_animatedHeader.codecOffset + temp_animatedHeader.transKeysOffset) #seek_set
						temp_animatedInfo.transKeys = #()
						for i = 1 to temp_animatedHeader.transNodeCount do (temp_animatedInfo.transKeys[i] = #())
						index1 = 1
						complete1 = false
						while not complete1 do
						(
							index2 = 1
							complete2 = false
							key = 0
							previousValue = 0
							while not complete2 do
							(
								if ((codec == 5) or (codec == 7)) then (key = readShortL useMap "#unsigned")
								else (key = readByte useMap #unsigned)
								if ((previousValue > key) or (key > (useAnim.frameCount - 1))) then
								(
									if ((codec == 5) or (codec == 7)) then (fseek useMap -2 #seek_cur)
									else (fseek useMap -1 #seek_cur)
									complete2 = true
								)
								else
								(
									previousValue = key
									temp_animatedInfo.transKeys[index1][index2] = key
									index2 += 1
								)
							)
							if (index1 == temp_animatedHeader.transNodeCount) then (complete1 = true)
							else (index1 += 1)
							if ((ftell useMap) == (temp_animatedHeader.codecOffset + temp_animatedHeader.unkOffset)) then (complete1 = true)
						)
						temp_animatedInfo.scaleKeys = #()
						temp_animatedInfo.rot = #()
						fseek useMap (temp_animatedHeader.codecOffset + temp_animatedHeader.transInfoOffset) #seek_set
						temp_animatedInfo.trans = #()
						for n = 1 to temp_animatedHeader.transNodeCount do
						(
							temp_nodeTrans = #()
							for f = 1 to temp_animatedInfo.transKeys[n].count do
							(
								temp_transX = (readFloatL useMap) * 100.0
								temp_transY = (readFloatL useMap) * 100.0
								temp_transZ = (readFloatL useMap) * 100.0
								temp_trans = [temp_transX,temp_transY,temp_transZ]
								temp_nodeTrans[f] = temp_trans
							)
							temp_animatedInfo.trans[n] = temp_nodeTrans
						)
						if ((codec == 6) or (codec == 7)) then
						(
							temp_animatedInfo.transKeys = reverseArray temp_animatedInfo.transKeys
							temp_animatedInfo.trans = reverseArray temp_animatedInfo.trans
						)
						temp_animatedInfo.scale = #()
						rawIndex.animatedInfo = temp_animatedInfo
					)
				)
			)
			
			rawIndex.animatedHeader = temp_animatedHeader
		)
		useAnim.raw = rawIndex
	)
	
	fn indexJmadMeta metaOffset =
	(
		jmadIndex = jmad ()
		fseek mapFile (metaOffset + 12) #seek_set
		skelNodeCount = readLongL mapFile "#unsigned"
		skelNodesOffset = (readLongL mapFile "#unsigned") - mapIndex.primaryMagic
		fseek mapFile skelNodesOffset #seek_set
		jmadIndex.nodes = #()
		for i = 1 to skelNodeCount do
		(
			temp_node = jmad_node ()
			nameSID = readShortL mapFile "#unsigned"
			temp_node.name = getStringByID nameSID
			fseek mapFile 2 #seek_cur
			temp_node.nextSiblingIndex = readShortL mapFile "#signed"
			temp_node.firstChildIndex = readShortL mapFile "#signed"
			temp_node.parentIndex = readShortL mapFile "#signed"
			fseek mapFile 22 #seek_cur
			jmadIndex.nodes[i] = temp_node
		)
		fseek mapFile (metaOffset + 44) #seek_set
		animCount = readLongL mapFile "#unsigned"
		animOffset = (readLongL mapFile "#unsigned") - mapIndex.primaryMagic
		fseek mapFile animOffset #seek_set
		jmadIndex.anims = #()
		for j = 1 to animCount do
		(
			temp_anim = jmad_anim ()
			nameSID = readShortL mapFile "#unsigned"
			temp_anim.name = getStringByID nameSID
			fseek mapFile 14 #seek_cur
			temp_anim.type = readByte mapFile #unsigned
			temp_anim.frameInfoType = readByte mapFile #unsigned
			fseek mapFile 2 #seek_cur
			temp_anim.frameCount = readShortL mapFile "#unsigned"
			temp_anim.internalFlags = parseFlagArray (readByte mapFile #unsigned)
			fseek mapFile 13 #seek_cur
			temp_anim.rawLocInfoIndex = readShortL mapFile "#unsigned"
			fseek mapFile 2 #seek_cur
			temp_anim.rawAnimOffset = readShortL mapFile "#unsigned"
			fseek mapFile 18 #seek_cur
			temp_anim.staticNodeFlags = readByte mapFile #unsigned
			temp_anim.animatedNodeFlags = readByte mapFile #unsigned
			temp_anim.movementNodes = readLongL mapFile "#unsigned"
			temp_anim.compressedStaticNodeSize = readLongL mapFile "#unsigned"
			fseek mapFile 2 #seek_cur
			temp_anim.compressedAnimatedNodeSize = readLongL mapFile "#unsigned"
			fseek mapFile 32 #seek_cur
			jmadIndex.anims[j] = temp_anim
		)
		fseek mapFile (metaOffset + 172) #seek_set
		rawLocInfoCount = readLongL mapFile "#unsigned"
		rawLocInfoOffset = (readLongL mapFile "#unsigned") - mapIndex.primaryMagic
		fseek mapFile rawLocInfoOffset #seek_set
		jmadIndex.rawLocInfos = #()
		for k = 1 to rawLocInfoCount do
		(
			temp_rawLocInfo = jmad_rawLocInfo ()
			fseek mapFile 4 #seek_cur
			temp_rawLocInfo.size = readLongL mapFile "#unsigned"
			loc = getRawLocationByOffset (readLongL mapFile "#unsigned")
			temp_rawLocInfo.offset = loc[1]
			temp_rawLocInfo.location = loc[2]
			fseek mapFile 8 #seek_cur
			jmadIndex.rawLocInfos[k] = temp_rawLocInfo
		)
		for i in jmadIndex.anims do
		(
			i.rawAnimOffset += jmadIndex.rawLocInfos[i.rawLocInfoIndex + 1].offset
			i.rawAnimLocation = jmadIndex.rawLocInfos[i.rawLocInfoIndex + 1].location
		)
		jmadIndex
	)
	
	fn loadAnim useAnim =
	(
		indexAnimRaw useAnim
		impNodeStates_save.enabled = true
		impNodeStates_sync.enabled = true
		impParams_frmInfo.enabled = (useAnim.frameInfoType > 0)
		impParams_frmInfo.checked = (useAnim.frameInfoType > 0)
		impParams_copyZero.enabled = (useAnim.type != 1)
		impParams_copyZero.checked = false
		impParams_stFrm_lbl.enabled = true
		impParams_stFrm.enabled = true
		imp_importAnim.enabled = true
		impDbg_prntAnim.enabled = true
		impDbg_prntAnim_head.enabled = true
		impDbg_prntAnim_head.checked = true
		impDbg_prntAnim_frm.enabled = (useAnim.frameInfoType > 0)
		impDbg_prntAnim_frm.checked = (useAnim.frameInfoType > 0)
		impDbg_prntAnim_stat.enabled = (useAnim.raw.staticHeader != undefined)
		impDbg_prntAnim_stat.checked = (useAnim.raw.staticHeader != undefined)
		impDbg_prntAnim_anim.enabled = (useAnim.raw.animatedHeader != undefined)
		impDbg_prntAnim_anim.checked = (useAnim.raw.animatedHeader != undefined)
		impDbgProps_type.text = ("Type: " + enumAnimationType[useAnim.type + 1])
		impDbgProps_frmType.text = ("Fr. Info Type: " + enumFrameInfoType[useAnim.frameInfoType + 1])
		impDbgProps_frmCount.text = ("Fr. Count: " + useAnim.frameCount as string)
		try (impDbgProps_codec.text = ("Codec: " + useAnim.raw.animatedHeader.codec as string))
		catch (impDbgProps_codec.text = "Codec: N/A")
	)
	
	fn clearAnim =
	(
		impNodeStates_save.enabled = false
		impNodeStates_sync.enabled = false
		impParams_frmInfo.enabled = false
		impParams_frmInfo.checked = false
		impParams_copyZero.enabled = false
		impParams_copyZero.checked = false
		impParams_stFrm_lbl.enabled = false
		impParams_stFrm.enabled = false
		imp_importAnim.enabled = false
		impDbg_prntAnim.enabled = false
		impDbg_prntAnim_head.enabled = false
		impDbg_prntAnim_head.checked = false
		impDbg_prntAnim_frm.enabled = false
		impDbg_prntAnim_frm.checked = false
		impDbg_prntAnim_stat.enabled = false
		impDbg_prntAnim_stat.checked = false
		impDbg_prntAnim_anim.enabled = false
		impDbg_prntAnim_anim.checked = false
		impDbgProps_type.text = "Type: "
		impDbgProps_frmType.text = "Fr. Info Type: "
		impDbgProps_frmCount.text = "Fr. Count: "
		impDbgProps_codec.text = "Codec: "
	)
	
	fn loadTag useTag =
	(
		clearAnimList ()
		populateAnimList useTag
		clearExportQueue ()
		mapExportQueueItems useTag
		populateExportQueueItems ()
		group_tags.text = ("Animation Tags: " + (filenameFromPath useTag.path))
		tagsDbg_prntJmad.enabled = true
		tagsDbg_prntJmad_node.enabled = (useTag.metaIndex.nodes.count > 0)
		tagsDbg_prntJmad_node.checked = (useTag.metaIndex.nodes.count > 0)
		tagsDbg_prntJmad_anim.enabled = (useTag.metaIndex.anims.count > 0)
		tagsDbg_prntJmad_anim.checked = (useTag.metaIndex.anims.count > 0)
		tagsDbg_prntJmad_raw.enabled = (useTag.metaIndex.rawLocInfos.count > 0)
		tagsDbg_prntJmad_raw.checked = (useTag.metaIndex.rawLocInfos.count > 0)
		tagsDbgStats_node.text = ("Node Blocks: " + useTag.metaIndex.nodes.count as string)
		tagsDbgStats_anim.text = ("Anim. Blocks: " + useTag.metaIndex.anims.count as string)
		tagsDbgStats_raw.text = ("Raw Loc. Blocks: " + useTag.metaIndex.rawLocInfos.count as string)
		tagsDbgNodeList_save.enabled  = true
		tagsDbgNodeList_sync.enabled  = true
		try
		(
			selAnim = useTag.metaIndex.anims[1]
			loadAnim selAnim
		)
		catch ()
	)
	
	fn clearTag =
	(
		group_tags.text = "Animation Tags"
		tagsDbg_prntJmad.enabled = false
		tagsDbg_prntJmad_node.enabled = false
		tagsDbg_prntJmad_node.checked = false
		tagsDbg_prntJmad_anim.enabled = false
		tagsDbg_prntJmad_anim.checked = false
		tagsDbg_prntJmad_raw.enabled = false
		tagsDbg_prntJmad_raw.checked = false
		tagsDbgStats_node.text = "Node Blocks: "
		tagsDbgStats_anim.text = "Anim. Blocks: "
		tagsDbgStats_raw.text = "Raw Loc. Blocks: "
		tagsDbgNodeList_save.enabled  = false
		tagsDbgNodeList_sync.enabled  = false
	)
	
	fn indexMap =
	(
		mapIndex = map ()
		fseek mapFile 16 #seek_set
		mapIndex.indexOffset = readLongL mapFile "#unsigned"
		mapIndex.indexSize = readLongL mapFile "#unsigned"
		mapIndex.metaSize = readLongL mapFile "#unsigned"
		fseek mapFile 708 #seek_set
		mapIndex.fileTableOffset = readLongL mapFile "#unsigned"
		fseek mapFile 364 #seek_set
		mapIndex.stringIDIndexOffset = readLongL mapFile "#unsigned"
		mapIndex.stringIDTableOffset = readLongL mapFile "#unsigned"
		fseek mapFile 408 #seek_set
		mapIndex.name = readString mapFile
		fseek mapFile mapIndex.indexOffset #seek_set
		mapIndex.primaryMagicConstant = readLongL mapFile "#unsigned"
		fseek mapFile 4 #seek_cur
		mapIndex.objectIndexOffset = readLongL mapFile "#unsigned"
		fseek mapFile 12 #seek_cur
		mapIndex.objectCount = readLongL mapFile "#unsigned"
		fseek mapFile (mapIndex.indexOffset + 32 + (mapIndex.objectIndexOffset - mapIndex.primaryMagicConstant)) #seek_set
		mapIndex.tags = #()
		for i = 1 to mapIndex.objectCount do
		(
			tempTag = tag ()
			tempTag.class = reverseString (readCharSet mapFile 4)
			tempTag.id = readLongL mapFile "#unsigned"
			tempTag.metaOffset = readLongL mapFile "#unsigned"
			tempTag.metaSize = readLongL mapFile "#unsigned"
			mapIndex.tags[i] = tempTag
		)
		mapIndex.primaryMagic = mapIndex.tags[1].metaOffset - (mapIndex.indexOffset + mapIndex.indexSize)
		mapIndex.secondaryMagic = mapIndex.primaryMagicConstant - mapIndex.indexOffset - 32
		for j = 1 to mapIndex.objectCount do (mapIndex.tags[j].metaOffset -= mapIndex.primaryMagic)
		fseek mapFile mapIndex.fileTableOffset #seek_set
		for k = 1 to mapIndex.objectCount do (mapIndex.tags[k].path = readString mapFile)
		for i in mapIndex.tags where (i.class as name == "jmad" as name) do (i.metaIndex = indexJmadMeta i.metaOffset)
		
		populateTagList ()
		try
		(
			selTag = getSelectedTag ()
			loadTag selTag
		)
		catch ()
	)
	
	fn loadMap =
	(
		mapFile = fopen mapPath "rb"
		
		sharedCheck = doesFileExist ((getFilenamePath mapPath) + "shared.map")
		spSharedCheck = doesFileExist ((getFilenamePath mapPath) + "single_player_shared.map")
		mainmenuCheck = doesFileExist ((getFilenamePath mapPath) + "mainmenu.map")
		
		missingString = "The following shared maps could not be found:\n\n"
		if not sharedCheck then (missingString += "shared.map\n")
		else (sharedFile = fopen ((getFilenamePath mapPath) + "shared.map") "rb")
		if not spSharedCheck then (missingString += "single_player_shared.map\n")
		else (spSharedFile = fopen ((getFilenamePath mapPath) + "single_player_shared.map") "rb")
		if not mainmenuCheck then (missingString += "mainmenu.map\n")
		else (mainmenuFile = fopen ((getFilenamePath mapPath) + "mainmenu.map") "rb")
		missingString += "\nSome animations may not be accessible."
		if (not sharedCheck or not spSharedCheck or not mainmenuCheck) then (messageBox missingString title:"Warning")
		
		indexMap ()
	)
	
	fn clrMap =
	(
		try (fclose mapFile)
		catch ()
		try (fclose sharedFile)
		catch ()
		try (fclose spSharedFile)
		catch ()
		try (fclose mainmenuFile)
		catch ()
		
		sharedCheck = false
		spSharedCheck = false
		mainmenuCheck = false
		
		group_map.caption = "Map File: No map loaded"
		map_clr.enabled = false
		map_text.text = ""
		clearTag ()
		clearTagList ()
		clearAnim ()
		clearAnimList ()
		clearExportQueue ()
		
		mapIndex = undefined
	)
	
	fn selMap =
	(
		try
		(
			mapPath = getOpenFileName	caption:"Open Halo 2 Map" \
										filename:lastPath \
										types:"Halo 2 Map File (*.MAP)|*.MAP|"
			if (mapPath != undefined) then
			(
				clrMap ()
				lastPath = getFilenamePath mapPath
				
				group_map.caption = ("Map File: " + filenameFromPath mapPath)
				map_clr.enabled = true
				map_text.text = mapPath
				
				loadMap ()
			)
		)
		catch (clrMap ())
	)
	
	fn importAnimToScene useTag animID startFrame useFrmInfo =
	(
		useAnim = useTag.metaIndex.anims[animID]
		indexAnimRaw useAnim
		
		max tool animmode
		set animate on
		
		animationRange = interval 0 (startFrame + useAnim.frameCount)
		
		for n = 1 to useTag.metaIndex.nodes.count do
		(
			try
			(
				temp_node = (getNodeByName ("frame " + useTag.metaIndex.nodes[n].name))
				temp_node.rotation.controller = bezier_rotation ()
				deleteControllerKeys temp_node.rotation.controller startFrame
				deleteControllerKeys temp_node.position.controller startFrame
				deleteControllerKeys temp_node.scale.controller startFrame
				if ((useAnim.type == 0) or (useAnim.type == 2)) then
				(
					if (useAnim.raw.statRotFlags[n] or useAnim.raw.animRotFlags[n]) then
					(
						temp_rot = in coordsys parent temp_node.rotation
						in coordsys local temp_node.rotation = inverse temp_rot
					)
				--	** redundant
				--	if (useAnim.raw.statTransFlags[n] or useAnim.raw.animTransFlags[n]) then
				--	(
				--		temp_trans = in coordsys parent temp_node.position
				--		in coordsys local temp_node.position = (temp_trans * -1)
				--	)
				--	if (useAnim.raw.statScaleFlags[n] or useAnim.raw.animScaleFlags[n]) then
				--	(
				--		in coordsys parent temp_node.scale = [1,1,1]
				--	)
				--	** redundant
				)
			)
			catch ()
		)
		
		indexRot = 1
		indexTrans = 1
		indexScale = 1
		for i = 1 to useTag.metaIndex.nodes.count do
		(
			try
			(
				temp_node = (getNodeByName ("frame " + useTag.metaIndex.nodes[i].name))
				if useAnim.raw.statRotFlags[i] then
				(
					in coordsys local temp_node.rotation = useAnim.raw.staticInfo.rot[indexRot]
					indexRot += 1
				)
				if useAnim.raw.statTransFlags[i] then
				(
					if (useAnim.type == 1) then (in coordsys parent temp_node.pos += useAnim.raw.staticInfo.trans[indexTrans])
					else (in coordsys parent temp_node.pos = useAnim.raw.staticInfo.trans[indexTrans])
					indexTrans += 1
				)
				if useAnim.raw.statScaleFlags[i] then
				(
					if (useAnim.type == 1) then (in coordsys parent temp_node.scale += useAnim.raw.staticInfo.scale[indexScale])
					else (in coordsys parent temp_node.scale = useAnim.raw.staticInfo.scale[indexScale])
					indexScale += 1
				)
			)
			catch ()
		)
		
		codec = useAnim.raw.animatedHeader.codec
		case of
		(
			((codec == 3) or (codec == 8)) :
			(
				indexRot = 1
				indexTrans = 1
				indexScale = 1
				for i = 1 to useTag.metaIndex.nodes.count do
				(
					try
					(
						temp_node = (getNodeByName ("frame " + useTag.metaIndex.nodes[i].name))
						if useAnim.raw.animRotFlags[i] then
						(
							for n = 1 to useAnim.frameCount do (addNewKey temp_node.rotation.controller (startFrame + (n - 1)))
							if impParams_copyZero.checked then (addNewKey temp_node.rotation.controller (startFrame + useAnim.frameCount))
							for f = 1 to useAnim.frameCount do
							(
								at time (startFrame + (f - 1)) (in coordsys local temp_node.rotation = useAnim.raw.animatedInfo.rot[indexRot][f])
							)
							if impParams_copyZero.checked then
							(
								at time (startFrame + useAnim.frameCount) (in coordsys local temp_node.rotation = useAnim.raw.animatedInfo.rot[indexRot][1])
							)
							indexRot += 1
						)
						if useAnim.raw.animTransFlags[i] then
						(
							for n = 1 to useAnim.frameCount do (addNewKey temp_node.position.controller (startFrame + (n - 1)))
							if impParams_copyZero.checked then (addNewKey temp_node.position.controller (startFrame + useAnim.frameCount))
							for f = 1 to useAnim.frameCount do
							(
								if (useAnim.type == 1) then (at time (startFrame + (f - 1)) (in coordsys parent temp_node.position += useAnim.raw.animatedInfo.trans[indexTrans][f]))
								else (at time (startFrame + (f - 1)) (in coordsys parent temp_node.position = useAnim.raw.animatedInfo.trans[indexTrans][f]))
							)
							if impParams_copyZero.checked then
							(
								at time (startFrame + useAnim.frameCount) (in coordsys parent temp_node.position = useAnim.raw.animatedInfo.trans[indexTrans][1])
							)
							indexTrans += 1
						)
						if useAnim.raw.animScaleFlags[i] then
						(
							for n = 1 to useAnim.frameCount do (addNewKey temp_node.scale.controller (startFrame + (n - 1)))
							if impParams_copyZero.checked then (addNewKey temp_node.scale.controller (startFrame + useAnim.frameCount))
							for f = 1 to useAnim.frameCount do
							(
								if (useAnim.type == 1) then (at time (startFrame + (f - 1)) (in coordsys parent temp_node.scale += useAnim.raw.animatedInfo.scale[indexScale][f]))
								else (at time (startFrame + (f - 1)) (in coordsys parent temp_node.scale = useAnim.raw.animatedInfo.scale[indexScale][f]))
							)
							if impParams_copyZero.checked then
							(
								at time (startFrame + useAnim.frameCount) (in coordsys parent temp_node.scale = useAnim.raw.animatedInfo.scale[indexScale][1])
							)
							indexScale += 1
						)
					)
					catch ()
				)
			)
			((codec == 4) or (codec == 5) or (codec == 6) or (codec == 7)) :
			(
				indexRot = 1
				indexTrans = 1
				indexScale = 1
				for i = 1 to useTag.metaIndex.nodes.count do
				(
					try
					(
						temp_node = (getNodeByName ("frame " + useTag.metaIndex.nodes[i].name))
						deleteControllerKeys temp_node.rotation.controller startFrame
						if useAnim.raw.animRotFlags[i] then
						(
							for n in useAnim.raw.animatedInfo.rotKeys[indexRot] do (addNewKey temp_node.rotation.controller (startFrame + n))
							if impParams_copyZero.checked then (addNewKey temp_node.rotation.controller (startFrame + useAnim.frameCount))
							for f = 1 to useAnim.raw.animatedInfo.rotKeys[indexRot].count do
							(
								at time (startFrame + useAnim.raw.animatedInfo.rotKeys[indexRot][f]) (in coordsys local temp_node.rotation = useAnim.raw.animatedInfo.rot[indexRot][f])
							)
							if impParams_copyZero.checked then
							(
								at time (startFrame + useAnim.frameCount) (in coordsys local temp_node.rotation = useAnim.raw.animatedInfo.rot[indexRot][1])
							)
							indexRot += 1
						)
						deleteControllerKeys temp_node.position.controller startFrame
						if useAnim.raw.animTransFlags[i] then
						(
							for n in useAnim.raw.animatedInfo.transKeys[indexTrans] do (addNewKey temp_node.position.controller (startFrame + n))
							if impParams_copyZero.checked then (addNewKey temp_node.position.controller (startFrame + useAnim.frameCount))
							for f = 1 to useAnim.raw.animatedInfo.transKeys[indexTrans].count do
							(
								if (useAnim.type == 1) then (at time (startFrame + useAnim.raw.animatedInfo.transKeys[indexTrans][f]) (in coordsys parent temp_node.position += useAnim.raw.animatedInfo.trans[indexTrans][f]))
								else (at time (startFrame + useAnim.raw.animatedInfo.transKeys[indexTrans][f]) (in coordsys parent temp_node.position = useAnim.raw.animatedInfo.trans[indexTrans][f]))
							)
							if impParams_copyZero.checked then
							(
								at time (startFrame + useAnim.frameCount) (in coordsys parent temp_node.position = useAnim.raw.animatedInfo.trans[indexTrans][1])
							)
							indexTrans += 1
						)
						deleteControllerKeys temp_node.scale.controller startFrame
						if useAnim.raw.animScaleFlags[i] then
						(
							for n in useAnim.raw.animatedInfo.scaleKeys[indexScale] do (addNewKey temp_node.scale.controller (startFrame + n))
							if impParams_copyZero.checked then (addNewKey temp_node.scale.controller (startFrame + useAnim.frameCount))
							for f = 1 to useAnim.raw.animatedInfo.scaleKeys[indexScale].count do
							(
								if (useAnim.type == 1) then (at time (startFrame + useAnim.raw.animatedInfo.scaleKeys[indexScale][f]) (in coordsys parent temp_node.scale += useAnim.raw.animatedInfo.scale[indexScale][f]))
								else (at time (startFrame + useAnim.raw.animatedInfo.scaleKeys[indexScale][f]) (in coordsys parent temp_node.scale = useAnim.raw.animatedInfo.scale[indexScale][f]))
							)
							if impParams_copyZero.checked then
							(
								at time (startFrame + useAnim.frameCount) (in coordsys parent temp_node.scale = useAnim.raw.animatedInfo.scale[indexScale][1])
							)
							indexScale += 1
						)
					)
					catch ()
				)
				for i = 1 to useTag.metaIndex.nodes.count where useAnim.raw.animRotFlags[i] do
				(
					try
					(
						temp_node = (getNodeByName ("frame " + useTag.metaIndex.nodes[i].name))
						deselectKeys temp_node.rotation.controller
						keyTimes = for x in temp_node.rotation.controller.keys collect ((x.time as integer)/160)
						unsetKeyTimes = for y = 1 to keyTimes.count where (((keyTimes[y] + 1) != keyTimes[y + 1]) and (y != keyTimes.count)) collect (keyTimes[y] + 1)
						for z = 1 to unsetKeyTimes.count do (addNewKey temp_node.rotation.controller unsetKeyTimes[z] #select)
						deleteKeys temp_node.rotation.controller #selection
					)
					catch ()
				)
			)
		)
		
		if ((useAnim.frameInfoType > 0) and useFrmInfo) then
		(
			try
			(
				root_node = (getNodeByName ("frame " + useTag.metaIndex.nodes[1].name))
				for n = 1 to useAnim.frameCount do (addNewKey root_node.position.controller (startFrame + (n - 1)))
				if (useAnim.frameInfoType > 1) then (for m = 1 to useAnim.frameCount do (addNewKey root_node.rotation.controller (startFrame + (m - 1))))
				total_dx = 0
				total_dy = 0
				total_dz = 0
				total_dyaw = 0
				for i = 1 to useAnim.frameCount do
				(
					sliderTime = (startFrame + (i - 1))
					if (useAnim.frameInfoType > 1) then
					(
						total_dyaw += useAnim.raw.frameInfos[i].dyaw
						rotate root_node (angleaxis total_dyaw [0,0,1])
					)
					total_dx += useAnim.raw.frameInfos[i].dx
					total_dy += useAnim.raw.frameInfos[i].dy
					if (useAnim.frameInfoType == 3) then (total_dz += useAnim.raw.frameInfos[i].dz)
					in coordsys parent root_node.position += [total_dx,total_dy,total_dz]
				)
			)
			catch ()
		)
		
		
		max tool animmode
		set animate off
	)
	
	fn exportNodeList useTag =
	(
		nostListPath = getSaveFileName	caption:"Save Node List" \
										filename:lastPath \
										types:"Text File (*.txt)|*.txt|"
		if (nostListPath != undefined) then
		(
			lastPath = getFilenamePath nostListPath
			nodeListFile = createFile nostListPath
			if (nodeListFile != undefined) then (for i in useTag.metaIndex.nodes do (format "%\n" i.name to:nodeListFile))
			try (close nodeListFile)
			catch ()
		)
	)
	
	fn syncNodeList useTag =
	(
		if (classOf z_animRawGenH2 == RolloutClass) and z_animRawGenH2.open then
		(
			nodeNames = for i in useTag.metaIndex.nodes collect i.name
			try
			(
				z_animRawGenH2.populateNodeList nodeNames
				z_animRawGenH2.node_list.selection = z_animRawGenH2.node_list.items.count
				z_animRawGenH2.updatedSelectedNode ()
			)
			catch ()
		)
		else (messageBox "Animation Raw Data Generator could not be found" title:"Error")
	)
	
	fn exportNodeStates useTag animID =
	(
		nodeStatePath = getSaveFileName	caption:"Save Node States" \
										filename:lastPath \
										types:"Text File (*.txt)|*.txt|"
		if (nodeStatePath != undefined) then
		(
			lastPath = getFilenamePath nodeStatePath
			nodeStateFile = createFile nodeStatePath
			if (nodeStateFile != undefined) then
			(
				useAnim = useTag.metaIndex.anims[animID]
				for i = 1 to useTag.metaIndex.nodes.count do
				(
					if useAnim.raw.statRotFlags[i] then (rotType = 3)
					else
					(
						if useAnim.raw.animRotFlags[i] then (rotType = 2)
						else (rotType = 1)
					)
					if useAnim.raw.statTransFlags[i] then (transType = 3)
					else
					(
						if useAnim.raw.animTransFlags[i] then (transType = 2)
						else (transType = 1)
					)
					if useAnim.raw.statScaleFlags[i] then (scaleType = 3)
					else
					(
						if useAnim.raw.animScaleFlags[i] then (scaleType = 2)
						else (scaleType = 1)
					)
					format "%\t%\t%\n" rotType transType scaleType to:nodeStateFile
				)
			)
			try (close nodeStateFile)
			catch ()
		)
	)
	
	fn syncNodeStates useTag animID =
	(
		if (classOf z_animRawGenH2 == RolloutClass) and z_animRawGenH2.open then
		(
			useAnim = useTag.metaIndex.anims[animID]
			stateArray = #()
			for i = 1 to useTag.metaIndex.nodes.count do
			(
				if useAnim.raw.statRotFlags[i] then (rotType = 3)
				else
				(
					if useAnim.raw.animRotFlags[i] then (rotType = 2)
					else (rotType = 1)
				)
				if useAnim.raw.statTransFlags[i] then (transType = 3)
				else
				(
					if useAnim.raw.animTransFlags[i] then (transType = 2)
					else (transType = 1)
				)
				if useAnim.raw.statScaleFlags[i] then (scaleType = 3)
				else
				(
					if useAnim.raw.animScaleFlags[i] then (scaleType = 2)
					else (scaleType = 1)
				)
				append stateArray #(rotType, transType, scaleType)
			)
			try
			(
				z_animRawGenH2.setNodeStates stateArray
				z_animRawGenH2.updatedSelectedNode ()
			)
			catch ()
		)
		else (messageBox "Animation Raw Data Generator could not be found" title:"Error")
	)
	
	fn isNode nodeName =
	(
		local isNode = false
		try
		(
			if (substring nodeName 1 5 as name == #frame) or (substring nodeName 1 5 as name == #bip01) then (isNode = true)
			else (isNode = false)
		)
		catch (isNode = false)
		isNode
	)
	
	fn indexNodes =
	(
		local failed = false
		local temp_rootSceneNode = undefined
		local temp_nodeArray = #()
		local temp_nodeNames = #()
		local temp_nodeParentIndices = #()
		local temp_nodeFirstChildIndices = #()
		local temp_nodeNextSiblingIndices = #()
		
		try
		(
			temp_nodeArray = $'frame*' as array + $'bip01*' as array -- collect node objects
			for i in temp_nodeArray do
			(
				if (i.parent != undefined) and (not isNode i.parent.name) then (failed = true)
				-- fails if the node is parented to an invalid node (node parented to non-node error)
			)
			if not failed then
			(
				for i in temp_nodeArray do
				(
					if (i.parent == undefined) then
					(
						if (temp_rootSceneNode != undefined) then (failed = true)
						-- fails if the node is unparented and there is already another unparented node (to many actors error)
						else
						(
							temp_rootSceneNode = i
							i.name = "01" + i.name
							-- the purpose of adding the hierarchy level to the beginning of node names is to sort them later
						)
					)
					else
					(
						hierarchyLevel = 1
						temp_parentNode = i.parent
						do
						(
							temp_oldParentNode = temp_parentNode
							temp_parentNode = temp_parentNode.parent
							hierarchyLevel += 1
							-- this determines a node's hierarchy level by adding 1 each time it traverses a parent node
						)
						while (temp_parentNode != undefined)
						if (temp_oldParentNode != temp_rootSceneNode) then (failed = true)
						else
						(
							if (hierarchyLevel < 10) then (i.name = "0" + hierarchyLevel as string + i.name)
							else (i.name = hierarchyLevel as string + i.name)
							-- it is necessary to append "0" before the heirarchy level if it is less than 10, because of the way MAX sorts strings
						)
					)
				)
				if not failed then
				(
					temp_nodeNames = for i in temp_nodeArray collect i.name
					sort temp_nodeNames -- this sorts the nodes in the order of heirarchy, then name
					temp_nodeArraySorted = #()
					for i = 1 to temp_nodeArray.count do (temp_nodeArraySorted[i] = getNodeByName temp_nodeNames[i])
					-- creates the "real" node array from the node name array
					for i = 1 to temp_nodeArray.count do (temp_nodeArray[i].name = substring temp_nodeArray[i].name 3 -1)
					-- reverts the node names back to normal (removes appended heirarchy level numbers)
					temp_nodeArray = temp_nodeArraySorted
					nodeArray = temp_nodeArraySorted
					for i = 1 to temp_nodeArray.count do (temp_nodeParentIndices[i] = findItem temp_nodeArray temp_nodeArray[i].parent)
					-- determines the node's parent index
					for i = 1 to temp_nodeArray.count do
					(
						temp_nodeChildren = for j in temp_nodeArray[i].children where (isNode j.name) collect j
						try (temp_nodeFirstChildIndices[i] = findItem temp_nodeArray temp_nodeChildren[temp_nodeChildren.count])
						catch (temp_nodeFirstChildIndices[i] = 0)
					)
					-- determines the node's first child index
					temp_nodeChildren = #()
					temp_nodeChildIndices = #()
					temp_nodeChildUsed = #()
					for i = 1 to temp_nodeArray.count do
					(
						temp_nodeChildren[i] = for j in temp_nodeArray[i].children where (isNode j.name) collect j
						temp_nodeChildren[i] = reverseArray temp_nodeChildren[i]
						temp_nodeChildIndices[i] = for j in temp_nodeChildren[i] collect (findItem temp_nodeArray j)
						temp_nodeChildUsed[i] = #{}
					)
					for i = 1 to temp_nodeArray.count do
					(
						for j = 1 to temp_nodeArray.count do
						(
							temp_usedChildIndex = findItem temp_nodeChildIndices[i] temp_nodeFirstChildIndices[j]
							if (temp_usedChildIndex != 0) then (temp_nodeChildUsed[i][temp_usedChildIndex] = true)
						)
					)
					for i = temp_nodeArray.count to 1 by -1 do
					(
						if (temp_nodeArray[i].parent != undefined) then
						(
							parentIndex = findItem temp_nodeArray temp_nodeArray[i].parent
							temp_parentChildren = temp_nodeChildren[parentIndex]
							temp_parentChildIndices = temp_nodeChildIndices[parentIndex]
							temp_parentChildUsed = temp_nodeChildUsed[parentIndex]
							for j = 1 to temp_parentChildren.count do
							(
								if ((not temp_parentChildUsed[j]) and (temp_parentChildren[j] != temp_nodeArray[i])) then
								(
									temp_parentChildUsed[j] = true
									temp_nodeNextSiblingIndices[i] = temp_parentChildIndices[j]
									exit
								)
							)
							if (temp_nodeNextSiblingIndices[i] == undefined) then (temp_nodeNextSiblingIndices[i] = 0)
						)
						else (temp_nodeNextSiblingIndices[i] = 0)
					)
					-- determines the node's next sibling index
					
					for i = 1 to temp_nodeArray.count do
					(
						temp_exportNode = export_node ()
						temp_exportNode.name = temp_nodeArray[i].name
						temp_exportNode.index = i
						temp_exportNode.parentIndex = temp_nodeParentIndices[i]
						temp_exportNode.firstChildIndex = temp_nodeFirstChildIndices[i]
						temp_exportNode.nextSiblingIndex = temp_nodeNextSiblingIndices[i]
						nodeArrayExport[i] = temp_exportNode
					)
					-- creates an array of nodes containing the gathered infomation for ease of exporting
				)
			)
			if failed then
			(
				for i in temp_nodeArray do (if (not isNode i.name) then (i.name = substring i.name 3 -1))
				-- if the export fails, reverts the nodes names back to normal if they were tampered with
			)
		)
		catch (failed = true)
		
		failed
	)
	
	fn exportSceneAnimation target =
	(
		local failed = false
		try
		(
			frameCount = ((animationRange.end - animationRange.start) as integer/160) + 1
			
			format "%\n" 16392 to:target
			format "%\n" frameCount to:target
			format "%\n" frameRate to:target
			format "%\n" 1 to:target
			format "%\n" "unnamedActor" to:target
			format "%\n" nodeArrayExport.count to:target
			format "%\n" nodeListChecksum to:target
			
			for i = 1 to nodeArrayExport.count do
			(
				format "%\n" nodeArrayExport[i].name to:target
				format "%\n" (nodeArrayExport[i].firstChildIndex - 1) to:target
				format "%\n" (nodeArrayExport[i].nextSiblingIndex - 1) to:target
			)
			
			sliderTime = animationRange.start
			for j = 1 to frameCount do
			(
				for k = 1 to nodeArray.count do
				(
					in coordsys parent nodePosition = nodeArray[k].position
					in coordsys parent tempNodeRotation = nodeArray[k].rotation
					nodeRotation = quat -tempNodeRotation.x -tempNodeRotation.y -tempNodeRotation.z tempNodeRotation.w
					in coordsys parent nodeScale = nodeArray[k].scale.x
					
					format "%\t%\t%\n" nodePosition.x nodePosition.y nodePosition.z to:target
					format "%\t%\t%\t%\n" nodeRotation.x nodeRotation.y nodeRotation.z nodeRotation.w to:target
					format "%\n" nodeScale to:target
				)
				if (j != (animationRange.start + frameCount)) do (sliderTime += 1)
			)
			format "\nexported with zteam animation exporter\n" to:target
			format "ctrlaltdestroy, choking victim, shadowspartan\n" to:target
			sliderTime = animationRange.start
		)
		catch (failed = true)
		
		failed
	)
	
	fn batchExportAnims =
	(
		selTag = getSelectedTag ()
		
		exportFailed = false
		saveMax = btc_export_saveMax.checked
		saveBtz = btc_export_saveBtz.checked
		messageStream = stringStream ""
		format "Done\n\n" to:messageStream
		
		progressStart "Exporting animations..."
		startStamp = timeStamp ()
		queuedCount = 0
		for n = 1 to itemArray.count where itemArray[n].checked do (queuedCount += 1)
		queueIndex = 1
		for i = 1 to itemArray.count where itemArray[i].checked do
		(
			success = loadMaxFile originScene quiet:true
			if success then
			(
				disableSceneRedraw ()
				proceed = true
				try (importAnimToScene selTag itemArray[i].id 0 true)
				catch
				(
					format "% could not be imported and was skipped\n" selTag.metaIndex.anims[itemArray[i].id].name to:messageStream
					proceed = false
					continue
				)
				if saveMax then
				(
					try
					(
						saveScenePath = getAvailableFilePath saveDir itemArray[i].name "max" true
						saveMaxFile saveScenePath useNewFile:false quiet:true
					)
					catch
					(
						messageStream = stringStream ""
						format "Error\n\n" to:messageStream
						format "Scene could not be saved\n" to:messageStream
						exportFailed = true
						proceed = false
						exit
					)
				)
				if not saveBtz then (proceed = false)
				if proceed then
				(
					failed = indexNodes ()
					if not failed then
					(
						try
						(
							usePath = getAvailableFilePath saveDir itemArray[i].name itemArray[i].extension true
							useFile = createFile usePath
							exportSceneAnimation useFile
							try (close useFile)
							catch ()
						)
						catch
						(
							messageStream = stringStream ""
							format "Error\n\n" to:messageStream
							format "Export could not be saved\n" to:messageStream
							exportFailed = true
							proceed = false
							exit
						)
					)
					else
					(
						messageStream = stringStream ""
						format "Error\n\n" to:messageStream
						format "Origin scene file could not be opened\n" to:messageStream
						exportFailed = true
						exit
					)
				)
			)
			else
			(
				messageStream = stringStream ""
				format "Error\n\n" to:messageStream
				format "Nodes could not be indexed\n" to:messageStream
				exportFailed = true
				exit
			)
			progressUpdate ((queueIndex as float/queuedCount as float) * 100.0)
			queueIndex += 1
		)
		endStamp = timeStamp ()
		progressEnd ()
		enableSceneRedraw ()
		
		if not exportFailed then (format "Time taken: % seconds\n" ((endStamp - startStamp)/1000.0) to:messageStream)
		messageBox (messageStream as string) title:"Batch Animation Exporter"
	)
	
	fn printNodeInfo useTag target tabCount =
	(
		tabs = ""
		for i = 1 to tabCount do (tabs += "\t")
		
		format "%Node Count: %\n\n" tabs useTag.metaIndex.nodes.count to:target
		for i = 1 to useTag.metaIndex.nodes.count do
		(
			format "%\tNode % (%)\n" tabs (i - 1) useTag.metaIndex.nodes[i].name to:target
			format "%\t\tNext Sibling: % (%)\n" tabs useTag.metaIndex.nodes[i].nextSiblingIndex (try (useTag.metaIndex.nodes[useTag.metaIndex.nodes[i].nextSiblingIndex + 1].name) catch ("null")) to:target
			format "%\t\tFirst Child: % (%)\n" tabs useTag.metaIndex.nodes[i].firstChildIndex (try (useTag.metaIndex.nodes[useTag.metaIndex.nodes[i].firstChildIndex + 1].name) catch ("null")) to:target
			format "%\t\tParent: % (%)\n\n" tabs useTag.metaIndex.nodes[i].parentIndex (try (useTag.metaIndex.nodes[useTag.metaIndex.nodes[i].parentIndex + 1].name) catch ("null")) to:target
		)
		format "\n" to:target
	)
	
	fn printAnimKeyOutput useTag animID target tabCount =
	(
		tabs = ""
		for i = 1 to tabCount do (tabs += "\t")
		
		useAnim = useTag.metaIndex.anims[animID]
		indexAnimRaw useAnim
		
		temp_animRotNodes = for i = 1 to useTag.metaIndex.nodes.count where useAnim.raw.animRotFlags[i] collect i
		temp_animTransNodes = for j = 1 to useTag.metaIndex.nodes.count where useAnim.raw.animTransFlags[j] collect j
		temp_animScaleNodes = for k = 1 to useTag.metaIndex.nodes.count where useAnim.raw.animScaleFlags[k] collect k
		
		if (useAnim.raw.animatedHeader.rotNodeCount > 0) then
		(
			longestLength = 0
			outputStrings = #()
			format "%Animated Rotation Key Info\n" tabs to:target
			for i = 1 to useAnim.raw.animatedHeader.rotNodeCount do
			(
				testStringStream = stringStream ""
				if ((temp_animRotNodes[i] - 1) > 9) then (padding = "")
				else (padding = " ")
				format "%\tNode %% (%)" tabs (temp_animRotNodes[i] - 1) padding useTag.metaIndex.nodes[temp_animRotNodes[i]].name to:testStringStream
				testString = testStringStream as string
				if (testString.count > longestLength) then (longestLength = testString.count)
				outputStrings[i] = testString
			)
			for j = 1 to useAnim.raw.animatedHeader.rotNodeCount do
			(
				spaces = ""
				for x = 1 to (longestLength - outputStrings[j].count + 1) do (spaces += " ")
				keyArray = #{}
				for y = 1 to useAnim.raw.animatedInfo.rotKeys[j].count do (keyArray[useAnim.raw.animatedInfo.rotKeys[j][y] + 1] = true)
				keyBinString = bitarrayToString keyArray useAnim.frameCount
				outputStrings[j] += (spaces + ": " + keyBinString)
				
				format "%\n" outputStrings[j] to:target
			)
		)
		
		if (useAnim.raw.animatedHeader.transNodeCount > 0) then
		(
			longestLength = 0
			outputStrings = #()
			format "%Animated Translation Key Info\n" tabs to:target
			for i = 1 to useAnim.raw.animatedHeader.transNodeCount do
			(
				testStringStream = stringStream ""
				if ((temp_animTransNodes[i] - 1) > 9) then (padding = "")
				else (padding = " ")
				format "%\tNode %% (%)" tabs (temp_animTransNodes[i] - 1) padding useTag.metaIndex.nodes[temp_animTransNodes[i]].name to:testStringStream
				testString = testStringStream as string
				if (testString.count > longestLength) then (longestLength = testString.count)
				outputStrings[i] = testString
			)
			for j = 1 to useAnim.raw.animatedHeader.transNodeCount do
			(
				spaces = ""
				for x = 1 to (longestLength - outputStrings[j].count + 1) do (spaces += " ")
				keyArray = #{}
				for y = 1 to useAnim.raw.animatedInfo.transKeys[j].count do (keyArray[useAnim.raw.animatedInfo.transKeys[j][y] + 1] = true)
				keyBinString = bitarrayToString keyArray useAnim.frameCount
				outputStrings[j] += (spaces + ": " + keyBinString)
				
				format "%\n" outputStrings[j] to:target
			)
		)
		
		if (useAnim.raw.animatedHeader.scaleNodeCount > 0) then
		(
			longestLength = 0
			outputStrings = #()
			format "%Animated Scale Key Info\n" tabs to:target
			for i = 1 to useAnim.raw.animatedHeader.scaleNodeCount do
			(
				testStringStream = stringStream ""
				if ((temp_animScaleNodes[i] - 1) > 9) then (padding = "")
				else (padding = " ")
				format "%\tNode %% (%)" tabs (temp_animScaleNodes[i] - 1) padding useTag.metaIndex.nodes[temp_animScaleNodes[i]].name to:testStringStream
				testString = testStringStream as string
				if (testString.count > longestLength) then (longestLength = testString.count)
				outputStrings[i] = testString
			)
			for j = 1 to useAnim.raw.animatedHeader.scaleNodeCount do
			(
				spaces = ""
				for x = 1 to (longestLength - outputStrings[j].count + 1) do (spaces += " ")
				keyArray = #{}
				for y = 1 to useAnim.raw.animatedInfo.scaleKeys[j].count do (keyArray[useAnim.raw.animatedInfo.scaleKeys[j][y] + 1] = true)
				keyBinString = bitarrayToString keyArray useAnim.frameCount
				outputStrings[j] += (spaces + ": " + keyBinString)
				
				format "%\n" outputStrings[j] to:target
			)
		)
	)
	
	fn printAnimInfo useTag animID incHeader incFrmInfo incStatHeader incStatInfo incAnimHeader incAnimInfo target tabCount =
	(
		tabs = ""
		for i = 1 to tabCount do (tabs += "\t")
		
		useAnim = useTag.metaIndex.anims[animID]
		indexAnimRaw useAnim
		
		if incHeader then
		(
			format "%Animation Name: %\n" tabs useAnim.name to:target
			format "%Type: %\n" tabs enumAnimationType[useAnim.type + 1] to:target
			format "%Frame Info Type: %\n" tabs enumFrameInfoType[useAnim.frameInfoType + 1] to:target
			format "%Frame Count: %\n" tabs useAnim.frameCount to:target
			format "%Flags: %\n" tabs (bitarrayToString useAnim.internalFlags 8) to:target
			format "%Static Node Flags: %\n" tabs useAnim.staticNodeFlags to:target
			format "%Animated Node Flags: %\n" tabs useAnim.animatedNodeFlags to:target
			format "%Movement Nodes: %\n" tabs useAnim.movementNodes to:target
			format "%Compressed Static Node Size: %\n" tabs useAnim.compressedStaticNodeSize to:target
			format "%Compressed Animated Node Size: %\n" tabs useAnim.compressedAnimatedNodeSize to:target
			format "%Raw Data Location Information Index: %\n" tabs useAnim.rawLocInfoIndex to:target
			format "%Raw Data Offset: %\n" tabs useAnim.rawAnimOffset to:target
			format "%Raw Data Location: %\n" tabs enumLocation[useAnim.rawAnimLocation + 1] to:target
			tabs += "\t"
		)
		if (incStatHeader and (useAnim.raw.staticHeader != undefined)) then
		(
			format "%Static Rotation Flags      : %\n" tabs (bitarrayToString useAnim.raw.statRotFlags useTag.metaIndex.nodes.count) to:target
			format "%Static Translation Flags   : %\n" tabs (bitarrayToString useAnim.raw.statTransFlags useTag.metaIndex.nodes.count) to:target
			format "%Static Scale Flags         : %\n" tabs (bitarrayToString useAnim.raw.statScaleFlags useTag.metaIndex.nodes.count) to:target
		)
		if (incAnimHeader and (useAnim.raw.animatedHeader != undefined)) then
		(
			format "%Animated Rotation Flags    : %\n" tabs (bitarrayToString useAnim.raw.animRotFlags useTag.metaIndex.nodes.count) to:target
			format "%Animated Translation Flags : %\n" tabs (bitarrayToString useAnim.raw.animTransFlags useTag.metaIndex.nodes.count) to:target
			format "%Animated Scale Flags       : %\n" tabs (bitarrayToString useAnim.raw.animScaleFlags useTag.metaIndex.nodes.count) to:target
		)
		temp_statRotNodes = for i = 1 to useTag.metaIndex.nodes.count where useAnim.raw.statRotFlags[i] collect i
		temp_statTransNodes = for j = 1 to useTag.metaIndex.nodes.count where useAnim.raw.statTransFlags[j] collect j
		temp_statScaleNodes = for k = 1 to useTag.metaIndex.nodes.count where useAnim.raw.statScaleFlags[k] collect k
		if (incStatHeader and (useAnim.raw.staticHeader != undefined)) then
		(
			format "%Static Rotation Node Count: %\n" tabs useAnim.raw.staticHeader.rotNodeCount to:target
			format "%Static Translation Node Count: %\n" tabs useAnim.raw.staticHeader.transNodeCount to:target
			format "%Static Scale Node Count: %\n" tabs useAnim.raw.staticHeader.scaleNodeCount to:target
			if (useAnim.raw.staticHeader.transInfoOffset != undefined) then (format "%Static Translation Offset: %\n" tabs useAnim.raw.staticHeader.transInfoOffset to:target)
			if (useAnim.raw.staticHeader.scaleInfoOffset != undefined) then (format "%Static Scale Offset: %\n" tabs useAnim.raw.staticHeader.scaleInfoOffset to:target)
		)
		temp_animRotNodes = for i = 1 to useTag.metaIndex.nodes.count where useAnim.raw.animRotFlags[i] collect i
		temp_animTransNodes = for j = 1 to useTag.metaIndex.nodes.count where useAnim.raw.animTransFlags[j] collect j
		temp_animScaleNodes = for k = 1 to useTag.metaIndex.nodes.count where useAnim.raw.animScaleFlags[k] collect k
		if (useAnim.raw.animatedHeader != undefined) then (codec = useAnim.raw.animatedHeader.codec)
		if (incAnimHeader and (useAnim.raw.animatedHeader != undefined)) then
		(
			format "%Animation Codec: %\n" tabs codec to:target
			format "%Animation Rate: %\n" tabs useAnim.raw.animatedHeader.animRate to:target
			format "%Animated Rotation Node Count: %\n" tabs useAnim.raw.animatedHeader.rotNodeCount to:target
			format "%Animated Translation Node Count: %\n" tabs useAnim.raw.animatedHeader.transNodeCount to:target
			format "%Animated Scale Node Count: %\n" tabs useAnim.raw.animatedHeader.scaleNodeCount to:target
			if (useAnim.raw.animatedHeader.rotInfoOffset != undefined) then (format "%Animated Rotation Info Offset: %\n" tabs useAnim.raw.animatedHeader.rotInfoOffset to:target)
			if (useAnim.raw.animatedHeader.transInfoOffset != undefined) then (format "%Animated Translation Info Offset: %\n" tabs useAnim.raw.animatedHeader.transInfoOffset to:target)
			if (useAnim.raw.animatedHeader.scaleInfoOffset != undefined) then (format "%Animated Scale Info Offset: %\n" tabs useAnim.raw.animatedHeader.scaleInfoOffset to:target)
			if (useAnim.raw.animatedHeader.unkOffset != undefined) then (format "%Animated Unknown Offset: %\n" tabs useAnim.raw.animatedHeader.unkOffset to:target)
			if (useAnim.raw.animatedHeader.rotKeysOffset != undefined) then (format "%Animated Rotation Keys Offset: %\n" tabs useAnim.raw.animatedHeader.rotKeysOffset to:target)
			if (useAnim.raw.animatedHeader.transKeysOffset != undefined) then (format "%Animated Translation Keys Offset: %\n" tabs useAnim.raw.animatedHeader.transKeysOffset to:target)
			if (useAnim.raw.animatedHeader.scaleKeysOffset != undefined) then (format "%Animated Scale Keys Offset: %\n" tabs useAnim.raw.animatedHeader.scaleKeysOffset to:target)
		)
		if (incStatInfo and (useAnim.raw.staticHeader != undefined)) then
		(
			if incStatHeader then (infoTabs = (tabs + "\t"))
			else (infoTabs = tabs)
			
			if (useAnim.raw.staticInfo.rot.count > 0) then
			(
				format "%Static Rotation Info\n" infoTabs to:target
				for i = 1 to useAnim.raw.staticInfo.rot.count do
				(
					format "%\tNode % (%)\n" infoTabs (temp_statRotNodes[i] - 1) useTag.metaIndex.nodes[temp_statRotNodes[i]].name to:target
					format "%\t\tRotation I: %\n" infoTabs useAnim.raw.staticInfo.rot[i].x to:target
					format "%\t\tRotation J: %\n" infoTabs useAnim.raw.staticInfo.rot[i].y to:target
					format "%\t\tRotation K: %\n" infoTabs useAnim.raw.staticInfo.rot[i].z to:target
					format "%\t\tRotation W: %\n" infoTabs useAnim.raw.staticInfo.rot[i].w to:target
				)
			)
			if (useAnim.raw.staticInfo.trans.count > 0) then
			(
				format "%Static Translation Info\n" infoTabs to:target
				for j = 1 to useAnim.raw.staticInfo.trans.count do
				(
					format "%\tNode % (%)\n" infoTabs (temp_statTransNodes[j] - 1) useTag.metaIndex.nodes[temp_statTransNodes[j]].name to:target
					format "%\t\tTranslation X: %\n" infoTabs useAnim.raw.staticInfo.trans[j].x to:target
					format "%\t\tTranslation Y: %\n" infoTabs useAnim.raw.staticInfo.trans[j].y to:target
					format "%\t\tTranslation Z: %\n" infoTabs useAnim.raw.staticInfo.trans[j].z to:target
				)
			)
			if (useAnim.raw.staticInfo.scale.count > 0) then
			(
				format "%Static Scale Info\n" infoTabs to:target
				for k = 1 to useAnim.raw.staticInfo.scale.count do
				(
					format "%\tNode % (%)\n" infoTabs (temp_statScaleNodes[k] - 1) useTag.metaIndex.nodes[temp_statScaleNodes[k]].name to:target
					format "%\t\tScale: %\n" infoTabs useAnim.raw.staticInfo.scale[k].x to:target
				)
			)
		)
		if (incAnimInfo and (useAnim.raw.animatedHeader != undefined)) then
		(
			if incAnimHeader then (infoTabs = (tabs + "\t"))
			else (infoTabs = tabs)
			
			if ((codec == 3) or (codec == 8)) then
			(
				if (useAnim.raw.animatedInfo.rot.count > 0) then
				(
					format "%Animated Rotation Info\n" infoTabs to:target
					for i = 1 to useAnim.raw.animatedInfo.rot.count do
					(
						format "%\tNode % (%)\n" infoTabs (temp_animRotNodes[i] - 1) useTag.metaIndex.nodes[temp_animRotNodes[i]].name to:target
						for j = 1 to useAnim.raw.animatedInfo.rot[i].count do
						(
							format "%\t\tFrame %\n" infoTabs (j - 1) to:target
							format "%\t\t\tRotation I: %\n" infoTabs useAnim.raw.animatedInfo.rot[i][j].x to:target
							format "%\t\t\tRotation J: %\n" infoTabs useAnim.raw.animatedInfo.rot[i][j].y to:target
							format "%\t\t\tRotation K: %\n" infoTabs useAnim.raw.animatedInfo.rot[i][j].z to:target
							format "%\t\t\tRotation W: %\n" infoTabs useAnim.raw.animatedInfo.rot[i][j].w to:target
						)
					)
				)
				if (useAnim.raw.animatedInfo.trans.count > 0) then
				(
					format "%Animated Translation Info\n" infoTabs to:target
					for i = 1 to useAnim.raw.animatedInfo.trans.count do
					(
						format "%\tNode % (%)\n" infoTabs (temp_animTransNodes[i] - 1) useTag.metaIndex.nodes[temp_animTransNodes[i]].name to:target
						for j = 1 to useAnim.raw.animatedInfo.trans[i].count do
						(
							format "%\t\tFrame %\n" infoTabs (j - 1) to:target
							format "%\t\t\tTranslation X: %\n" infoTabs useAnim.raw.animatedInfo.trans[i][j].x to:target
							format "%\t\t\tTranslation Y: %\n" infoTabs useAnim.raw.animatedInfo.trans[i][j].y to:target
							format "%\t\t\tTranslation Z: %\n" infoTabs useAnim.raw.animatedInfo.trans[i][j].z to:target
						)
					)
				)
				if (useAnim.raw.animatedInfo.scale.count > 0) then
				(
					format "%Animated Scale Info\n" infoTabs to:target
					for i = 1 to useAnim.raw.animatedInfo.scale.count do
					(
						format "%\tNode % (%)\n" infoTabs (temp_animScaleNodes[i] - 1) useTag.metaIndex.nodes[temp_animScaleNodes[i]].name to:target
						for j = 1 to useAnim.raw.animatedInfo.scale[i].count do
						(
							format "%\t\tFrame %\n" infoTabs (j - 1) to:target
							format "%\t\t\tScale: %\n" infoTabs useAnim.raw.animatedInfo.scale[i][j].x to:target
						)
					)
				)
			)
			if ((codec == 4) or (codec == 5) or (codec == 6) or (codec == 7)) then
			(
				printAnimKeyOutput useTag animID target infoTabs.count
				if (useAnim.raw.animatedInfo.rot.count > 0) then
				(
					format "%Animated Rotation Info\n" infoTabs to:target
					for i = 1 to useAnim.raw.animatedInfo.rot.count do
					(
						format "%\tNode % (%)\n" infoTabs (temp_animRotNodes[i] - 1) useTag.metaIndex.nodes[temp_animRotNodes[i]].name to:target
						for j = 1 to useAnim.raw.animatedInfo.rot[i].count do
						(
							format "%\t\tFrame %\n" infoTabs useAnim.raw.animatedInfo.rotKeys[i][j] to:target
							format "%\t\t\tRotation I: %\n" infoTabs useAnim.raw.animatedInfo.rot[i][j].x to:target
							format "%\t\t\tRotation J: %\n" infoTabs useAnim.raw.animatedInfo.rot[i][j].y to:target
							format "%\t\t\tRotation K: %\n" infoTabs useAnim.raw.animatedInfo.rot[i][j].z to:target
							format "%\t\t\tRotation W: %\n" infoTabs useAnim.raw.animatedInfo.rot[i][j].w to:target
						)
					)
				)
				if (useAnim.raw.animatedInfo.trans.count > 0) then
				(
					format "%Animated Translation Info\n" infoTabs to:target
					for i = 1 to useAnim.raw.animatedInfo.trans.count do
					(
						format "%\tNode % (%)\n" infoTabs (temp_animTransNodes[i] - 1) useTag.metaIndex.nodes[temp_animTransNodes[i]].name to:target
						for j = 1 to useAnim.raw.animatedInfo.trans[i].count do
						(
							format "%\t\tFrame %\n" infoTabs useAnim.raw.animatedInfo.transKeys[i][j] to:target
							format "%\t\t\tTranslation X: %\n" infoTabs useAnim.raw.animatedInfo.trans[i][j].x to:target
							format "%\t\t\tTranslation Y: %\n" infoTabs useAnim.raw.animatedInfo.trans[i][j].y to:target
							format "%\t\t\tTranslation Z: %\n" infoTabs useAnim.raw.animatedInfo.trans[i][j].z to:target
						)
					)
				)
				if (useAnim.raw.animatedInfo.scale.count > 0) then
				(
					format "%Animated Scale Info\n" infoTabs to:target
					for i = 1 to useAnim.raw.animatedInfo.scale.count do
					(
						format "%\tNode % (%)\n" infoTabs (temp_animScaleNodes[i] - 1) useTag.metaIndex.nodes[temp_animScaleNodes[i]].name to:target
						for j = 1 to useAnim.raw.animatedInfo.scale[i].count do
						(
							format "%\t\tFrame %\n" infoTabs useAnim.raw.animatedInfo.scaleKeys[i][j] to:target
							format "%\t\t\tScale: %\n" infoTabs useAnim.raw.animatedInfo.scale[i][j].x to:target
						)
					)
				)
			)
		)
		if (incFrmInfo and (useAnim.frameInfoType > 0)) then
		(
			format "%Frame Info\n" tabs to:target
			for i = 1 to useAnim.frameCount do
			(
				format "%\tFrame %\n" tabs (i - 1) to:target
				format "%\t\tdx   : %\n" tabs useAnim.raw.frameInfos[i].dx to:target
				format "%\t\tdy   : %\n" tabs useAnim.raw.frameInfos[i].dy to:target
				if (useAnim.frameInfoType == 3) then (format "%\t\tdz   : %\n" tabs useAnim.raw.frameInfos[i].dz to:target)
				if (useAnim.frameInfoType >= 2) then (format "%\t\tdyaw : % degrees\n" tabs useAnim.raw.frameInfos[i].dyaw to:target)
			)
		)
		format "\n" to:target
	)
	
	fn printAllAnimInfo useTag target tabCount =
	(
		tabs = ""
		for i = 1 to tabCount do (tabs += "\t")
		
		format "%Animation Count: %\n\n" tabs useTag.metaIndex.anims.count to:target
		for i = 1 to useTag.metaIndex.anims.count do (printAnimInfo useTag i true false true false true false target (tabCount + 1))
		format "\n" to:target
	)
	
	fn printRawLocInfo useTag target tabCount =
	(
		tabs = ""
		for i = 1 to tabCount do (tabs += "\t")
		
		format "%Raw Data Location Information Count: %\n\n" tabs useTag.metaIndex.rawLocInfos.count to:target
		for i = 1 to useTag.metaIndex.rawLocInfos.count do
		(
			format "%\tRaw Data Location Block %\n" tabs (i - 1) to:target
			format "%\t\tRaw Data Size: %\n" tabs useTag.metaIndex.rawLocInfos[i].size to:target
			format "%\t\tRaw Data Offset: %\n" tabs useTag.metaIndex.rawLocInfos[i].offset to:target
			format "%\t\tRaw Data Location: %\n\n" tabs enumLocation[useTag.metaIndex.rawLocInfos[i].location + 1] to:target
		)
		format "\n" to:target
	)
	
	on h2AnimTool open do
	(
		changeParamList ()
		tabStrip.tabs.add()
		tabStrip.tabs[1].caption = "Import Animation to Scene"
		tabStrip.tabs[2].caption = "Batch Animation Exporter"
		populateExportQueue ()
		adjustExportQueue ()
	)
	on h2AnimTool close do
	(
		try (fclose mapFile)
		catch ()
		try (fclose sharedFile)
		catch ()
		try (fclose spSharedFile)
		catch ()
		try (fclose mainmenuFile)
		catch ()
	)
	on tags_list selected item do (loadTag (getSelectedTag ()))
	on imp_animList selected item do
	(
		selTag = getSelectedTag ()
		selAnim = selTag.metaIndex.anims[item]
		loadAnim selAnim
	)
	on map_sel pressed do (selMap ())
	on map_clr pressed do (clrMap ())
	on btc_locs_origSel pressed do (selOrigScn ())
	on btc_locs_origClr pressed do (clrOrigScn ())
	on btc_locs_saveSel pressed do (selSaveDir ())
	on btc_locs_saveClr pressed do (clrSaveDir ())
	on minimize pressed do (minimizeToggle ())
	on tagsDbg_prntJmad pressed do
	(
		selTag = getSelectedTag ()
		jmadInfoStream = newScript ()
		format "%\n\n" selTag.path to:jmadInfoStream
		if tagsDbg_prntJmad_node.checked then (printNodeInfo selTag jmadInfoStream 0)
		if tagsDbg_prntJmad_anim.checked then (printAllAnimInfo selTag jmadInfoStream 0)
		if tagsDbg_prntJmad_raw.checked then (printRawLocInfo selTag jmadInfoStream 0)
	)
	on impDbg_prntAnim pressed do
	(
		selTag = getSelectedTag ()
		incHeader = impDbg_prntAnim_head.checked
		incFrmInfo = impDbg_prntAnim_frm.checked
		incStatHeader = impDbg_prntAnim_head.checked
		incStatInfo = impDbg_prntAnim_stat.checked
		incAnimHeader = impDbg_prntAnim_head.checked
		incAnimInfo = impDbg_prntAnim_anim.checked
		animInfoStream = newScript ()
		printAnimInfo selTag imp_animList.selection incHeader incFrmInfo incStatHeader incStatInfo incAnimHeader incAnimInfo animInfoStream 0
	)
	on tagsDbgNodeList_save pressed do
	(
		selTag = getSelectedTag ()
		exportNodeList selTag
	)
	on tagsDbgNodeList_sync pressed do
	(
		selTag = getSelectedTag ()
		syncNodeList selTag
	)
	on impNodeStates_save pressed do
	(
		selTag = getSelectedTag ()
		exportNodeStates selTag imp_animList.selection
	)
	on impNodeStates_sync pressed do
	(
		selTag = getSelectedTag ()
		syncNodeStates selTag imp_animList.selection
	)
	on tabStrip click do (changeParamList ())
	on btc_exportQueue itemCheck item do
	(
		adjustExportItem item
		adjustExportQueue ()
	)
	on btc_exportCmds_chkAll pressed do
	(
		for i in btc_exportQueue.listItems do
		(
			i.checked = true
			adjustExportItem i
		)
		adjustExportQueue ()
	)
	on btc_exportCmds_uncAll pressed do
	(
		for i in btc_exportQueue.listItems do
		(
			i.checked = false
			adjustExportItem i
		)
		adjustExportQueue ()
	)
	on btc_exportCmds_chkSel pressed do
	(
		for i in btc_exportQueue.listItems where i.selected do
		(
			i.checked = true
			adjustExportItem i
		)
		adjustExportQueue ()
	)
	on btc_exportCmds_uncSel pressed do
	(
		for i in btc_exportQueue.listItems where i.selected do
		(
			i.checked = false
			adjustExportItem i
		)
		adjustExportQueue ()
	)
	on btc_exportCmds_filterText changed textString do (populateExportQueueItems ())
	on imp_importAnim pressed do
	(
		selTag = getSelectedTag ()
		disableSceneRedraw ()
		importAnimToScene selTag imp_animList.selection impParams_stFrm.value impParams_frmInfo.checked
		enableSceneRedraw ()
	)
	on btc_exportAnims pressed do (batchExportAnims ())
)

createDialog h2AnimTool