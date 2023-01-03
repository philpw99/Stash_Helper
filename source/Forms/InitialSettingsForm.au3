;InitialSettingsForm.au3
#include <StaticConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#Include <GuiButton.au3>
#include <GuiTab.au3>
#include <EditConstants.au3>

Func InitialSettingsForm()
	Global $stashFilePath

	; Create the whole initial setting's GUI
	Local $Initial_Settings = GUICreate("Initial Settings",1326,809,-1,-1,-1,-1)
	GUISetIcon("helper2.ico")
	
	Local $tab = GUICtrlCreatetab(41,70,1201,673,-1,-1)

	; Tab 1
	GUICtrlCreateTabItem("  Start  ")

	GUICtrlCreateLabel("Welcome to my little GUI helper for Stash!",191,117,908,62,-1,-1)
	GUICtrlSetFont(-1,20,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")

	GUICtrlCreateLabel("StashApp is a great program to manage your porn collection. This little helper will make it easier to run in Windows.", _
		166,193,937,75,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")

	; Group for choosing local or remote
	GUICtrlCreateGroup("Please start it by tell me which type of Stash you are running",139,280,1028,326,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Palatino Linotype")
	
	GUICtrlCreateLabel("Location:",279,418,101,28,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")
	
	Local $radioLocal = GUICtrlCreateRadio("Local Stash by running stash-win.exe.",219,359,501,42,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"0xFFFFFF")

	Local $stashPath = GUICtrlCreateInput("",409,409,560,40,-1,$WS_EX_CLIENTEDGE)
	GUICtrlSetState(-1,BitOr($GUI_SHOW,$GUI_ENABLE))
	GUICtrlSetFont(-1,10,400,0,"Palatino Linotype")
	GUICtrlSetTip(-1,"Please type in the location of stash-win.exe, e.g. c:\stash\stash-win.exe")
	
	Local $btnBrowse = GUICtrlCreateButton("Browse",982,408,131,40,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")

	Local $radioRemote = GUICtrlCreateRadio("Remote Stash",219,474,501,51,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"0xFFFFFF")

	GUICtrlCreateLabel("Stash URL:",279,539,120,30,-1,-1)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetBkColor(-1,"-2")

	$inputStashURL = GUICtrlCreateInput("",409,529,560,40,-1,$WS_EX_CLIENTEDGE)
	GUICtrlSetFont(-1,10,400,0,"Tahoma")
	GUICtrlSetTip(-1,"Please type in the remote URL of Stash, e.g. http://192.168.1.10:9999")

	; GUICtrlCreateTabItem("")

	; Tab 2
	GUICtrlCreateTabItem(" Choose Browser ")

	GUICtrlCreateLabel("Now choose your favorite browser to launch StashApp.",361,150,616,104,-1,-1)
	GUICtrlSetFont(-1,16,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")
	
	GUICtrlCreateGroup("Browser Choice",157,267,1014,314,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"0xFFFFFF")

	Local $chooseFirefox = GUICtrlCreateRadio("Firefox",200,325,157,48,$BS_AUTORADIOBUTTON,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")

	Local $chooseChrome = GUICtrlCreateRadio("Chrome",200,377,157,48,$BS_AUTORADIOBUTTON,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")

	Local $chooseEdge = GUICtrlCreateRadio("MS Edge",200,430,157,48,$BS_AUTORADIOBUTTON,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")

	Local $chooseOpera = GUICtrlCreateRadio("Opera",200,494,157,48,$BS_AUTORADIOBUTTON,-1)
	GUICtrlSetFont(-1,12,400,0,"Tahoma")

	Local $browserDetails = GUICtrlCreateLabel("",450,339,656,163,-1,-1)
	GUICtrlSetFont(-1,12,400,0,"Palatino Linotype")
	GUICtrlSetBkColor(-1,"-2")
	; The frame for the details
	; GUICtrlCreateLabel("",406,270,741,235,$SS_GRAYFRAME,-1) 
	; GUICtrlSetBkColor(-1,"-2")

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
	Local $btnNext = GUICtrlCreateButton("Next",960,630,211,57,-1,-1)
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
		Local $nMsg = GUIGetMsg()
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
							RegWrite($gsRegBase, "StashType", "REG_SZ", $stashType)
							If $stashType = "Local" Then 
								RegWrite($gsRegBase, "StashFilePath", "REG_SZ", $stashFilePath)
								$stashURL = "http://localhost:9999/"
								RegWrite($gsRegBase, "StashURL", "REG_SZ", $stashURL)
							Else; Remote
								If StringRight($stashURL, 1) <> "/" Then $stashURL &= "/"
								RegWrite($gsRegBase, "StashURL", "REG_SZ", $stashURL)
							EndIf
							; Set the browser choice
							RegWrite($gsRegBase, "Browser", "REG_SZ", $sBrowser)
							$bSettingDone = True

							ExitLoop 
						EndIf
				EndSwitch
				
			Case $GUI_EVENT_CLOSE
				Exit 
		EndSwitch
		
		If $iSecond <> @SEC Then 
			$iSecond = @SEC
			; Check every second.
			Switch _GUICtrlTab_GetCurFocus($tab)
				Case 0	; Currently at Tab 0, Start
					; Maybe the button now is "Launch"
					If GUICtrlRead($btnNext) <> "Next" Then GUICtrlSetData($btnNext, "Next")
					
					If GUICtrlRead($radioLocal) = $GUI_CHECKED Then
						; Chose local
						$stashFilePath = GUICtrlRead($stashPath)
						$stashType = "Local"
						If StringLower(StringRight($stashFilePath, 13)) = "stash-win.exe" And FileExists($stashFilePath) Then
							; the input is valid
							GUICtrlSetState($btnNext, $GUI_ENABLE)
							$bPathReady = True 
						Else
							GUICtrlSetState($btnNext, $GUI_DISABLE)
							$bPathReady = False 
						EndIf
					ElseIf GUICtrlRead($radioRemote) = $GUI_CHECKED Then 
						; Chose remote
						$stashType = "Remote"
						$stashURL = GUICtrlRead($inputStashURL)
						If stringlower(stringleft($stashURL,4)) = "http" Then 
							; Just the minimal check passed
							GUICtrlSetState($btnNext, $GUI_ENABLE)
							$bPathReady = True 
						Else
							GUICtrlSetState($btnNext, $GUI_DISABLE)
							$bPathReady = False 
						EndIf
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
						Case GUICtrlRead($chooseOpera) = $GUI_CHECKED
							GUICtrlSetData($browserDetails,"Never test it myself. It should work though." )
							$sBrowser = "Opera"
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
