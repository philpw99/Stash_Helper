#cs
GET /i.html HTTP/1.1
Accept: image/gif, image/x-xbitmap, image/jpeg, image/png
Accept-Language: en-us
Accept-Encoding: gzip, deflate
User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 1.0.3705; .NET CLR 2.0.50727)
Host: 127.0.0.1
Connection: Keep-Alive
#ce

#include <INet.au3>
#include <File.au3>
#include "wd_core.au3"
; #include "URL_Encode.au3"

Global $mimetypes[16] = [ _
	"html","text/html", _
	"htm","text/html", _
	"gif", "image/gif", _
	"bmp", "image/x-xbitmap", _
	"jpg", "image/jpeg", _
	"jpeg", "image/jpeg", _
	"jpe", "image/jpeg", _
	"png", "image/png"]

Global Const $E404 = '<html><head><meta http-equiv="Content-Type" content="text/html; charset=gb_2312-80"><title> Localhost:9980 - Error 404 - File not found.</title>'& _
					'</head><body bgcolor="#FFFFFF"><h2>Error 404: File not found</h2>'& _
					'<p>The server which you are requesting the file cannot find the file.</p></body></html>'

;~ If $CmdLine[0] = 0 Then
;~ 	ConsoleWrite("Error, No parameter." & @CRLF)
;~ 	Exit
;~ EndIf

; Parameter 1 is the browser type "Firefox","Chrome" or "Edge"
; Para 2 is the URL

; MiniWebServer($CmdLine[1])
If $CmdLine[0]<> 2 Then
	c("command line error")
	Exit
EndIf

$sBrowser = $CmdLine[1]
$sURL = $CmdLine[2]
$sLocalBase = "http://localhost:9980"

$aURL = _WinHttpCrackUrl($sURL)
; protocol & hostname
$sURLBase= $aURL[0]& "://" & $aURL[2]
If $aURL[3] <> 80 And $aURL[3]<>443 Then
	; Add port number
	$sURLBase &= ":" & $aURL[3]
EndIf
c("url base:"& $sURLBase)
c("URL:" & $aURL[6])
c("Extra:" & $aURL[7])

Switch $sBrowser
	Case "Firefox"
		SetupFirefox()
	Case "Chrome"
		SetupChrome()
	Case "Edge"
		SetupEdge()
	Case Else
		SetupEdge()
EndSwitch

Global $iConsolePID = _WD_Startup()
If @error <> $_WD_ERROR_Success Then BrowserError(@extended)

$sSession = _WD_CreateSession($sDesiredCapabilities)
If @error <> $_WD_ERROR_Success Then BrowserError(@extended)

Global $sBrowserHandle

OpenURL($sURL)

MiniWebServer()

Func MiniWebServer()
	Local $listen, $sock, $recv
	$timeout = 9999999999

	Local Const $IP = "127.0.0.1"
	Local Const $PORT = 9980

	TCPStartup()

	$listen = TCPListen($IP, $PORT)
	If $listen = -1 Then
		$err = @error
		ConsoleWrite("Error, Unable to connect." & @CRLF & @CRLF & "dec: " & $err & @CRLF & "hex: 0x" & Hex($err, 8))
		Return SetError(1)
	EndIf
	Local $hTimer = TimerInit()
	While TimerDiff($hTimer) < $timeout
		$sock = TCPAccept($listen)                           ;;Poll the socket for commands
		If $sock >= 0 Then
			; Got a connection request
			$recv = _SockRecv($sock)                         ;;Get Command from socket
			$pos1 = StringInStr( $recv, "GET", 2 )
			$pos2 = StringInStr( $recv, "Host", 2 )
			$sFirstLine = StringMid( $recv, $pos1, $pos2-$pos1) ; Get between 'GET' and 'Host'
			$aFirstLine = StringSplit( $sFirstLine, " ")
			$recvRequest = $aFirstLine[2] 				        ;;Split up the Request, 2nd one is the request file.
			$pos = StringInStr( $recvRequest, ".", 2, -1)
			If $pos = 0 Then
				$sFileType="html"		; No extension, presume to be html
			Else
				$sFileType=StringMid($recvRequest,$pos+1)	; Get the request file extension.
			EndIf
			ConsoleWrite ( "Request:" & $recvRequest & " file type:" & $sFileType & @CRLF )
			$Content = _ServerGetFile($recvRequest)    ;;Normal file request
			If $Content <> $E404 Then
				; Not 404 error.
				$sHeader = _ServerGetHeader($sFileType)
			Else
				; It's a 404 error
				$sHeader = _ServerGetHeader("html")
			EndIf
			; ConsoleWrite ( "Header: " & $sHeader & "|" & @CRLF)
			_SockSend($sock, $sHeader );;Send the header first.
			_SockSend($sock, $Content) ;; Send it seperately so no string conversion.
		EndIf
		TCPCloseSocket($sock)		; Close the tcp socket to allow listening afterwards
		; $listen = TCPListen($IP, $PORT, 1)
	WEnd
	TCPShutdown()
EndFunc

Func ServerExit()
	TCPShutdown()
