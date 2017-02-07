DetectHiddenWindows,On
#Persistent
#SingleInstance force
#UseHook
#InstallKeybdHook
#Include %A_ScriptDir%\JSON.ahk
SetBatchLines -1

;<<<<<<<<<<<<默认值>>>>>>>>>>>>
Path_data=%A_ScriptDir%\HotWindows.mdb	;数据库地址
Edition:=201707
HotWindows=Space

;<<<<<<<<<<<<WIN10 WIN8中重要的设置值>>>>>>>>>>>>
RegRead,Bubble,HKEY_CURRENT_USER,SOFTWARE\Policies\Microsoft\Windows\Explorer,EnableLegacyBalloonNotifications
if not Bubble
	MsgBox,4,重要设置,脚本需要使用气泡提示点击Yes确定切换为气泡提示`n如需恢复请在托盘设置中更改
		IfMsgBox Yes
			RegWrite,REG_DWORD,HKEY_CURRENT_USER,SOFTWARE\Policies\Microsoft\Windows\Explorer,EnableLegacyBalloonNotifications,1
TrayTip,HotWindows,正在准备请等待准备完成,,2
;<<<<<<<<<<<<预设与配置>>>>>>>>>>>>
Show_modes=TrayTip,ListView
Hot_keys=Space,Tab
Loop,parse,Show_modes,`,
	Menu,Show_mode,Add,%A_LoopField%,Show_mode
Loop,parse,Hot_keys,`,
	Menu,Hot_key,Add,%A_LoopField%,Hot_key
Menu,Tray,Add,开机启动,Auto
Menu,Tray,Add,气泡提示,Bubble
Menu,Tray,Add,输入保护,Boot
Menu,Tray,Add
Menu,Tray,Add,显示方式,:Show_mode
Menu,Tray,Add,激活热键,:Hot_key
Menu,Tray,Add,添加程序,Add_exe
Menu,Tray,Add
Menu,Tray,Add,重启脚本,Reload
Menu,Tray,Add,退出脚本,ExitApp
Menu,Tray,Icon,显示方式,shell32.dll,90
Menu,Tray,Icon,激活热键,shell32.dll,318
Menu,Tray,Icon,添加程序,shell32.dll,138
Menu,Tray,Icon,重启脚本,shell32.dll,239
Menu,Tray,Icon,退出脚本,shell32.dll,132
Menu,Tray,NoStandard
Menu,Tray,Tip,HotWindows`n版本:%Edition%
RegRead,HotRun,HKEY_CURRENT_USER,Software\Microsoft\Windows\CurrentVersion\Run,HotRun
RegRead,Bubble,HKEY_CURRENT_USER,SOFTWARE\Policies\Microsoft\Windows\Explorer,EnableLegacyBalloonNotifications
RegRead,Show_mode,HKEY_CURRENT_USER,HotWindows,HotShow_mode	;显示方式
RegRead,Hot_key,HKEY_CURRENT_USER,HotWindows,HotHot_key	;激活热键
RegRead,Boot,HKEY_CURRENT_USER,HotWindows,Hotboot	;输入保护
RegRead,Styles,HKEY_CURRENT_USER,HotWindows,HotStyles	;样式列表
if not Styles
	Styles=0x860F0000,0x860E0000,0x36CF0000,0x17CF0000,0x84C80000,0xB4CF0000,0x94CA0000,0x95CF0000,0x94CF0000	;默认匹配的样式
if not Hot_key{
	RegWrite,REG_SZ,HKEY_CURRENT_USER,HotWindows,HotHot_key,Space
	Menu,Hot_key,ToggleCheck,Space
}else{
	Menu,Hot_key,ToggleCheck,%Hot_key%
}
if not Show_mode{
	RegWrite,REG_SZ,HKEY_CURRENT_USER,HotWindows,HotShow_mode,ListView
	Menu,Show_mode,ToggleCheck,ListView
}else{
	Menu,Show_mode,ToggleCheck,%Show_mode%
}
IfExist,%HotRun%
{
	RegWrite,REG_SZ,HKEY_CURRENT_USER,Software\Microsoft\Windows\CurrentVersion\Run,HotRun,%A_ScriptFullPath%
	Menu,Tray,ToggleCheck,开机启动
}
if Bubble
	Menu,Tray,ToggleCheck,气泡提示
