/*
Lisk Node Watcher
	by Vega

Version: v0.1   (2016.12.06)

You have to install AutoHotKey to run this script.
You can find the latest version here: https://autohotkey.com

requirements:
- Autohotkey installed
- Autohotkey is Windows OS only
- make sure that the script has write permission to his folder, for the creation of settings.ini
*/

;### some initialisation ###
#SingleInstance force
#Persistent
#NoEnv
SetBatchLines -1
SetTitleMatchMode 2
ComObjError(false)
Menu, tray, icon, shell32.dll, 210
onexit, OnExit
GroupAdd justthiswin, %A_ScriptName% - Notepad	; for editing purposes
GroupAdd justthiswin, \Lisk Node Watcher\	; for editing purposes
;QPX( True ) ; Initialise Counter
;QPX( False )

; notification function by gwarble. source: https://autohotkey.com/board/topic/44870-notify-multiple-easy-tray-area-notifications-v04991/
;https://autohotkey.com/board/topic/81807-notify-builder/

;###################################################
;startup - read data from settings.ini, check stuff
;###################################################

IfnotExist settings.ini		; if no setting.ini, 
	gosub createsettingsini		;go to subroutine to create it

loop, read, settings.ini, `n		; read settings into variables
	{
	if regexmatch(A_LoopReadLine,"(.*?) ?:=.*?""(.*?)""",d)
		%d1% := Trim(d2)
	Ifinstring A_LoopReadLine, nodeurl
		if d2 
			nodeurl_count++		
	}	
	
; create an object. this will be used later for API calls. for more about this method: https://msdn.microsoft.com/en-us/library/windows/desktop/aa384106%28v=vs.85%29.aspx		
oHTTP:=ComObjCreate("WinHttp.WinHttpRequest.5.1")
;######## do some stuff based on settings.ini #########

check_nodes_height *= 1000		; convert check time to milliseconds
check_delegateinfo *= 1000		; convert check time to milliseconds

getdata_time_end := -1

guiupdate := 1			; if gui should be updated
peersupdate := 1		; if peers consensus should be checked
nodesupdate := 1		; if your nodes data should be checked

; remove / char from end of URL if present
loop % nodeurl_count
	nodeurl%a_index% := RegExReplace(nodeurl%a_index%,"(.*)\/$","$1")

defaultnode := "https://login.lisk.io"
idealnode := defaultnode		; the node in this var will be used for delegate info and other request, should be one at maximum height
if nodeurl1
	idealnode := nodeurl1		; this will need to be dynamic, change on peers block heights

gosub START
settimer START,%check_nodes_height%
return

;#######################################################
;############ END OF STARTUP SECTION  ##################
;#######################################################

START:
getdata_time := a_tickcount
Thread, NoTimers
if !ui		; if exist ignore
	gosub GUICREATION

gosub GETPEERHEIGHTS	
gosub GETNODESSTATUS	
gosub GETDELEGATEINFO
gosub GETMOREDELEGATINFO	
gosub GETFORGINGSTATUS
return


GETPEERHEIGHTS:
;##############################################
; determine how many peers at different heights
;##############################################
Thread, NoTimers
offset := "0", response := "", heightdistribution := "",topheight:=""
; query node for data
loop 1
	response .= oHTTP.ResponseText(oHTTP.Send(oHTTP.Open("GET",idealnode "/api/peers?state=2&limit=100&offset=" offset))), offset := offset + 100

FormatTime peersdata_time,%a_now%,HH:mm:ss

;process peers json 	

Pos := 1, peers_height := "", peers_ip := "",count_lines:=0
regex = {"ip":"(.*?)",.*?"height":(.*?)}
While Pos {
	Pos:=RegExMatch(response,regex, d, Pos+StrLen(d1) )
	if !d
		Break

	if d2 = null
		continue
		
IfNotInString peers_ip, %d1%`n
	peers_ip .= d1 "`n", peers_height .= d2 "`n"
}
uniquehights := peers_height

