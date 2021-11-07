; -- Created with ISN Form Studio 2 for ISN AutoIt Studio -- ;
#include <StaticConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#Include <GuiButton.au3>
; #include <Array.au3>
#include <..\GUIListViewEx.au3>
Global $customList

Func CustomList($sCategory, ByRef $aCategory)
	; sCategory is "Scenes","Movies"...
	; aCategory is the array that contains Item_Handle, Item_Title, Item_Link
	; Global Enum $ITEM_HANDLE, $ITEM_TITLE, $ITEM_LINK
	; Global $iMaxSubItems


	; Disable the tray clicks
	TraySetClick(0)
		
	$guiCustom = GUICreate("Customize " & $sCategory,1060,1126,-1,-1,-1,-1)
	GUISetIcon("helper2.ico")
	
	GUICtrlCreateLabel("Customize the list of " & $sCategory & _ 
	  ". This is like bookmarks or favorites for Stash. You paste the link from the address bar, then put a title for it, as the examples you see below." _ 
		  &@crlf&"To edit the list, double-click on the item, type or paste the text then press enter.",80,50,882,196,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	
	$customList = GUICtrlCreatelistview("#|  Title|  Query Link",40,270,972,696, _ 
		BitOR($LVS_NOSCROLL, $LVS_SINGLESEL), _ 
		BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	; #
	_GUICtrlListView_SetColumnWidth($customList, 0, 50)
	; Title
	_GUICtrlListView_SetColumnWidth($customList, 1, 300)
	; _GUICtrlListView_JustifyColumn($customList, 1, 2)
	; Query Link
	_GUICtrlListView_SetColumnWidth($customList, 2, 700)
	; _GUICtrlListView_JustifyColumn($customList, 2, 2)
	
	$btnSave = GUICtrlCreateButton("Save",773,993,238,47,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Save the list and apply the changes.")
	$btnDelete = GUICtrlCreateButton("Delete",47,993,238,47,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Delete the highlighted row.")
	
	Local $aList[$iMaxSubItems]
	For $i = 0 to $iMaxSubItems -1
		; Popular all numbers anyway
		$aList[$i] = String($i + 1)
	Next
	For $i = 0 to UBound($aCategory) -1
		$aList[$i] &= "|" & $aCategory[$i][$ITEM_TITLE] & "|" & $aCategory[$i][$ITEM_LINK]
	Next
	
	For $i = 0 to $iMaxSubItems -1
		_GUICtrlListView_AddItem($customList, $i + 1)
	Next
	
	; Populate the list view
	; Local $aListHandles[$iMaxSubItems][2]
	For $i = 0 to UBound($aCategory) -1
		_GUICtrlListView_AddSubItem($customList, $i, $aCategory[$i][$ITEM_TITLE], 1)
		_GUICtrlListView_AddSubItem($customList, $i, $aCategory[$i][$ITEM_LINK], 2)
	Next

	GUISetState(@SW_SHOW, $guiCustom)
	; Make list view editable
	$iLV_Index = _GUIListViewEx_Init($customList, $aList, 0, 0, True, 2)
	_GUIListViewEx_SetEditStatus($iLV_Index, "1;2", 1, Default)
	_GUIListViewEx_MsgRegister(True, False, False)
	
	; Now do the loop
	While True
		; if click on tray icon, activate the current GUI
		$nTrayMsg = TrayGetMsg()
		Switch $nTrayMsg
			Case $TRAY_EVENT_PRIMARYDOWN, $TRAY_EVENT_SECONDARYDOWN
				WinActivate($guiCustom)
 		EndSwitch 

		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case 0
				; Nothing should be here.
			Case $customList
				; ConsoleWrite("here" & @CRLF)
			Case $btnSave
				$aRead =  _GUIListViewEx_ReturnArray($iLV_Index)
				; _ArrayDisplay($aRead)
				Local $str = $aRead[0]
				For $i = 1 to $iMaxSubItems-1
					$str &= "@@@" & $aRead[$i]
				Next
				RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", $sCategory & "List", "REG_SZ", $str)
				; Need to load the Items here.
				ReloadMenu($sCategory)
				ExitLoop
			Case $btnDelete
				If _GUICtrlListView_GetSelectedCount($customList) = 0 Then 
					MsgBox(0, "No item is selected", "Please select a row first.")
					ContinueLoop 
				EndIf
				; Now $iRow is the one needs to be deleted.
				_GUIListViewEx_SetActive($iLV_Index)
				; Delete the selected one.
				_GUIListViewEx_Delete()
				; Insert an empty row at the end
				_GUIListViewEx_InsertSpec($iLV_Index, -1, "")
				; Unselect it.
				_GUICtrlListView_SetItemSelected ($customList, $iMaxSubItems-1, False )
				; Repopulate the leading numbers.
				; Local $aList[$iMaxSubItems]
				For $i = 0 to $iMaxSubItems -1
					; Set the # 1,2,3,4...
					_GUICtrlListView_SetItemText($customList, $i, $i + 1)
				Next
				
			Case $GUI_EVENT_CLOSE
				ExitLoop 
		EndSwitch
		
		_GUIListViewEx_EventMonitor()
	Wend
	_GUIListViewEx_Close($iLV_Index)
	GUIDelete($guiCustom)
	$customList = 0
	; restore the tray icon functions.
	TraySetClick(9)
EndFunc