if Boot
	Menu,Tray,ToggleCheck,输入保护
RegRead,LastTime,HKEY_CURRENT_USER,HotWindows,HotEdit
RegWrite,REG_SZ,HKEY_CURRENT_USER,HotWindows,HotEdit,%Edition%
if LastTime and (LastTime<Edition){
	TrayTip,升级成功,已从%LastTime%升级到%Edition%,,1
	Sleep,2000
}

;<<<<<<<<<<<<检查更新>>>>>>>>>>>>
if W_InternetCheckConnection("https://github.com"){
	TrayTip,检查更新,确保网络联通,,1
	GetJson:=JSON.load(Update("http://autoahk.com/hotwindows.php"))
	if (GetJson[1].time>Edition){
		Time:=GetJson[1].time
		Inf:=GetJson[1].inf
		Url:=GetJson[1].URL
		RunWait https://github.com/liumenggit/HotWindows#更新历史
		MsgBox,4,版本更新,是否更新到最新版本：%Time%`n%Inf%
		IfMsgBox Yes
			gosub,Downloand
	}
}

;<<<<<<<<<<<<声明全局变量>>>>>>>>>>>>
global Styles,Path_data,Show_mode,Key_History,WHERE_list

;<<<<<<<<<<<<DLL载入>>>>>>>>>>>>
tcmatch := "Tcmatch.dll"
hModule := DllCall("LoadLibrary", "Str", tcmatch, "Ptr")

;<<<<<<<<<<<<热键创建>>>>>>>>>>>>
Layout=qwertyuiopasdfghjklzxcvbnm
Loop,Parse,Layout
	Hotkey,%A_LoopField%,Layout
SysGet,Width,16
SysGet,Height,17
ListWidth:=Width/4

;<<<<<<<<<<<<GUI>>>>>>>>>>>>
Gui,+AlwaysOnTop +Border -SysMenu +ToolWindow +LastFound +HwndMyGuiHwnd
Gui,Add,ListView,w%ListWidth% r9 xm ym,编号|标题
Gui,Add,StatusBar
WinSet,Transparent,200,ahk_id %MyGuiHwnd%

;<<<<<<<<<<<<创建SQL表>>>>>>>>>>>>
IfNotExist,%Path_data%
{
	Catalog:=ComObjCreate("ADOX.Catalog")
	Catalog.Create("Provider='Microsoft.Jet.OLEDB.4.0';Data Source=" Path_data)
	SQL_Run("CREATE TABLE Now_list(Title varchar(255),Pid varchar(255),Path varchar(255),GetStyle varchar(255))")	;添加程序数据库表
	SQL_Run("CREATE TABLE Activate(Title varchar(255),Times varchar(255))")	;添加程序数据库表
	SQL_Run("CREATE TABLE Quick(Title varchar(255),Pid varchar(255),Path varchar(255),GetStyle varchar(255))")	;添加程序数据库表
	;SQL_Run("CREATE TABLE Quick(Title varchar(255),Path varchar(255))")
}else{
	SQL_Run("DELETE FROM Now_list")
}

;<<<<<<<<<<<<加载列表>>>>>>>>>>>>
Load_list()	;创建初始程列表
TrayTip,HotWindows,准备完成开始使用`,右键托盘设置热键.`n捐赠支付宝：rrsyycm@163.com,,1
;<<<<<<<<<<<<主要循环>>>>>>>>>>>>
loop{
	WinGet,Wina_ID,ID,A
	WinGet,Exe_Name,ProcessName,ahk_id %Wina_id%
	WinGet,Get_Style,Style,ahk_id %Wina_id%
	if GetStyle not in %Styles%
	{
		Styles=%Styles%`,%Get_Style%
		RegWrite,REG_SZ,HKEY_CURRENT_USER,HotWindows,HotStyles,%Styles%
	}
	Load_exe(Exe_Name)
	WinWaitNotActive,ahk_id %Wina_id%
	Load_exe(Exe_Name)
}
Return