Sort, uniquehights, N R U D`n	 ; removes duplicates, puts them in desc order
	 
loop, parse, uniquehights, `n
	{
	if !a_loopfield
		break
	
	StringReplace, peers_height, peers_height, %a_loopfield%`n, %a_loopfield%`n, UseErrorLevel
	
	;if ErrorLevel < 5	; don't list errant heights
	;	continue
	
; get highest block on network	
	if topheight < %a_loopfield%
		 topheight := a_loopfield
	; display data
	ui.document.getElementById("peerbox").getElementsByClassName("line")[count_lines].getElementsByClassName("cell")[0].innerHTML := a_loopfield
	ui.document.getElementById("peerbox").getElementsByClassName("line")[count_lines].getElementsByClassName("cell")[1].innerHTML := "on"
	ui.document.getElementById("peerbox").getElementsByClassName("line")[count_lines].getElementsByClassName("cell")[2].innerHTML := ErrorLevel
	ui.document.getElementById("peerbox").getElementsByClassName("line")[count_lines].getElementsByClassName("cell")[3].innerHTML := "peers"
	
	count_lines++	 
	}
	
	;change title (if new data)
if uniquehights
	ui.document.getElementById("peerstitle").innerhtml := "Height Consensus (" peersdata_time ")"

return	

;##############################################
;##############################################

;##############################################
; determine your nodes status
;##############################################
GETNODESSTATUS:
Thread, NoTimers

loop % nodeurl_count
{
response := oHTTP.ResponseText(oHTTP.Send(oHTTP.Open("GET",nodeurl%a_index% "/api/loader/status/sync")))
if !response
	continue
FormatTime heightsdata_time,%a_now%,HH:mm:ss	
RegExMatch(response,"{""success"":(.*?),""syncing"":(.*?),""blocks"":(.*?),""height"":(.*?)}",d)
; later othen info than height can be added
	
nodeurl%a_index%_height := d4	
if d3 != 0
	nodeurl%a_index%_height := d3 " | " height
	
ui.document.getElementById("nodesbox").getElementsByClassName("line")[a_index - 1].getElementsByClassName("cell")[0].innerHTML := nodeurl%a_index%_height
ui.document.getElementById("nodesbox").getElementsByClassName("line")[a_index - 1].getElementsByClassName("cell")[1].innerHTML := RegExReplace(nodeurl%a_index%,"https?://","")
}

; change title (if new data)
if response	
	ui.document.getElementById("nodestitle").innerhtml := "Your Node Height(s) (" heightsdata_time ")"
;##############################################
;##############################################		
return

GETDELEGATEINFO:
;##############################################
; get delegate information including public key
;##############################################
if !delegate_name
	return			; there should be a message that this info needed for additional data

; check if enough time elapsed since last check
elapsed := a_tickcount - getdata_time_end
if !check_delegateinfo < %elapsed%
	return
offset:=0
loop 10
{
	response := oHTTP.ResponseText(oHTTP.Send(oHTTP.Open("GET",idealnode "/api/delegates?limit=100&offset=" offset))), offset := offset + 100

	Ifinstring response, :"%delegate_name%",
		break
	sleep 100	
}


; finds your delegate informations on the delegate list, and put them into vars

regex = {"username":"%delegate_name%","address":"(.*?)","publicKey":"(.*?)"?,"vote":"?(.*?)"?,"producedblocks":"?(.*?)"?,"missedblocks":"?(.*?)"?,.*?"rate":"?(.*?)"?,"approval":"?(.*?)"?,"productivity":"?(.*?)"?}
RegExMatch(response,regex,d)

delegate_address := Trim(d1)
delegate_publickey := Trim(d2)
delegate_vote := Trim(d3)
delegate_producedblocks := Trim(d4)
delegate_missedblocks := Trim(d5)
delegate_rate := Trim(d6)
delegate_approval  := Trim(d7)
delegate_productivity := Trim(d8)