EndFunc
; WD drivers
Func SetupFirefox()
	If Not FileExists(@AppDataDir & "\Webdriver\" & "geckodriver.exe") Then
		Local $b64 = ( @CPUArch = "X64" )
		Local $bGood = _WD_UPdateDriver ("firefox", @AppDataDir & "\Webdriver" , $b64, True) ; Force update
		If Not $bGood Then
			MsgBox(48,"Error Getting Firefox Driver", _
			"There is an error getting the driver for Firefox. Maybe your Internet is down?" _
				& @CRLF & "The program will try to get the driver again next time you launch it.",0)
			Exit
		EndIf
	EndIf

	_WD_Option('Driver', @AppDataDir & "\Webdriver\" & 'geckodriver.exe')
	_WD_Option('DriverClose', True)
	_WD_Option('DriverParams', '--log trace')
	_WD_Option('Port', 4444)

	$sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"browserName": "firefox", "acceptInsecureCerts":true}}}'
EndFunc   ;==>SetupGecko

Func SetupChrome()
	If Not FileExists( @AppDataDir & "\Webdriver\" & "chromedriver.exe") Then
		Local $bGood = _WD_UPdateDriver ("chrome", @AppDataDir & "\Webdriver" , Default, True) ; Force update
		If Not $bGood Then
			MsgBox(48,"Error Getting Firefox Driver", _
			"There is an error getting the driver for Firefox. Maybe your Internet is down?" _
				& @CRLF & "The program will try to get the driver again next time you launch it.",0)
			Exit
		EndIf
	EndIf

	_WD_Option('Driver', @AppDataDir & "\Webdriver\" & 'chromedriver.exe')
	_WD_Option('DriverClose', True)
	_WD_Option('Port', 9515)
	_WD_Option('DriverParams', '--verbose --log-path="' & @AppDataDir & "\Webdriver\chrome.log")

	$sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"goog:chromeOptions": {"w3c": true, "excludeSwitches": [ "enable-automation"]}}}}'
EndFunc   ;==>SetupChrome

Func SetupEdge()
	If Not FileExists(@AppDataDir & "\Webdriver\" & "msedgedriver.exe") Then
		Local $b64 = ( @CPUArch = "X64" )
		Local $bGood = _WD_UPdateDriver ("msedge", @AppDataDir & "\Webdriver" , $b64 , True) ; Force update
		If Not $bGood Then
			MsgBox(48,"Error Getting Firefox Driver", _
			"There is an error getting the driver for Firefox. Maybe your Internet is down?" _
				& @CRLF & "The program will try to get the driver again next time you launch it.",0)
			Exit
		EndIf
	EndIf


	_WD_Option('Driver', @AppDataDir & "\Webdriver\" & 'msedgedriver.exe')
	_WD_Option('DriverClose', True)
	_WD_Option('Port', 9515)
	_WD_Option('DriverParams', '--verbose --log-path="' & @AppDataDir & "\Webdriver\msedge.log")

	$sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"ms:edgeOptions": {"excludeSwitches": [ "enable-automation"]}}}}'
EndFunc   ;==>SetupEdge

Func OpenURL($url)
	$sBrowserHandle = _WD_Window($sSession, "Window")
	If $sBrowserHandle = "" Then
		; The session is invalid.
		$sSession = _WD_CreateSession($sDesiredCapabilities)
	EndIf

	_WD_Navigate($sSession, $url)
EndFunc

;Gets the document header
Func _ServerGetHeader($filetype)
	$mime = _ServerGetFileType($filetype)
	Return 'HTTP/1.1 200 OK' & @CRLF _
		& 'Content-Type: ' & $mime & @CRLF & @CRLF
EndFunc

;Gets the filetype for the header using the extention
Func _ServerGetFileType($ext)
	For $i = 0 to UBound($mimetypes)-1 Step 2
		If StringInStr($ext, $mimetypes[$i]) Then Return $mimetypes[$i+1]
	Next
	Return "text/html"
EndFunc

;Get a file normally
Func _ServerGetFile($filename)
	;;Default to index.html
	If $filename = "/" or $filename = "\" or $filename = "" Then
		$filename = "\index.html"
	Else
		$filename = StringReplace( $filename, "/", "\" )
		If StringLeft($filename,1) <> "\" Then
			$filename = "\" & $filename
		EndIf
	EndIf
	$file = $filename

	;;If file does not exist, send an error 404
	If Not FileExists($file) Then
		Return $E404
	EndIf

	;;Read the data from the file
	If StringInStr($filename,".htm") Then
		; html or html file
		Return FileRead($file)
	Else
		; treat it like binary
		$hFile = FileOpen($file, $FO_BINARY)
		$sData = FileRead( $hFile, FileGetSize($file) )
		FileClose($hFile)
		Return $sData
	EndIf
EndFunc

;;Sock Functions

;Recieve Data on a socket
Func _SockRecv( $iSocket, $iBytes = 2048 )
	Local $sData = ""
	;;Loop Until you recieve data on the socket
	While $sData = ""
		$sData = TCPRecv($iSocket, $iBytes)
	Wend
	;;Flash a MsgBox
	; ConsoleWrite("Receive data:" & $sData & @CRLF)
	;;Log the Command
	; _FileWriteLog( @ScriptDir&"\log.txt", $sData )
	Return $sData
EndFunc

;Send Data on a socket
Func _SockSend( $iSocket, $sData )
	Return TCPSend($iSocket, $sData)
EndFunc

Func c($str)
	ConsoleWrite($str&@CRLF)
EndFunc