;<<<<<<<<<<<<主要功能的标签>>>>>>>>>>>>
Layout:
if GetKeyState(HotWindows,"P"){
	StringReplace,ThisHotkey,A_ThisHotkey,~
	Key_History = %Key_History%%ThisHotkey%
	StrLens := StrLen(Key_History)
	if StrLens=1
		loop,9{
			Hotkey,%A_Index%,Table
			Hotkey,%A_Index%,On
		}
	SQL_List("SELECT Now_list.Title,Now_list.Pid,Now_list.Path,Now_list.GetStyle,Activate.Times FROM Now_list LEFT JOIN Activate ON Now_list.Title=Activate.Title ORDER BY Activate.Times DESC UNION SELECT Quick.Title,Quick.Pid,Quick.Path,Quick.GetStyle,Activate.Times FROM Quick LEFT JOIN Activate ON Quick.Title=Activate.Title",Key_History)
	if WHERE_list.Length(){
		Show_list(WHERE_list)
		if (WHERE_list.Length()="1"){
			Activate("1")
			Send {Space Up}
		}
	}else{
		loop,9
			Hotkey,%A_Index%,off
		Cancel()
	}
	if (Boot="1") and (StrLens="1")
		if GetKeyState("CapsLock","T")
			StringUpper,PriorHotke,A_ThisHotkey
		else
			PriorHotke:=A_ThisHotkey
	if (Boot="1") and (StrLens="2")
		goto,Key_wait
	if (Boot="0") and (StrLens="1")
		goto,Key_wait
}else{
	Cancel()
	if (Boot="1") and (StrLens="1"){
		Send %PriorHotke%
		StrLens:=
	}
	if GetKeyState("CapsLock","T")
		StringUpper,ThisHotkey,A_ThisHotkey
	else
		ThisHotkey:=A_ThisHotkey
	Send %ThisHotkey%
}
ThisHotkey:=A_ThisHotkey
Return

Table:
	Activate(A_ThisHotkey)
Return

Key_wait:
	KeyWait,%HotWindows%,L
	if Key_History
		Activate("1")
Return

Add_exe:
Gui,New
Gui,Add_exe:New
Gui,Add_exe:+LabelMyAdd +ToolWindow +AlwaysOnTop
Gui,Add_exe:Add,ListView,w%ListWidth% vAdd_list r9 xm ym,名称|路径
Gui,Add_exe:Add,Text,xm Section,添加程序请将文件拖入本窗口
Gui,Add_exe:Add,Button,ys gDele_exe,删除选择程序(&D)
Gui,Add_exe:Show,,添加程序到热启动列表
Add_list()
Return

Dele_exe:
RowNumber=0
Loop
{
    RowNumber:=LV_GetNext(RowNumber)
    if not RowNumber
        break
    LV_GetText(Text,RowNumber)
	SQL_Run("DELETE FROM Quick WHERE Title='" Text "'")
}
Add_list()
TrayTip,HotWindows,删除完成,,3
Return