ui.document.getElementById("rank").innerhtml := "#" delegate_rate
ui.document.getElementById("approval").innerhtml := delegate_approval "%"
ui.document.getElementById("productivity").innerhtml := delegate_productivity "%"
ui.document.getElementById("forged").innerhtml := delegate_producedblocks
ui.document.getElementById("missed").innerhtml := delegate_missedblocks

FormatTime delegatedata_time,%a_now%,HH:mm:ss	


ui.document.getElementById("delegatestitle").innerhtml := "Delegate " delegate_name " (" delegatedata_time ")"

getdata_time_end := a_tickcount
return

GETMOREDELEGATINFO:
;##############################################
;	Get account releated data
;##############################################	
if !delegate_publickey	;something went wrong, no delegate found, so can't make other queries
	return			; there should be a message that this info needed for additional data

; check if enough time elapsed since last check
elapsed := a_tickcount - getdata_time_end
if !check_delegateinfo < %elapsed%
	return
	
; get forged amounts
response := oHTTP.ResponseText(oHTTP.Send(oHTTP.Open("GET",idealnode "/api/delegates/forging/getForgedByAccount?generatorPublicKey=" delegate_publickey)))


regex = "fees":"?(.*?)"?,"rewards":"?(.*?)"?,"forged":"?(.*?)"?}
RegExMatch(response,regex,d)

delegate_forgedtotal := round(d3 / 100000000,2)
delegate_forgedreward := round(d2 / 100000000,2)
delegate_forgedfees := round(d1 / 100000000,2)

ui.document.getElementById("forgedamount").innerhtml := delegate_forgedtotal " LSK"

return	
;##############################################
;##############################################	

;##############################################
; determine if your delegate forging on a node
;##############################################
GETFORGINGSTATUS:
if !delegate_publickey	;something went wrong, no delegate found, so can't make other queries
	return			; there should be a message that this info needed for additional data
	
forgingcount := "", unknownforgingcount := ""
loop % nodeurl_count
	{
	nodeurl%a_index%_forgingstatus := regexreplace(oHTTP.ResponseText(oHTTP.Send(oHTTP.Open("GET",nodeurl%a_index% "/api/delegates/forging/status?publicKey=" delegate_publickey))),".*""enabled"":(.*?)}","$1")
	
	if nodeurl%a_index%_forgingstatus = true
		ui.document.getElementById("nodesbox").getElementsByClassName("line")[a_index - 1].getElementsByClassName("cell")[2].style.background := "green", forgingcount ++
	if nodeurl%a_index%_forgingstatus = false
		ui.document.getElementById("nodesbox").getElementsByClassName("line")[a_index  - 1].getElementsByClassName("cell")[2].style.background := "red"
	if !nodeurl%a_index%_forgingstatus 
		ui.document.getElementById("nodesbox").getElementsByClassName("line")[a_index  - 1].getElementsByClassName("cell")[2].style.background := "yellow",ui.document.getElementById("nodesbox").getElementsByClassName("line")[a_index].getElementsByClassName("cell")[2].title	:= "Forging status unknown", unknownforgingcount ++	
;instead of this, just make classes in css and here change the class
		
	}
	
if 	forgingcount > 1
	{
	FormatTime, time, %a_now%, MMM dd HH:mm
	eventlog := time " | More than one delegate is forging" 
	}
	
;############################################
; get last 10 forged blocks data
response := oHTTP.ResponseText(oHTTP.Send(oHTTP.Open("GET",idealnode "/api/blocks?generatorPublicKey=" delegate_publickey "&limit=10")))

Pos := 1, list :=""
regex = ,"timestamp":(.*?),"height":(.*?),
While Pos {
    Pos:=RegExMatch(response,regex, d, Pos+StrLen(d1) )
	if !d
		Break

; convert lisk time (unix time + 1464109200 ) to normal format + from UTC to local timezone
FormatTime, utime, % DateAdd( 19700101000000, 1464109200 + d1, "s" ), yyyy-MM-dd HH:mm:ss
	list .= utime " | " d2 "`n"
	
}

Return




