#Include "JAVstudios.isf"
; #include <Array.au3>

;~ Global Const $gsRegBase = "HKEY_CURRENT_USER\Software\Stash_Helper"
Global $gaJAVStudioData[0][2]

;~ JavStudios()

Func JavStudios()
	GetJAVStudioData()
	Global $mguiJAV = _JAVstudios()
	_GUICtrlListView_AddArray($mguiJAV.lstStudios, $gaJAVStudioData)
	$mguiJAV["list_pos"] = ControlGetPos($mguiJAV.JAVstudios, "", $mguiJAV.lstStudios)

	; GUI: JAVstudios, list: lstStudios, button: btnOK,btnCancel,btnPlus,btnMinus,btnSet
	; input: inpStudio, inpFragment
	GUISetState(@SW_SHOW, $mguiJAV.JAVstudios)
	While True
		$aMsg = GUIGetMsg(1)	; Get Advance message
		Switch $aMsg[0]
			Case 0, -7, -11
				ContinueLoop 
			
			Case $mguiJAV.btnOK
				SetJAVStudioData()
				ExitLoop

			Case $mguiJAV.btnCancel, $GUI_EVENT_CLOSE
				ExitLoop 
				
			Case $mguiJAV.btnPlus
				$sFragment =  GUICtrlRead($mguiJAV.inpFragment)
				$sStudio = GUICtrlRead($mguiJAV.inpStudio)
				If $sFragment = "" or $sStudio = "" Then 
					MsgBox(266288,"Set Fragment and Studio","You need to set the value for both Fragment and Studio.",0)
					ContinueLoop 
				EndIf
				
				$i = _GUICtrlListView_AddItem($mguiJAV.lstStudios, $sFragment)
				_GUICtrlListView_SetItem($mguiJAV.lstStudios, $sStudio, $i, 1 )

			Case $mguiJAV.btnMinus
				$sSelectRow = _GUICtrlListView_GetSelectedIndices($mguiJAV.lstStudios )
				If $sSelectRow = "" Then
					MsgBox(266288,"Select A Row","You need to select a row first.",0)
					ContinueLoop
				EndIf 
					
				$iReply = MsgBox(266276,"Are You Sure?","Are you sure to delete this row?",0)
				If $iReply = 7 Then ContinueLoop 
				
				_GUICtrlListView_DeleteItemsSelected($mguiJAV.lstStudios)
				
			Case $mguiJAV.btnSet
				$sSelectRow = _GUICtrlListView_GetSelectedIndices($mguiJAV.lstStudios )
				$sFragment =  GUICtrlRead($mguiJAV.inpFragment)
				$sStudio = GUICtrlRead($mguiJAV.inpStudio)
				
				If $sSelectRow = "" Then
					MsgBox(266288,"Select A Row","You need to select a row first.",0)
					ContinueLoop
				ElseIf $sFragment = "" or $sStudio = "" Then 
					MsgBox(266288,"Set Fragment and Studio","You need to set the value for Fragment and Studio.",0)
					ContinueLoop 
				EndIf
				; c("set data, fragment:" & $sFragment & " studio:" & $sStudio & " row:" & $sSelectRow)
				_GUICtrlListView_SetItem($mguiJAV.lstStudios, $sFragment, Int($sSelectRow))
				_GUICtrlListView_SetItem($mguiJAV.lstStudios, $sStudio, Int($sSelectRow), 1)
				
			Case $mguiJAV.lstStudios
				; c("header clicked")

			Case $GUI_EVENT_PRIMARYUP
				; Use mouse down event to presume the list is clicked.
				if $aMsg[3] > $mguiJAV.list_pos[0] _ 
					and $aMsg[3] < $mguiJAV.list_pos[0] + $mguiJAV.list_pos[2] _
					and $aMsg[4] > $mguiJAV.list_pos[1] _
					and $aMsg[4] < $mguiJAV.list_pos[1] + $mguiJAV.list_pos[3] Then
					CheckListSelect()
				EndIf
				
			Case Else
				c("others:" & $aMsg[0])
		EndSwitch
	Wend

	GUIDelete($mguiJAV.JavStudios)
EndFunc

Func GetJAVStudioData()
	; Get data from registry for $gaJAVStudios
	$sCodes = RegRead($gsRegBase, "JAVStudioCodes")
	If @error Then 
		$sCodes = "dsvr,13DSVR|tmavr,55TMAVR|vosm,h_1127vosm|fsvss,1fsvss|vosf,h_1127vosf|nhvr,1nhvr|kiwvr,h_1248kiwvr|prdvr,118prdvr|vrtb,h_1423vrtb|sepvr,h_1285sepvr|fsvr,h_955fsvr|kmvr,84kmvr|dtvr,24dtvr|mivr,h_1145mivr|vrtb,h_1423vrtb|gopj,h_1127gopj|spivr,h_1609spivr|ocvr,h_1358ocvr|crvr,h_1155crvr|pydvr,h_1321pydvr|exvr,84exvr|pipivr,1pipivr|dibvr,504dibvr|cbikmv,h_1285cbikmv|bzvr,84bzvr|tmvr,h_1285tmvr|wpvr,2wpvr"
	EndIf 

	Local $aItems = StringSplit($sCodes, "|", 2) ; No count
	Global $gaJAVStudioData[UBound($aItems)][2]
	For $i = 0 to UBound($aItems)-1
		$aData = StringSplit($aItems[$i], ",", 2)
		$gaJAVStudioData[$i][0] = $aData[0]
		$gaJAVStudioData[$i][1] = $aData[1]
	Next

EndFunc

Func SetJAVStudioData()
	; Set the data in registry from the list
	Global $gaJAVStudioData[0][0]
	$iCount = _GUICtrlListView_GetItemCount($mguiJAV.lstStudios)
	If $iCount = 0 Then Return

	$sData = ""
	For $i = 0 to $iCount-1
		$sFragment = _GUICtrlListView_GetItemText( $mguiJAV.lstStudios, $i, 0)
		$sStudio = _GUICtrlListView_GetItemText( $mguiJAV.lstStudios, $i, 1)
		c("Fragment:" & $sFragment & " studio:" & $sStudio)
		Redim $gaJAVStudioData[$i+1][2]
		$gaJAVStudioData[$i][0] = $sFragment
		$gaJAVStudioData[$i][1] = $sStudio
		If $sData = "" Then
			$sData = $sFragment & "," & $sStudio
		Else
			$sData &= "|" & $sFragment & "," & $sStudio
		EndIf
	Next
	RegWrite( $gsRegBase, "JAVStudioCodes", "REG_SZ", $sData)
EndFunc

Func CheckListSelect()
	Static $row
	$sSelectRow = _GUICtrlListView_GetSelectedIndices($mguiJAV.lstStudios )
	If $sSelectRow = "" or $sSelectRow = $row Then Return
	; Now set the value
	$aData = _GUICtrlListView_GetItemTextArray($mguiJAV.lstStudios)
	if $aData[0] = 0 Then Return
	GUICtrlSetData($mguiJAV.inpFragment, $aData[1])
	GUICtrlSetData($mguiJAV.inpStudio, $aData[2])
	$row = $sSelectRow
EndFunc

;~ Func c($str)
;~ 	ConsoleWrite($str & @CRLF)
;~ EndFunc

