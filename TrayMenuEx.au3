; FILE:           TrayMenuEx.au3
; VESION:         1.0.0
; LAST EDIT:      30 Mar 2006
; PURPOSE:        Provide udf's to extend TrayMenu functionality.
;                 Image support is implemented
;
; RESOURCES:  Scopinho: http://www.autoitscript.com/forum/index.php?showtopic=20798&hl=AddImageToMenu
; RESOURCES:  MSDN:     http://msdn.microsoft.com/library/default.asp?url=/library/en-us/dnwui/html/msdn_icons.asp
; CREATED BY: Uten:     http://www.autoitscript.com/forum/index.php?showuser=7836
; TODO:
; ---------------------------------------------------------------------
; * Add support to get the icon viewed in explorer for any exe.
; ---------------------------------------------------------------------
; CHANGE LOG:
; ---------------------------------------------------------------------
; uten   30 Mar 2006   First release.
; ---------------------------------------------------------------------
#cs - User calltip entries: Tools->User calltip entries
_LoadImage($imagePathName, $imageType) Returns handel to image in memory. Load image from a image file (bmp, ico). Set $imageType as $IMAGE_BITMAP=0 or $IMAGE_ICON=1
_TrayMenuAddIcon(ByRef $hIcon, $TrayMenuNr[, $ParentMenu = 0[, $IndexType = 0x00000400]] ) Add, bitmap in, icon to a tray item. $hIco: Handel to icon in memory. $TrayMenuNr: TrayItems index nr in menu.First item is 0. $ParentMenu: controlID returned by TrayCreateMenu. $IndexType: $MF_BYPOSITION | $MF_BYCOMMAND Changes behaviour of $TrayMenuNr
_TrayMenuAddImage( ByRef $hBmp, $MenuIndex[, $ParentMenu = 0[, $IndexType = 0x00000400]] )Add bitmap to a tray item. $hBmp: Handel to bitmap in memory. $TrayMenuNr: TrayItems index nr in menu.First item is 0. $ParentMenu: controlID returned by TrayCreateMenu. $IndexType: $MF_BYPOSITION | $MF_BYCOMMAND Changes behaviour of $TrayMenuNr
_IconExtractFromFile($szIconFile, $iconID) Extract icon from file. $szIconFile: PathName to file (dll or exe) containing the icon. $iconID: Resource reference in the file.
_IconDestroy(ByRef $hIcon) Destroy icon in memory. $hIcon may be a array of handels. Could be called after the icon has been pased on to menuItem.
_IconGetInfo( ByRef $hIcon, ByRef $structICONINFO) $hIcon: Handel to icon in memory. $structICONINFO: A array resembeling the ICONSTRUCT structure. item 5 is a handel to the bitmap.
_GetMenuItemID($hMenu, $itemRelativePos) Returns itemID of a item in menu $hMenu with relative pos $itemRelativePos.
#ce

#include <GUIConstants.au3>
#include-once

; ---------------------------------------------------------------------
;Global Const $MF_BYCOMMAND = 0x00000000  ; In <GUIConstants.au3>
;Global Const $MF_BYPOSITION = 0x00000400 ; In <GUIConstants.au3>
Global Const $IMAGE_BITMAP = 0
Global Const $IMAGE_ICON = 1

Global Const $LR_LOADMAP3DCOLORS = 0x00001000
Global Const $LR_LOADFROMFILE = 0x0010
;
Global Const $Debug = 1
Global Const $ModuleName = "TrayMenuEx.au3"
; ---------------------------------------------------------------------
#cs TEST CODE:

_Main()
Func _Main()
	Opt("TrayMenuMode", 1) ; Don't show the default tray context menu
	local $autoitIcons="C:\Program Files (x86)" & "\Autoit3\icons\"
	local $bmpPathName = "c:\temp\test.bmp"
	local $IExplorerPath = "c:\program files\internet explorer\iexplorer.exe"
	local $TMControlIDs[8], $hImg[8]
	; Create a menu structure
	$TMControlIDs[0] = TrayCreateMenu("Options")
	$TMControlIDs[1] = TrayCreateItem("Opt1",$TMControlIDs[0])
	$TMControlIDs[2] = TrayCreateItem("Opt2",$TMControlIDs[0])
	$TMControlIDs[3] = TrayCreateItem("")

	$TMControlIDs[4] = TrayCreateItem("Test1")
	$TMControlIDs[5] = TrayCreateItem("IExplorer")
	$TMControlIDs[6] = TrayCreateItem("")
	$TMControlIDs[7] = TrayCreateItem("Exit")
	; Add some icons

	$hImg[0] = _IconExtractFromFile("shell32.dll", 15)	; Computer icon in dll
	$hImg[1] = _LoadImage($autoitIcons & "MyAutoIt3_Blue.ico", $IMAGE_ICON)
	$hImg[2] = _LoadImage($autoitIcons & "MyAutoIt3_Green.ico", $IMAGE_ICON)
	$hImg[4] = _IconExtractFromFile(@AutoItExe, 0) ; This does not work for all files (ex:firefox). Even if the item reference is correct
	$hImg[5] = _IconExtractFromFile($IExplorerPath, 32528)
	$hImg[7] = _LoadImage($bmpPathName, $IMAGE_BITMAP)

	_TrayMenuAddIcon($hImg[0], 0)                  ; CReate a submenu
	_TrayMenuAddIcon($hImg[1], 0,$TMControlIDs[0]) ; First item on the sub menu
	_TrayMenuAddIcon($hImg[2], 1,$TMControlIDs[0]) ; Second on sub menu
	;_TrayMenuAddIcon($hImg[3], 1)                 ; Seperator, between submenu and root
	_TrayMenuAddIcon($hImg[4], 2)                  ; Test1, expect Autoit icon
	_TrayMenuAddIcon($hImg[5], 3)                 ; IExplorer
	;_TrayMenuAddIcon($hImg[6], 4)                 ; Seperator
	_TrayMenuAddImage($hImg[7], 5)                  ; Exit, expect blue bmp

	TraySetState()
	; We can destroy the icon references after it has been loaded by the TrayItem
	_IconDestroy($hImg) ;Destroys handel or array of handels

	local $msg, $TrayMsg
	While 1
		if TrayGetMsg()= $TMControlIDs[7] then Exit
		$msg = GUIGetMsg()
		switch $msg
			case $GUI_EVENT_CLOSE
				exit
			case Else
				If $msg = 0 Then
					;sleep(250)
				Else
					if $debug then ConsoleWrite("MSG LOOP: $msg:=" & $msg & @LF)
				EndIf
		EndSwitch

	WEnd

EndFunc ;==>_Main
#ce
; ---------------------------------------------------------------------
Func _LoadImage($imagePathName, $imageType)
	; $imageType=[$IMAGE_BITMAP|$IMAGE_ICON]
	; Loads image to memory, returns pointer
	If $Debug AND Not FileExists($imagePathName) Then ConsoleWrite($ModuleName & _
					" ERROR: _LoadImage($imagePathName:=" & _
					$imagePathName & ", $imageType:="& $imageType & _
					") File does not exist" & @LF)
	Local $hRet = DllCall("user32.dll", "hwnd", "LoadImage", "hwnd", 0, _
												           "str", $imagePathName, _
												           "int", $imageType, _
												           "int", 0, _
												           "int", 0, _
												           "int", BitOR($LR_LOADFROMFILE, $LR_LOADMAP3DCOLORS))
	; TODO: Consider LR_LOADTRANSPARENT, LR_SHARED
	if $Debug AND $hRet[0] = 0 Then ConsoleWrite($ModuleName & _
					" ERROR: _LoadImage($imagePathName:=" & _
					$imagePathName & ", $imageType:="& $imageType & _
					") Did not return img handel." & @LF)
	$hRet = $hRet[0]
	Return $hRet
EndFunc

