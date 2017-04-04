DetectHiddenWindows,On
#WinActivateForce
#Persistent
#SingleInstance force
#UseHook
#InstallKeybdHook
#ErrorStdOut
ComObjError(false)
SetBatchLines -1

;<<<<<<<<<<<<默认值>>>>>>>>>>>>
Path_data=%A_ScriptDir%\HotWindows.mdb	;数据库地址
FileRead,Edition,README.md
RegExMatch(Edition,"\b\d{6}\b",Edition)

;<<<<<<<<<<<<WIN10 WIN8中重要的设置值>>>>>>>>>>>>
RegRead,Bubble,HKEY_CURRENT_USER,SOFTWARE\Policies\Microsoft\Windows\Explorer,EnableLegacyBalloonNotifications
if not Bubble
	MsgBox,4,重要设置,脚本需要使用气泡提示点击Yes确定切换为气泡提示`n如需恢复请在启动后托盘设置中更改
		IfMsgBox Yes
		{
			RegWrite,REG_DWORD,HKEY_CURRENT_USER,SOFTWARE\Policies\Microsoft\Windows\Explorer,EnableLegacyBalloonNotifications,1
			RunWait %comspec% /c "taskkill /f /im explorer.exe",,Hide
			Run %comspec% /c "start c:\Windows\explorer.exe",,Hide
		}

Progress,,初始化,初始化请稍等...,HotWindows
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
Menu,Dele_mdb,Add,清除窗口记录,Dele_mdb_Gui
Menu,Dele_mdb,Add,清除程序记录,Dele_mdb_Exe
Menu,Dele_mdb,Add,清除样式记录,Dele_mdb_Style
Menu,Dele_mdb,Add,清除所有记录,Dele_mdb
Menu,Tray,Add,清除记录,:Dele_mdb
Menu,Tray,Add,添加程序,Add_exe
Menu,Tray,Add
Menu,Tray,Add,重启脚本,Reload
Menu,Tray,Add,退出脚本,ExitApp
Menu,Tray,Icon,显示方式,MenuIco.icl,6
Menu,Tray,Icon,激活热键,MenuIco.icl,4
Menu,Tray,Icon,添加程序,MenuIco.icl,1
Menu,Tray,Icon,清除记录,MenuIco.icl,2
Menu,Tray,Icon,重启脚本,MenuIco.icl,5
Menu,Tray,Icon,退出脚本,MenuIco.icl,3
Menu,Tray,NoStandard
Menu,Tray,Tip,HotWindows`n版本:%Edition%
Menu,Tray,Icon,MenuIco.icl,7
RegRead,HotRun,HKEY_CURRENT_USER,Software\Microsoft\Windows\CurrentVersion\Run,HotRun
RegRead,Bubble,HKEY_CURRENT_USER,SOFTWARE\Policies\Microsoft\Windows\Explorer,EnableLegacyBalloonNotifications
RegRead,Show_mode,HKEY_CURRENT_USER,HotWindows,HotShow_mode	;显示方式
RegRead,Hot_Set_key,HKEY_CURRENT_USER,HotWindows,HotHot_key	;激活热键
RegRead,Boot,HKEY_CURRENT_USER,HotWindows,Hotboot	;输入保护
RegRead,Styles,HKEY_CURRENT_USER,HotWindows,HotStyles	;样式列表
RegRead,Path_list,HKEY_CURRENT_USER,HotWindows,Path_list	;自定义程序添加规则
if not Path_list
	RegWrite,REG_SZ,HKEY_CURRENT_USER,HotWindows,Path_list,%A_Desktop%\*.lnk`n
RegRead,Path_list,HKEY_CURRENT_USER,HotWindows,Path_list	;自定义程序添加规则
if not Styles{
	Styles=0x14EF0000,0x15CF0000,0x34CF0000,0x860F0000,0x860E0000,0x36CF0000,0x17CF0000,0x84C80000,0xB4CF0000,0x94CA0000,0x95CF0000,0x94CF0000,0x94000000
	RegWrite,REG_MULTI_SZ,HKEY_CURRENT_USER,HotWindows,HotStyles,%Styles%
}
if not Hot_Set_key{
	Hot_Set_key=Space
	RegWrite,REG_SZ,HKEY_CURRENT_USER,HotWindows,HotHot_key,% Hot_Set_key
	Menu,Hot_key,ToggleCheck,Space
}else{
	Menu,Hot_key,ToggleCheck,%Hot_Set_key%
}
if not Show_mode{
	Show_mode=ListView
	RegWrite,REG_SZ,HKEY_CURRENT_USER,HotWindows,HotShow_mode,% Show_mode
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
if not Boot{
	Boot:=1
	RegWrite,REG_SZ,HKEY_CURRENT_USER,HotWindows,Hotboot,% Boot
	Menu,Tray,ToggleCheck,输入保护
}else if (Boot="1"){
	Menu,Tray,ToggleCheck,输入保护
}
if LastTime and (LastTime<Edition)
	MsgBox,4,升级成功,已从%LastTime%升级到%Edition%`n点击确定查看更新内容
	IfMsgBox Yes
		RunWait https://github.com/liumenggit/HotWindows#更新历史