MyAddDropFiles:
Loop,Parse,A_GuiEvent,`n
{
	SplitPath,A_LoopField,OutFileName,OutDir,OutExtension,OutNameNoExt,OutDrive
	if not Sql_Get("SELECT COUNT(*) FROM Quick WHERE Path='" A_LoopField "'")
	{
		SQL_Run("DELETE FROM Quick WHERE Title='" OutNameNoExt "'")
		SQL_Run("Insert INTO Quick (Title,Path) VALUES ('" OutNameNoExt "','" A_LoopField "')")
	}
}
Add_list()
TrayTip,HotWindows,添加完成,,1
Return
;<<<<<<<<<<<<窗口函数>>>>>>>>>>>>
Add_list(){
	Recordset := ComObjCreate("ADODB.Recordset")
	Recordset.Open("SELECT Title,Path FROM Quick","Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" . Path_data . "")
	GuiControl,-Redraw,Add_list
	LV_Delete()
	while !Recordset.EOF
	{
		LV_Add("" ,Recordset.Fields["Title"].Value,Recordset.Fields["Path"].Value)
		Recordset.MoveNext()
	}
	LV_ModifyCol()
	GuiControl,+Redraw,Add_list
}

Activate(WHERE_time){
	Cancel()
	Activate:=WHERE_list[WHERE_time].PID
	Title:=WHERE_list[WHERE_time].Title
	Path:=WHERE_list[WHERE_time].Path
	if Activate
		WinActivate,ahk_id %Activate%
	else
		Try Run %Path%
		catch e
			Return
	loop,9
		Hotkey,%A_Index%,off
	if not Sql_Get("SELECT Times FROM Activate WHERE Title='" Title "'")
		SQL_Run("Insert INTO Activate (Title,Times) VALUES ('" Title "','1')")
	else
		SQL_Run("UPDATE Activate SET Times = Times+1 WHERE Title='" Title "'")
}

Cancel(){
	Key_History:=
	if Show_mode=ListView
		Gui,Cancel
	else
		TrayTip
}

Show_list(WHERE_list){
	if Show_mode=ListView
	{
		GuiControl,-Redraw,MyListView
		LV_Delete()
		ImageListID:=IL_Create(WHERE_list.Length())
		LV_SetImageList(ImageListID)
		For k,v in WHERE_list
		{
			if v.Pid
				Level=○
			else
				Level=●
			LV_Add("Icon" . IL_Add(ImageListID,v.Path,1),k Level,v.Title)
		}
		LV_ModifyCol()
		SB_SetText("按键历史：" . Key_History . "")
		GuiControl,+Redraw,MyListView
		Gui,Show,AutoSize Center,HotWindows
	}else{
		Tip_list:=Key_History
		For k,v in WHERE_list
		{
			if v.Pid
				Level=○
			else
				Level=●
			Tip_list:=Tip_list "`n" k Level v.Title
		}
		TrayTip,,%Tip_list%
	}
}