Func _TrayMenuAddIcon(ByRef $hIcon, $TrayMenuNr, $ParentMenu = 0, $IndexType = 0x00000400 ); $MF_POSITION=0x00000400
	dim $pIcoInfo, $hBmp
	If _IconGetInfo($hIcon, $pIcoInfo) <> 0 Then
		; Get a handel to the bmp in the icon def.
		$hBmp = DllStructGetData($pIcoInfo,5)
		_TrayMenuAddImage($hBmp, $TrayMenuNr, $ParentMenu, $IndexType)
		$pIcoInfo = 0
	Else
		If $Debug Then ConsoleWrite($ModuleName & " ERROR: In _TrayMenuAddIcon($hIcon:=" & $hIcon & _
				", $TrayMenuNr:=" & $TrayMenuNr _
				& ") Call to _GetIconInfo Trying to use $hIcon as bmp handel" &  @LF)
		_TrayMenuAddImage($hIcon, $TrayMenuNr, $ParentMenu, $IndexType)
	EndIf
EndFunc ; ==>_TrayMenuAddIcon

Func _TrayMenuAddImage( ByRef $hBmp, $MenuIndex, $ParentMenu = 0, $IndexType = 0x00000400 ); $MF_POSITION=0x00000400
	if $Debug Then ConsoleWrite("_TrayMenuAddIcon( $hBmp:=" & $hBmp & ", $MenuIndex:=" & _
					$MenuIndex & ", $ParentMenu:=" & $ParentMenu & ", $IndexType:=" & $IndexType &" )" & @LF)
	local $ret = DllCall("user32.dll", "int", "SetMenuItemBitmaps", "hwnd", TrayItemGetHandle($ParentMenu), _
                                                       "int",  $MenuIndex, _
													   "int",  $IndexType, _
													   "hwnd", $hBmp, _
													   "hwnd", $hBmp)
EndFunc ; ==>_TrayMenuAddImage

Func _IconExtractFromFile($szIconFile, $iconID)
	; TODO: This will not extract icons (as in a embeded resource) from a normal exe.
    Local $hIcon = DllStructCreate("int")
	;PROTO: UINT ExtractIconEx(LPCTSTR lpszFile, int nIconIndex, HICON *phiconLarge, HICON *phiconSmall, UINT nIcons);
    Local $result = DllCall("shell32.dll", "hwnd", "ExtractIconEx", "str", $szIconFile, "int", $iconID, "hwnd", 0, "ptr", DllStructGetPtr($hIcon), "int", 1)
    ;TODO: Do we have to make shure some cleanup is done? Or will the memory bee freed when Autoit terminates
	$ret = DllStructGetData($hIcon,1)
    Return $ret
EndFunc ; ==> _IconExtractFromFile

Func _IconDestroy(ByRef $hIcon)
	if IsArray($hIcon) Then
		local $i
		For $i = 0 to UBound($hIcon) - 1
			DllCall("user32.dll", "int", "DestroyIcon", "hwnd", DllStructGetPtr($hIcon[$i]))
		Next
	else
		DllCall("user32.dll", "int", "DestroyIcon", "hwnd", DllStructGetPtr($hIcon))
	EndIf
EndFunc ; ==>_IconDestroy

Func _IconGetInfo( ByRef $hIcon, ByRef $structICONINFO)
	local $def = "int; dword; dword; ptr; ptr"
	$structICONINFO = DllStructCreate($def)
	; PROTO: BOOL GetIconInfo( HICON hIcon, PICONINFO piconinfo);
	Local $ret = DllCall("user32.dll", "long", "GetIconInfo","ptr", $hIcon, "ptr", DllStructGetPtr($structICONINFO))
	if $Debug AND @error <> 0 then ConsoleWrite( $ModuleName & "_IconGetInfo: @ERROR:=" & @error & @CRLF & _
			"@ERROR:=1 > unable to use the DLL file: user32.dll" & @CRLF & _
			"@ERROR:=2 > unknown return type"  & @CRLF & _
			"@ERROR:=3 > function: GetIconInfo not found in user32.dll" & @LF)
	; 0 Is failure andything else is success.
	return $ret[0]
EndFunc ; ==> _IconGEtInfo

Func _GetMenuItemID($hMenu, $itemRelativePos)
	;PROTO: UINT GetMenuItemID( HMENU hMenu, int nPos);
	local $ret = dllcall("", "int", "GetMenuItemID","hwnd", $hMenu, "int", $itemRelativePos)
	Return $ret[0]
EndFunc
; ---------------------------------------------------------------------