RegWrite,REG_SZ,HKEY_CURRENT_USER,HotWindows,HotEdit,%Edition%

;<<<<<<<<<<<<热键创建>>>>>>>>>>>>
Layout=qwertyuiopasdfghjklzxcvbnm
Loop,Parse,Layout
{
	Layouts:=A_LoopField
	Loop,parse,Hot_keys,`,
	{
		Hotkey,~%A_LoopField% & %Layouts%,Layout
		if (Hot_Set_key!=A_LoopField)
			Hotkey,~%A_LoopField% & %Layouts%,off
	}
}
SysGet,Width,16
SysGet,Height,17
ListWidth:=Width/4

;<<<<<<<<<<<<声明全局变量>>>>>>>>>>>>
global Styles,Path_data,Show_mode,K_ThisHotkey,WHERE_list,Path_list,Ger,Gers,Starts,NewEdition

;<<<<<<<<<<<<检查更新>>>>>>>>>>>>
if W_InternetCheckConnection("https://github.com"){
	Progress,,确保网络联通,检查更新请稍等...,HotWindows

	ie:=ComObjCreate("InternetExplorer.Application") 
	ie.visible :=false
	ie.Navigate("http://onulm6njq.bkt.clouddn.com/index.html") 
	Loop {
		Sleep,200
		if (ie.readyState="complete" or ie.readyState=4 or A_LastError!=0)
			break
	}
	RegExMatch(ie.document.GetElementsByTagName("BODY").item(0).outertext,"(?<=\|.).*",NewCnzz)
	ie.quit()
	Progress,,%NewCnzz%,检查更新请稍等...,HotWindows

	whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	whr.Open("GET","https://raw.githubusercontent.com/liumenggit/HotWindows/master/README.md",false)
	Try{
		whr.Send()
		whr.WaitForResponse()
		RegExMatch(whr.ResponseText,"\b\d{6}\b",NewEdition)
	}catch e {
		Progress,,,检查更新出错...,HotWindows
	}
	;Edition=201701
	if (NewEdition>Edition){
		Progress,,确保网络联通,正在更新至%NewEdition%...,HotWindows
		gosub,Downloand
	}
}

;<<<<<<<<<<<<DLL载入>>>>>>>>>>>>
tcmatch := "Tcmatch.dll"
hModule := DllCall("LoadLibrary", "Str", tcmatch, "Ptr")

;<<<<<<<<<<<<GUI>>>>>>>>>>>>
;http://new.cnzz.com/v1/login.php?siteid=1261658612
Gui,+AlwaysOnTop +Border -SysMenu +ToolWindow +LastFound +HwndMyGuiHwnd
Gui,Add,ListView,w%ListWidth% r9 xm ym AltSubmit gHot_ListView,编号|标题	;
Gui,Add,StatusBar
WinSet,Transparent,200,ahk_id %MyGuiHwnd%

;<<<<<<<<<<<<创建SQL表>>>>>>>>>>>>
FileDelete,%Path_data%
IfNotExist,%Path_data%
{
	Catalog:=ComObjCreate("ADOX.Catalog")
	Catalog.Create("Provider='Microsoft.Jet.OLEDB.4.0';Data Source=" Path_data)
	SQL_Run("CREATE TABLE Now_list(Title varchar(255),Pid varchar(255),Path varchar(255),GetStyle varchar(255))")	;添加程序数据库表
	SQL_Run("CREATE TABLE Activate(Title varchar(255),Times varchar(255))")	;添加程序数据库表
	SQL_Run("CREATE TABLE Quick(Title varchar(255),Pid varchar(255),Path varchar(255),GetStyle varchar(255))")	;添加程序数据库表
}else{
	SQL_Run("DELETE FROM Now_list")
}

;<<<<<<<<<<<<加载列表>>>>>>>>>>>>
Load_list()	;创建初始程列表
TrayTip,HotWindows,准备完成开始使用`n当前版本号：%Edition%`n捐赠支付宝：rrsyycm@163.com`n%NewCnzz%,,1
;<<<<<<<<<<<<主要循环>>>>>>>>>>>>
loop{
	WinGet,Wina_ID,ID,A
	WinGet,Exe_Name,ProcessName,ahk_id %Wina_id%
	WinGet,Get_Style,Style,ahk_id %Wina_id%
	if Get_Style not in %Styles%
	{
		Styles=%Styles%`,%Get_Style%
		RegWrite,REG_SZ,HKEY_CURRENT_USER,HotWindows,HotStyles,% Styles
	}
	Load_exe(Exe_Name)
	WinWaitNotActive,ahk_id %Wina_id%
	Load_exe(Exe_Name)
}
Return

;<<<<<<<<<<<<主要功能的标签>>>>>>>>>>>>
Layout:
	StringRight,H_ThisHotkey,A_ThisHotkey,1
	K_ThisHotkey:=K_ThisHotkey H_ThisHotkey
	StrLens := StrLen(K_ThisHotkey)
	ToolTip,,%K_ThisHotkey%
	if StrLens=1
		loop,9{
			Hotkey,%A_Index%,Table
			Hotkey,%A_Index%,On
		}
	SQL_List("SELECT Activate.title,Activate.times,t1.pid,t1.path,t1.getstyle FROM Activate LEFT JOIN (SELECT * FROM Now_list UNION SELECT * FROM Quick) AS t1 ON Activate.title = t1.title WHERE t1.pid IS NOT NULL OR t1.path IS NOT NULL ORDER BY Activate.Times +- 1 DESC,t1.GetStyle DESC",K_ThisHotkey)
	if WHERE_list.Length() and K_ThisHotkey{
		Show_list(WHERE_list)
		if (WHERE_list.Length()="1"){
			Activate("1")
			Send {%Hot_Set_key% Up}
		}
	}else{
		Cancel()
	}
	if StrLens=1
		SetTimer,Key_wait,200
Return


Table:
	Activate(A_ThisHotkey)
Return

Key_wait:
	SetTimer,Key_wait,off
	KeyWait,%Hot_Set_key%,L
	if not K_ThisHotkey
		Return
	if (EventInfo<>"0") and (Show_mode="ListView"){
		if (Boot="1") and (StrLens="1")
			Cancel()
		if (Boot="2")
			Activate(EventInfo)
		if (Boot="1") and (StrLens>"1")
			Activate(EventInfo)
		Return
	}
	if (Boot="1") and (StrLens="1")	;开启了输入保护什么也没有发生
		Cancel()
	if (Boot="2")	;没有开启输入保护激活第一个
		Activate("1")
	if (Boot="1") and (StrLens>"1")	;开启了输入保护发生了事情
		Activate("1")
Return

Add_exe:
Gui,New
Gui,Add_exe:New
Gui,Add_exe:+LabelMyAdd +ToolWindow +AlwaysOnTop
Gui,Add_exe:Add,Text,xm,添加程序请将文件拖入本窗口
Gui,Add_exe:Add,ListView,xm w%ListWidth% vAdd_list r9,名称|路径
Gui,Add_exe:Add,Text,xm,此处添加程序目录c:\Users\*.exe或c:\Users\*.lnk
Gui,Add_exe:Add,Edit,xm w%ListWidth% r5 vPath_list,%Path_list%
Gui,Add_exe:Add,Button,xm Section gDele_exe,删除选择程序(&D)
Gui,Add_exe:Add,Button,ys gSubmit_exe,保存规则(&S)
Gui,Add_exe:Show,,添加程序到热启动列表
Add_list()
Return

Submit_exe:
	TrayTip,HotWindows,等待操作完成,,1
	Gui,Submit,NoHide
	RegWrite,REG_SZ,HKEY_CURRENT_USER,HotWindows,Path_list,%Path_list%
	Load_list()
	Add_list()
	TrayTip,HotWindows,保存完成,,1
Return

Dele_exe:
Gui,ListView,Add_list
RowNumber=0
Loop
{
    RowNumber:=LV_GetNext(RowNumber)
    if not RowNumber
        break
    LV_GetText(dPath,RowNumber,2)
	SQL_Run("DELETE FROM Quick WHERE Path='" dPath "'")
}
Add_list()
TrayTip,HotWindows,删除完成,,3
Gui,ListView,Hot_ListView
Return

MyAddDropFiles:
Loop,Parse,A_GuiEvent,`n
	Add_quick(A_LoopField)
Add_list()
TrayTip,HotWindows,添加完成,,1
Return

Hot_ListView:
EventInfo:=LV_GetNext()
Return
;<<<<<<<<<<<<窗口函数>>>>>>>>>>>>
Add_list(){
	Recordset := ComObjCreate("ADODB.Recordset")
	Recordset.Open("SELECT Title,Path FROM Quick","Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" . Path_data . "")
	GuiControl,-Redraw,Add_list
	LV_Delete()
	while !Recordset.EOF
	{
		IfExist,% Recordset.Fields["Path"].Value
			LV_Add("" ,Recordset.Fields["Title"].Value,Recordset.Fields["Path"].Value)
		else
			SQL_Run("DELETE FROM Quick WHERE Path='" Recordset.Fields["Path"].Value "'")
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
	if Activate{
		WinActivate,ahk_id %Activate%
	}else{
		Try RunWait %Path%
		catch e
			Return
	}
	if not Sql_Get("SELECT Times FROM Activate WHERE Title='" Title "'")
		SQL_Run("Insert INTO Activate (Title,Times) VALUES ('" Title "','1')")
	else
		SQL_Run("UPDATE Activate SET Times = Times+1 WHERE Title='" Title "'")
}

Cancel(){
	if K_ThisHotkey
		loop,9
			Hotkey,%A_Index%,off
	if Show_mode=ListView
		Gui,Cancel
	else
		TrayTip
	K_ThisHotkey:=
	Send {%Hot_Set_key% Up}
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
		SB_SetText("按键历史：" . K_ThisHotkey . "")
		LV_Modify(1,"Select")
		LV_Modify(1,"Focus")
		GuiControl,+Redraw,MyListView
		Gui,Show,AutoSize Center,HotWindows
	}else{
		Tip_list:=K_ThisHotkey
		For k,v in WHERE_list
		{
			if v.Pid
				Level=○
			else
				Level=●
			Tip_list:=Tip_list "`n" k Level SubStr(v.Title,"1","25")
		}
		TrayTip,,%Tip_list%
	}
	if not K_ThisHotkey
		Cancel()
}

;<<<<<<<<<<<<生成数据>>>>>>>>>>>>
Load_list(){
	Suspend,On
	DetectHiddenWindows,Off
	WinGet,ID_list,List,,,Program Manager
	DetectHiddenWindows,On
	Ger:=100//ID_list
	Gers:=0
	loop,%ID_list%
	{
		This_id := ID_list%A_Index%
		WinGet,Exe_Name,ProcessName,ahk_id %This_id%
		IfNotInString,Exe_Names,%Exe_Name%
			Load_exe(Exe_Name)
		else
			Gers+=100//ID_list
		Exe_Names=%Exe_Name%`n%Exe_Names%
	}
	Starts=Yes
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
	loop,Parse,Path_list,`n
		loop,%A_LoopField%
			Add_quick(A_LoopFileLongPath)
	Add_list()
    Progress,100
	Progress,Off
	Suspend,Off
}
Load_exe(Exe_Name){
	if not Exe_Name
		return
	SQL_Run("DELETE FROM Now_list WHERE Path LIKE '%" Exe_Name "'")
	WinGet,WinList,List,ahk_exe %Exe_Name%
	WinGet,Path,ProcessPath,ahk_exe %Exe_Name%
	SplitPath,Path,OutFileName,OutDir,OutExtension,OutNameNoExt,OutDrive
	;Windowsvar=C:\Windows\
	Add_quick(Path)
	loop,%WinList% {
		PID:=WinList%A_Index%
		WinGet,GetStyle,Style,ahk_id %PID%
		WinGetTitle,Title,ahk_id %PID%
		WinGet,Path,ProcessPath,ahk_id %PID%
		if not Starts
    		Progress,% Gers+=Ger/WinList ,% Title,构建当前窗口信息...,HotWindows
		if GetStyle in %Styles%
			if Title and GetIconCount(Path){
				if Sql_Get("SELECT COUNT(*) FROM Now_list WHERE Title='" Title "'")
					continue
				SQL_Run("Insert INTO Now_list (Title,PID,Path,GetStyle) VALUES ('" Title "','" PID "','" Path "','" GetStyle "')")
				if not Sql_Get("SELECT Times FROM Activate WHERE Title='" Title "'")
					SQL_Run("Insert INTO Activate (Title,Times) VALUES ('" Title "','1')")
			}
	}
}

Add_quick(Path){
	IfNotInString,Path,%A_WinDir%
	{
		SplitPath,Path,OutFileName,OutDir,OutExtension,OutNameNoExt,OutDrive
			if not Sql_Get("SELECT COUNT(*) FROM Quick WHERE Path='" Path "'"){
				SQL_Run("DELETE FROM Quick WHERE Path='" Path "'")
				SQL_Run("Insert INTO Quick (Title,Path) VALUES ('" OutNameNoExt "','" Path "')")
				if not Sql_Get("SELECT Times FROM Activate WHERE Title='" OutNameNoExt "'")
					SQL_Run("Insert INTO Activate (Title,Times) VALUES ('" OutNameNoExt "','1')")
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
	RunWait %comspec% /c "taskkill /f /im explorer.exe",,Hide
	Run %comspec% /c "start c:\Windows\explorer.exe",,Hide
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
	Loop,Parse,Layout
	{
		Hotkey,~%Hot_Set_key% & %A_LoopField%,off
		Hotkey,~%A_ThisMenuItem% & %A_LoopField%,On
	}
	Hot_Set_key:=A_ThisMenuItem
	Loop,parse,Hot_keys,`,
		Menu,Hot_key,Uncheck,%A_LoopField%
	Menu,Hot_key,ToggleCheck,%Hot_Set_key%
	RegWrite,REG_SZ,HKEY_CURRENT_USER,HotWindows,HotHot_key,%A_ThisMenuItem%
Return

Boot:
RegRead,Boot,HKEY_CURRENT_USER,HotWindows,Hotboot	;输入保护
if Boot=1
	Boot=2
else
	Boot=1
RegWrite,REG_SZ,HKEY_CURRENT_USER,HotWindows,Hotboot,%Boot%
Menu,Tray,ToggleCheck,输入保护
Return

Dele_mdb:
	TrayTip,HotWindows,等待操作完成,,1
	SQL_Run("DELETE FROM Activate")
	SQL_Run("DELETE FROM Now_list")
	SQL_Run("DELETE FROM Quick")
	RegDelete,HKEY_CURRENT_USER,HotWindows,HotStyles
	RegDelete,HKEY_CURRENT_USER,HotWindows,Path_list
	Load_list()
	TrayTip,HotWindows,已经清除所有记录,,1
Return

Dele_mdb_Gui:
	TrayTip,HotWindows,等待操作完成,,1
	SQL_Run("DELETE FROM Activate")
	Load_list()
	TrayTip,HotWindows,已经清除窗口记录,,1
Return

Dele_mdb_Exe:
	TrayTip,HotWindows,等待操作完成,,1
	SQL_Run("DELETE FROM Quick")
	RegDelete,HKEY_CURRENT_USER,HotWindows,Path_list
	Load_list()
	TrayTip,HotWindows,已经清除程序记录,,1
Return

Dele_mdb_Style:
	TrayTip,HotWindows,等待操作完成,,1
	RegDelete,HKEY_CURRENT_USER,HotWindows,HotStyles
	Load_list()
	TrayTip,HotWindows,已经清除样式记录,,1
Return

Reload:
	Reload
ExitApp:
	ExitApp

;<<<<<<<<<<<<SQL函数>>>>>>>>>>>>
SQL_List(SQL,K_ThisHotkey){
	Recordset := ComObjCreate("ADODB.Recordset")
	Recordset.Open(SQL,"Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" . Path_data . "")
	WHERE_list := Object()
	WHERE_time :=
	while !Recordset.EOF
	{
		wPID:=Recordset.Fields["PID"].Value
		wPath:=Recordset.Fields["Path"].Value
		if wPID
		{
			IfWinNotExist,ahk_id %wPID%
			{
				SQL_Run("DELETE FROM Now_list WHERE PID='" Recordset.Fields["PID"].Value "'")
				Recordset.MoveNext()
				Continue
			}
		}
		else if wPath
		{
			IfNotExist,%wPath%
			{
				SQL_Run("DELETE FROM Now_list WHERE Path='" Recordset.Fields["Path"].Value "'")
				Recordset.MoveNext()
				Continue
			}
		}
		if (matched := DllCall("Tcmatch\MatchFileW","WStr",K_ThisHotkey,"WStr",Recordset.Fields["Title"].Value)){
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
	Try Recordset.Open(SQL,"Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" . Path_data . "")
	catch e
		Return 0
	Try Return Recordset.Fields[0].Value
	catch e
		Return 0
}

;<<<<<<<<<<<<更新功能>>>>>>>>>>>>
Downloand:
	Progress,,确保网络联通,正在更新至%NewEdition%...,HotWindows
	SysGet, m, MonitorWorkArea,1
	x:=A_ScreenWidth-520
	y:=A_ScreenHeight-180
	URL=https://codeload.github.com/liumenggit/HotWindows/zip/master
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
		Progress,100,下载完成,正在更新至%NewEdition%...,HotWindows
		SmartZip(SAVE,A_ScriptDir "\" NewEdition)
		FileDelete,%SAVE%
		gosub,ExitSub
		ExitApp
	}else{
		ERR := (E<0) ? "下载失败，错误代码为" . E : "下载过程中出错，未能完成下载。请手动更新。"
		Progress,0,%ERR%,正在更新至%NewEdition%...,HotWindows
		Sleep, 500
		return
	}
	DllCall( "FreeLibrary", UInt,DllCall( "GetModuleHandle", Str,"wininet.dll") )
return

ExitSub:
	;rd /s/q %D_history%
bat=
		(LTrim
:start
	ping 127.0.0.1 -n 2>nul
	del `%1
	if exist `%1 goto start
	xcopy %A_ScriptDir%\%NewEdition%\HotWindows-master %A_ScriptDir% /s/e/y
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
	Progress,% Round(WP/LP*100),%WP% / %LP%    %SP% KB/S,正在更新至%NewEdition%...,HotWindows
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
	Progress,,%WP% / %LP%    %SP% KB/S,正在更新至%NewEdition%...,HotWindows
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
