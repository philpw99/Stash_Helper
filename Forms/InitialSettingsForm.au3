;InitialSettingsForm.au3
#include <StaticConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#Include <GuiButton.au3>
#include <GuiTab.au3>
#include <EditConstants.au3>

Func InitialSettingsForm()
	Global $stashFilePath
	Local $Initial_Settings, $tab, $stashPath, $btnBrowse, $btnOK

	If Not (@Compiled ) Then DllCall("User32.dll","bool","SetProcessDPIAware")
	
	; Create the whole initial setting's GUI
	$Initial_Settings = GUICreate("Initial Settings",1326,809,-1,-1,-1,-1)
	$tab = GUICtrlCreatetab(41,70,1232,661,-1,-1)
	GuiCtrlSetState(-1,2048)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")

	; Tab 1
	GUICtrlCreateTabItem("  Start  ")

	GUICtrlCreateLabel("Welcome to my little GUI helper for Stash!",191,158,908,62,-1,-1)
	GUICtrlSetFont(-1,20,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")

	GUICtrlCreateLabel("StashApp is a great program to manage your porn collection. This little helper will make it easier to run in Windows."&@crlf&"Please start it by tell me where 'stash-win.exe' is.",167,244,937,111,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")

	$stashPath = GUICtrlCreateInput("",280,391,610,41,-1,$WS_EX_CLIENTEDGE)
	GUICtrlSetState(-1,BitOr($GUI_SHOW,$GUI_ENABLE))
	GUICtrlSetFont(-1,10,400,0,"Palatino Linotype")

	$btnBrowse = GUICtrlCreateButton("Browse",910,391,170,41,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Palatino Linotype")
	GUICtrlCreateLabel("If you don't have it yet, you can download it here.",283,470,615,49,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")

	$btnWebsite = GUICtrlCreateButton("Website",910,470,170,41,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Palatino Linotype")

	; Tab 2
	GUICtrlCreateTabItem(" Choose Browser ")

	GUICtrlCreateLabel("Now choose your favorite browser to launch StashApp.",361,150,616,104,-1,-1)
	GUICtrlSetFont(-1,16,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")

	$chooseFirefox = GUICtrlCreateRadio("Firefox",201,286,157,48,$BS_AUTORADIOBUTTON,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")

	$chooseChrome = GUICtrlCreateRadio("Chrome",201,348,157,48,$BS_AUTORADIOBUTTON,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")

	$chooseEdge = GUICtrlCreateRadio("MS Edge",201,415,157,48,$BS_AUTORADIOBUTTON,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")

	$browserDetails = GUICtrlCreateLabel("",451,300,656,163,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")
	; The frame for the details
	GUICtrlCreateLabel("",406,270,741,235,$SS_GRAYFRAME,-1) 
	GUICtrlSetBkColor(-1,"-2")

	; Tab 3
	GUICtrlCreateTabItem("  Launch!  ")

	GUICtrlCreateLabel("Thank you ! Now it's all ready to launch StashApp.",331,160,547,109,-1,-1)
	GUICtrlSetFont(-1,16,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")

	GUICtrlCreateLabel("Note: If this is the first time you run StashApp, it will ask you a question about where to store the config file. Since this is windows, you should choose -> 'In the current working directory.'"&@crlf&""&@crlf&"*** After you finish the wizard, you should click on 'Tasks' then 'Scan' to get your files recognized by Stash."&@crlf&"No movies? No Studio and Performers? No problem. This program will help you along the way.",201,290,895,307,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")

	; For all tabs
	GUICtrlCreateTabItem("")
	$btnNext = GUICtrlCreateButton("Next",960,630,211,57,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Palatino Linotype")
	GUICtrlSetState(-1,BitOr($GUI_SHOW,$GUI_DISABLE))
	; Back to tab 0
	_GUICtrlTab_SetCurFocus($tab,0)


	; Now run the rest
	GUISetState(@SW_SHOW, $Initial_Settings)
	Local $bSettingDone = False, $iSecond = @SEC
	Local $bPathReady = False , $bBrowserReady = False, $sBrowser
	While Not $bSettingDone
		Sleep(10)
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $btnBrowse
				Local $sFile = FileOpenDialog("Open the Stash-Win.exe:", _ 
					@DocumentsCommonDir, "(Stash-Win.exe)", $FD_FILEMUSTEXIST )
				If Not @error Then
					GUICtrlSetData($stashPath, $sFile)
				EndIf
			Case $btnNext
				Switch _GUICtrlTab_GetCurFocus($tab)
					Case 0 ; Tab start
						_GUICtrlTab_SetCurFocus($tab, 1)
					Case 1 ; Tab Browser
						_GUICtrlTab_SetCurFocus($tab, 2)
					Case 2 ; Tab Launch
						If $bPathReady And $bBrowserReady Then 
							RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", "StashFilePath", "REG_SZ", $stashFilePath)
							RegWrite("HKEY_CURRENT_USER\Software\Stash_Helper", "Browser", "REG_SZ", $sBrowser)
							$bSettingDone = True
							
							MsgBox(64,"Very Good !", _ 
							"Thank you! Now stash will run and this helper will reside in the notification tray area, where the clock and other small icons are.",0)

							ExitLoop 
						EndIf
				EndSwitch
				
			Case $btnWebsite
				ShellExecute("https://github.com/stashapp/stash/releases")
			Case $GUI_EVENT_CLOSE
				Exit 
		EndSwitch
		
		If $iSecond <> @SEC Then 
			$iSecond = @SEC
			; Check every second.
			Switch _GUICtrlTab_GetCurFocus($tab)
				Case 0	; Currently at Tab 0, Start
					GUICtrlSetData($btnNext, "Next")
					$stashFilePath = GUICtrlRead($stashPath)
					If StringLower(StringRight($stashFilePath, 13)) = "stash-win.exe" _ 
						And FileExists($stashFilePath) Then 
						GUICtrlSetState($btnNext, $GUI_ENABLE)
						$bPathReady = True 
					Else
						GUICtrlSetState($btnNext, $GUI_DISABLE)
						$bPathReady = False 
					EndIf
				Case 1 ; Tab choose browser
					GUICtrlSetData($btnNext, "Next")
					Select 
						Case GUICtrlRead($chooseFirefox) = $GUI_CHECKED
							GUICtrlSetData($browserDetails, "When launch StashApp with Firefox, you will see a robot icon and address bar turns red, indicating the browser is under my program's control. Other than that, it's all fine.")
							$sBrowser = "Firefox"
						Case GUICtrlRead($chooseChrome) = $GUI_CHECKED
							GUICtrlSetData($browserDetails, "It works perfectly. You won't see red address bar or anything." )
							$sBrowser = "Chrome"
						Case GUICtrlRead($chooseEdge) = $GUI_CHECKED
							GUICtrlSetData($browserDetails,"It works well, but you probably hate Microsoft so..." )
							$sBrowser = "Edge"
						Case Else
							GUICtrlSetData($browserDetails, "Choose one of the browser on the left to see its note here.")
							$sBrowser = ""
							$bBrowserReady = False 
					EndSelect
					If  $sBrowser <> "" Then 
						$bBrowserReady = True
						GUICtrlSetState($btnNext, $GUI_ENABLE)
					EndIf

				Case 2 ; Tab launch
					GUICtrlSetData($btnNext, "Launch !")
					If $bPathReady And $bBrowserReady Then 
						GUICtrlSetState($btnNext, $GUI_ENABLE)
					Else 
						GUICtrlSetState($btnNext, $GUI_DISABLE)
					EndIf
			EndSwitch
		EndIf
	Wend
	GUIDelete($Initial_Settings)
EndFunc