;<<<<<<<<<<<<生成数据>>>>>>>>>>>>
Load_list(){
	DetectHiddenWindows,Off
	WinGet,ID_list,List,,,Program Manager
	DetectHiddenWindows,On
	loop,%ID_list%
	{
		This_id := ID_list%A_Index%
		WinGet,Exe_Name,ProcessName,ahk_id %This_id%
		IfNotInString,Exe_Names,%Exe_Name%
			Load_exe(Exe_Name)
		Exe_Names=%Exe_Name%`n%Exe_Names%
	}
	Recordset := ComObjCreate("ADODB.Recordset")
	Recordset.Open("SELECT Path FROM Quick","Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" . Path_data . "")
	while !Recordset.EOF
	{
		Quick_Path:=Recordset.Fields["Path"].Value
		;if not GetIconCount(Quick_Path)		
		IfNotExist,%Quick_Path%
			SQL_Run("DELETE FROM Quick WHERE Path='" Quick_Path "'")
		Recordset.MoveNext()
	}
}
Load_exe(Exe_Name){
	SQL_Run("DELETE FROM Now_list WHERE Path LIKE '%" Exe_Name "'")
	WinGet,WinList,List,ahk_exe %Exe_Name%
	WinGet,Path,ProcessPath,ahk_exe %Exe_Name%
	SplitPath,Path,OutFileName,OutDir,OutExtension,OutNameNoExt,OutDrive
	;Windowsvar=C:\Windows\
	;IfNotInString,Path,%Windowsvar%
	if GetIconCount(Path)
		if not Sql_Get("SELECT COUNT(*) FROM Quick WHERE Path='" Path "'")
		{
			SQL_Run("DELETE FROM Quick WHERE Title='" OutNameNoExt "'")
			SQL_Run("Insert INTO Quick (Title,Path) VALUES ('" OutNameNoExt "','" Path "')")
		}
	loop,%WinList% {
		PID:=WinList%A_Index%
		WinGet,GetStyle,Style,ahk_id %PID%
		WinGetTitle,Title,ahk_id %PID%
		WinGet,Path,ProcessPath,ahk_id %PID%
		if GetStyle in %Styles%
			if Title and GetIconCount(Path){
				if Sql_Get("SELECT COUNT(*) FROM Quick WHERE Title='" Title "'")
					continue
				;if Sql_Get("SELECT Times FROM Activate WHERE Title='" Title "'")
				SQL_Run("Insert INTO Now_list (Title,PID,Path,GetStyle) VALUES ('" Title "','" PID "','" Path "','" GetStyle "')")
			}
	}
}

GetIconCount(file){
	Menu, test, add, test, handle
	Loop
	{
		try {
			id++
			Menu, test, Icon, test, % file, % id
		} catch error {
			break
		}
	}
return id-1
}
handle:
return
;<<<<<<<<<<<<MENU的功能>>>>>>>>>>>>
Bubble:
if Bubble
	RegWrite,REG_DWORD,HKEY_CURRENT_USER,SOFTWARE\Policies\Microsoft\Windows\Explorer,EnableLegacyBalloonNotifications,0
else
	RegWrite,REG_DWORD,HKEY_CURRENT_USER,SOFTWARE\Policies\Microsoft\Windows\Explorer,EnableLegacyBalloonNotifications,1
	Menu,Tray,ToggleCheck,气泡提示
Return

Auto:
	IfExist,%HotRun%
		RegDelete,HKEY_CURRENT_USER,Software\Microsoft\Windows\CurrentVersion\Run,HotRun
	else
		RegWrite,REG_SZ,HKEY_CURRENT_USER,Software\Microsoft\Windows\CurrentVersion\Run,HotRun,%A_ScriptFullPath%
	Menu,Tray,ToggleCheck,开机启动
Return

Show_mode:
	Show_mode:=A_ThisMenuItem
	Loop,parse,Show_modes,`,
		Menu,Show_mode,Uncheck,%A_LoopField%
	Menu,Show_mode,ToggleCheck,%A_ThisMenuItem%
	RegWrite,REG_SZ,HKEY_CURRENT_USER,HotWindows,HotShow_mode,%A_ThisMenuItem%
Return

Hot_key:
	HotWindows:=A_ThisMenuItem
	Loop,parse,Hot_keys,`,
		Menu,Hot_key,Uncheck,%A_LoopField%
	Menu,Hot_key,ToggleCheck,%A_ThisMenuItem%
	RegWrite,REG_SZ,HKEY_CURRENT_USER,HotWindows,HotHot_key,%A_ThisMenuItem%
Return

Boot:
if Boot				
	RegWrite,REG_SZ,HKEY_CURRENT_USER,HotWindows,Hotboot,0
else
	RegWrite,REG_SZ,HKEY_CURRENT_USER,HotWindows,Hotboot,1
RegRead,Boot,HKEY_CURRENT_USER,HotWindows,Hotboot	;输入保护
Menu,Tray,ToggleCheck,输入保护
Return

Reload:
	Reload
ExitApp:
	ExitApp

;<<<<<<<<<<<<SQL函数>>>>>>>>>>>>
SQL_List(SQL,Key_History){
	Recordset := ComObjCreate("ADODB.Recordset")
	Recordset.Open(SQL,"Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" . Path_data . "")
	WHERE_list := Object()
	WHERE_time :=
	while !Recordset.EOF
	{
		if (matched := DllCall("Tcmatch\MatchFileW","WStr",Key_History,"WStr",Recordset.Fields["Title"].Value)){
			WHERE_time++
			WHERE_list[WHERE_time]:={Title:Recordset.Fields["Title"].Value,PID:Recordset.Fields["PID"].Value,Path:Recordset.Fields["Path"].Value,GetStyle:Recordset.Fields["GetStyle"].Value,Times:Recordset.Fields["Times"].Value}
		}
		Recordset.MoveNext()
	}
	Return
}
SQL_Run(SQL){	;向数据库运行命令
	Recordset := ComObjCreate("ADODB.Recordset")
	Try Recordset.Open(SQL,"Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" . Path_data . "")
	catch e
	Return
}
SQL_Get(SQL){	;向数据库运行命令请求返回
	Recordset := ComObjCreate("ADODB.Recordset")
	Recordset.Open(SQL,"Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" . Path_data . "")
	Try Return Recordset.Fields[0].Value
	catch e
		Return
}

;<<<<<<<<<<<<更新功能>>>>>>>>>>>>
Downloand:
	Gui,Add,Text,xm ym w233 vLabel1,正在初始化...
	Gui,Add,Text,xm y24 w140 vLabel2,
	Gui,Add,Text, x150 y24 w80 vLabel3,
	Gui,Add,Button, x260 y10 w50 h25 gCancel, 取消
	Gui,Add,Progress, x10 y45 w300 h20 vMyProgress -Smooth
	Gui, +ToolWindow +AlwaysOnTop
	SysGet, m, MonitorWorkArea,1
	x:=A_ScreenWidth-520
	y:=A_ScreenHeight-180
	Gui,Show,w320 x%x% y%y% , 文件下载
	Gui +LastFound
	SplitPath, URL, FN,,,, DN
	FN:=(FN ? FN : DN)
	SAVE=%A_ScriptDir%\HotWindows-master.zip
	DllCall("QueryPerformanceCounter", "Int64*", T1)
	WP1=0
	T2=0
	WP2=0
	if ((E:=InternetFileRead( binData, URL, False, 1024)) > 0 && !ErrorLevel)
	{
		VarZ_Save(binData, SAVE)
		GuiControl, Text, Label1, 下载完成。
		Sleep, 500
		FileCopyDir,%A_ScriptDir%,%A_ScriptDir%\history\%Edition%,1
		D_history=%A_ScriptDir%\history\%time%
		FileCreateDir,%D_history%
		SmartZip(SAVE,D_history)
		FileDelete,%SAVE%
		gosub,ExitSub
		ExitApp
	}else{
		ERR := (E<0) ? "下载失败，错误代码为" . E : "下载过程中出错，未能完成下载。请手动更新。"
		GuiControl, Text, Label1, %ERR%
		Sleep, 500
		Gui,Destroy
		return
	}
	DllCall( "FreeLibrary", UInt,DllCall( "GetModuleHandle", Str,"wininet.dll") )
return

ExitSub:
bat=
		(LTrim
:start
	ping 127.0.0.1 -n 2>nul
	del `%1
	if exist `%1 goto start
	xcopy %D_history%\HotWindows-master %A_ScriptDir% /s/e/y
	rd /s/q %D_history%
	start %A_ScriptFullPath%
	del `%0
	)
	batfilename=Delete.bat
	IfExist %batfilename%
		FileDelete %batfilename%
	FileAppend, %bat%, %batfilename%
	Run,%batfilename% , , Hide
	ExitApp
return

SmartZip(s, o, t = 16)	;内置解压函数
{
	IfNotExist, %s%
		return, -1
	oShell := ComObjCreate("Shell.Application")
	if InStr(FileExist(o), "D") or (!FileExist(o) and (SubStr(s, -3) = ".zip"))
	{
		if !o
			o := A_ScriptDir
		else ifNotExist, %o%
			FileCreateDir, %o%
		Loop, %o%, 1
			sObjectLongName := A_LoopFileLongPath
		oObject := oShell.NameSpace(sObjectLongName)
		Loop, %s%, 1
		{
			oSource := oShell.NameSpace(A_LoopFileLongPath)
			oObject.CopyHere(oSource.Items, t)
		}
	}
}


W_InternetCheckConnection(lpszUrl){ ;检查FTP服务是否可连接
	FLAG_ICC_FORCE_CONNECTION := 0x1
	dwReserved := 0x0
	return, DllCall("Wininet.dll\InternetCheckConnection", "Ptr", &lpszUrl, "UInt", FLAG_ICC_FORCE_CONNECTION, "UInt", dwReserved, "Int")
}

InternetFileRead( ByRef V, URL="", RB=0, bSz=1024, DLP="DLP", F=0x84000000 )
{
	SetBatchLines, -1
	Static LIB="WININET\", QRL=16, CL="00000000000000", N=""
	If ! DllCall( "GetModuleHandle", Str,"wininet.dll" )
		DllCall( "LoadLibrary", Str,"wininet.dll" )
	If ! hIO:=DllCall( LIB "InternetOpen", Str,N, UInt,4, Str,N, Str,N, UInt,0 )
		Return -1
	If ! ( ( hIU:=DllCall( LIB "InternetOpenUrl", UInt,hIO, Str,URL, Str,N, Int,0, UInt,F , UInt,0 ) ) || ErrorLevel )
		Return 0 - ( !DllCall( LIB "InternetCloseHandle", UInt,hIO ) ) - 2
	If ! ( RB )
	If ( SubStr(URL,1,4) = "ftp:" )
		CL := DllCall( LIB "FtpGetFileSize", UInt,hIU, UIntP,0 )
	Else If ! DllCall( LIB "HttpQueryInfo", UInt,hIU, Int,5, Str,CL, UIntP,QRL, UInt,0 )
		Return 0 - ( !DllCall( LIB "InternetCloseHandle", UInt,hIU ) ) - ( !DllCall( LIB "InternetCloseHandle", UInt,hIO ) ) - 4
	VarSetCapacity( V,64 ), VarSetCapacity( V,0 )
	SplitPath, URL, FN,,,, DN
	FN:=(FN ? FN : DN), CL:=(RB ? RB : CL), VarSetCapacity( V,CL,32 ), P:=&V,
	B:=(bSz>CL ? CL : bSz), TtlB:=0, LP := RB ? "Unknown" : CL, %DLP%( True,CL,FN )
	Loop
	{
		If ( DllCall( LIB "InternetReadFile", UInt,hIU, UInt,P, UInt,B, UIntP,R ) && !R )
			Break
		P:=(P+R), TtlB:=(TtlB+R), RemB:=(CL-TtlB), B:=(RemB<B ? RemB : B), %DLP%( TtlB,LP )
		Sleep -1
	}
	TtlB<>CL ? VarSetCapacity( T,TtlB ) DllCall( "RtlMoveMemory", Str,T, Str,V, UInt,TtlB ) . VarSetCapacity( V,0 ) . VarSetCapacity( V,TtlB,32 ) . DllCall( "RtlMoveMemory", Str,V , Str,T, UInt,TtlB ) . %DLP%( TtlB, TtlB ) : N
	If ( !DllCall( LIB "InternetCloseHandle", UInt,hIU ) ) + ( !DllCall( LIB "InternetCloseHandle", UInt,hIO ) )
		Return -6
	Return, VarSetCapacity(V)+((ErrorLevel:=(RB>0 && TtlB<RB)||(RB=0 && TtlB=CL) ? 0 : 1)<<64)
}

DLP(WP=0, LP=0, MSG="")
{
	global INI,FN,T1,T2,WP1,WP2,SP
	GuiControl, Text, Label1, 正在下载：%FN%
	GuiControl,, MyProgress, % Round(WP/LP*100)
	DllCall("QueryPerformanceCounter", "Int64*", T2)
	DllCall("QueryPerformanceFrequency", "Int64*", TI)
	WP2:=WP
	if ((T:=(T2-T1)/TI) >=1)
	{
		SP:=Round(((WP2-WP1)/1024)/T,2)
		T1:=T2
		WP1:=WP2
	}
	WP:= ((WP:= Round(WP/1024)) < 1024) ? WP . " KB" : Round(WP/1024, 2) . " MB"
	LP:= ((LP:= Round(LP/1024)) < 1024) ? LP . " KB" : Round(LP/1024, 2) . " MB"
	GuiControl, Text, Label2, %WP% / %LP%
	GuiControl, Text, Label3, %SP% KB/S
}

VarZ_Save( byRef V, File="" ) { ; www.autohotkey.net/~Skan/wrapper/FileIO16/FileIO16.ahk
Return ( ( hFile := DllCall( "_lcreat", AStr,File, UInt,0 ) ) > 0 )
 ? DllCall( "_lwrite", UInt,hFile, Str,V, UInt,VarSetCapacity(V) )
 + ( DllCall( "_lclose", UInt,hFile ) << 64 ) : 0
}

Update(URL){
	static req := ComObjCreate("Msxml2.XMLHTTP")
	req.open("GET",URL,false)
	try req.Send()
	catch e
		return
	return req.responseText
}