;######################################
;#### CREATE GUI AND RELATED STUFF ####
;######################################

GUICREATION:
;gui, add, ActiveX, vex1 x5 y5 w800 h1000, shell.explorer
gui, add, ActiveX, vui x-9 y-9 w220 h500, about:<!DOCTYPE HTML><meta http-equiv="X-UA-Compatible" content="IE=Edge">
ui.Navigate(a_scriptdir "\defaultUI.html")
while ui.ReadyState != 4
	Sleep 10
	
; determins how many nodes are in settings and add that many lines to html	
divs := ""	
if !delegate_name
	ui.document.getElementById("delegatebox").innerhtml := "<p>Add your delegate name to settings.ini to see delegate statistics</p>"

while !ui.document.getElementById("nodesbox").innerhtml
	sleep 50
	
loop % nodeurl_count
	divs .="<div class='line'><div class='cell'></div><div class='cell'></div><div class='cell'>&nbsp;</div></div>`n"
	ui.document.getElementById("nodesbox").innerhtml := divs
	
gui +AlwaysOnTop  +ToolWindow 
Gui Margin , 0, 0		
uiheight += 5


WinGetPos,,,,TrayHeight,ahk_class Shell_TrayWnd,,,

h := A_ScreenHeight - 500
w := A_ScreenWidth -220
	
settimer, ADJUSTSIZE, 50
button := ui.Document.All.MyButton
ComObjConnect(button, "Button_")

titlebar := ui.document.all.delegatestitle
ComObjConnect(titlebar, "titlebar_")

Gui Show, autosize x%w% y%h%, Lisk Node Watcher	
return
;######################################
;######################################

	
;###################################
;#### Stuff run on short timer  ####
;###################################	
ADJUSTSIZE:
uiheight := ""
while !uiheight
	{
	uiheight := ui.document.getElementById("container").offsetHeight
	sleep 50
	if a_index > 100
		break
	}
if uiheight = %uiheight_old%
	return
uiheight_old := uiheight
uiheight += 5
GuiControl, Move, ui, h%uiheight%
Gui Show, autosize NA

return

; #### just stuff to make editing the script easier (restarts at every save in notepad)
#IfWinActive ahk_group justthiswin
~^s::
Sleep 500
reload
return
#IfWinActive
;################################################


ONEXIT:
exitapp


;### this is the default content of the ini file. if not exist this will create it ###
createsettingsini:		; creates a settings ini file

defaultf =
(
/*
Notes:
- start or reload Lisk Node Watcher after changing this file
*/

;############################
;#####  Private Nodes  ######
;############################

/*
Notes:
Your own nodes addresses. Domain or ip address with http(s) prefix and port if needed
Again, you can add as many as you want but take care of numbering them.
*/

nodeurl1 := ""			
nodeurl2 := ""
nodeurl3 := ""
nodeurl4 := ""
nodeurl5 := ""

delegate_name := "" 	 ;	your delegate username


check_nodes_height := "15"	;in seconds. how often the script should check your nodes height?
check_delegateinfo := "600"	;in seconds. how often the script should check delegate information?

notification_style := "GC=asdasd TC=White MC=White"		; you can change the notification popups design. for more see: http://www.gwarble.com/ahk/Notify/

)
FileAppend %defaultf%, settings.ini
;msgbox A default settings.ini was created. Please edit your preferences to the ini file and start the script again.`n`nPress OK to exit
msgbox A default settings.ini was created. Edit the file and restart the script after.



;#######################################################################

GuiClose:
GuiCancel:
exitapp

; convert lisk time (unix time + 1464109200 ) to normal format + from UTC to local timezone
;FormatTime, utime, % DateAdd( 19700101000000, 1464109200 + d1, "s" ), yyyy-MM-dd HH:mm:ss
DateAdd( Date, Value, Units="days" ) { ; 
	Date += Value, %Units%
	time1:=A_NowUTC, 	time2:=A_Now
	time2 -=%time1%,s
	date += time2,s
   Return Date
} 
