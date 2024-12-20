#Requires AutoHotkey v2.0
#Include WatchFolder.ahk
;调试
; ListLines()
;工具属性
;@Ahk2Exe-SetVersion 1.1
;@Ahk2Exe-SetName 育碧存档全自动备份
;@Ahk2Exe-SetCompanyName GameXueRen
;@Ahk2Exe-SetCopyright © 2024 GameXueRen

;以管理员身份运行
runAsAdmin()

;工具名称与版本
toolName := "育碧存档全自动备份"
toolVersion := "Beta1.1"


;配置文件
profilesName := toolName "配置.ini"
mainConfigName := "main"
ubiGameIdConfigName := "ubiGameIdInfo"
;主配置Key
ubiSaveDirPathKey := "ubiSaveDirPath"
userIdKey := "userId"
gameIdKey := "gameId"
backupDirPathKey := "backupDirPath"
backupLimitMethodKey := "backupLimitMethod"
backupLimitDataKey := "backupLimitData"
backupLimitTimeKey := "backupLimitTime"
backupLimitCountKey := "backupLimitCount"
minBackupTimeKey := "minBackupTime"
isEnableHotkeyKey := "isEnableHotkey"
backupHotkeyKey := "backupHotkey"
isEnableGMAutoSaveKey := "isEnableGMAutoSave"
isAutoPopUpKey := "isAutoPopUp"
cacheLevelKey := "cacheLevel"
;备份信息配置文件
backupInfoIniName := "gmxrBackupInfo.ini"
backupInfoKey := "info"
;隐性扩展配置Key
maxShowLogCountKey := "maxShowLogCount"
isShowTipKey := "isShowTip"
isPlayBackupSoundKey := "isPlayBackupSound"

;全局变量
;存档目录
saveGamesDir := ""
;当前用户ID、游戏ID
currentUserId := ""
currentGameId := ""
;备份目录
backupSaveDir := ""
;已备份用户ID、游戏ID
backedupUserId := ""
backedupGameId := ""
;手动备份热键
backupHotkey := ""
;是否启用幽灵模式自动续档
isEnableGMAutoSave := false
;最大运行日志条数
maxShowLogCount := 200
;是否开启监测存档变化
isOpenWatchSave := false
;是否播放手动备份成功提示音
isPlayBackupSound := true
;游戏扩展界面
extensionGui := ""

;全局常量
backLimitTextArr := ["MB(10-9999)", "天(1-366)", "份(1-9999)"]
;幽灵模式缓存扩展名
lastCacheExt := "gmxrGhostCache"
defaultBackupInfo := "自动备份"

myGui := Gui(, toolName toolVersion)
guiMarginX := 8
guiMarginY := 8
myGui.MarginX := guiMarginX
myGui.MarginY := guiMarginY

creatMyGuiCtrl()

addMyGuiCtrlEvent()

addMyGuiCtrlTip()

myGui.Show()

customTrayMenu()

loadMainCtrlData()
return

;创建控件
creatMyGuiCtrl(*)
{
    global tabW := 420
    buttonH := 32
    userLogoW := 64

    global tabCtrl := myGui.AddTab3("xm ym Choose1 w" tabW , ["设置备份", "管理备份"])

    tabCtrl.UseTab(1)
    saveDirText := myGui.AddText("+0x200 c800000 Section h" buttonH, "育碧游戏存档目录：")
    global autoDetectBtn := myGui.AddButton("hp x+" guiMarginX, "重新探测")
    global selectSaveDirBtn := myGui.AddButton("hp x+" guiMarginX, "手动选择")
    global openSaveDirBtn := myGui.AddButton("hp x+" guiMarginX, "打开目录")
    
    global ubiSaveDirEdit := myGui.AddEdit("R1 ReadOnly xs w" tabW-guiMarginX*2, "")
    
    userIdDDLW := 279
    gameIdDDLW := 244
    
    myGui.AddText("+0x200 c800000 Section xs h22", "用户ID：")
    global userIdDDL := myGui.AddDropDownList("x+" guiMarginX " w" userIdDDLW)
    
    myGui.AddText("+0x200 c800000 Section xs h22", "游戏ID：")
    global gameIdDDL := myGui.AddDropDownList("x+" guiMarginX " w" gameIdDDLW)
    global editGameNameBtn := myGui.AddButton("Disabled h22 yp-1 x+1 w" userIdDDLW-gameIdDDLW-1, "编辑")
    
    ;添加分割线
    myGui.AddText("0x10 h1 w" tabW " xs-" guiMarginX)
    
    backupDirText := myGui.AddText("+0x200 c800000 Section xs h" buttonH, "游戏存档备份目录：")
    global selectBackupDirBtn := myGui.AddButton("hp x+" guiMarginX, "选择目录")
    global openBackupDirBtn := myGui.AddButton("hp x+" guiMarginX, "打开目录")
    global managerBackupBtn := myGui.AddButton("hp x+" guiMarginX, "还原备份")
    global openExtensionBtn := myGui.AddButton("Hidden hp x+" guiMarginX, "游戏扩展>>")
    openExtensionBtn.SetFont("bold")
    
    global backupDirEdit := myGui.AddEdit("R1 ReadOnly xs w" tabW - guiMarginX * 2)
    
    ;备份限制
    myGui.AddText("+0x200 Section xs h22", "备份限制：")
    global backupLimitDDL := myGui.AddDropDownList("Choose1 w96 x+" guiMarginX, ["最大备份空间", "最大保留天数", "最大备份数量"])
    global backupLimitEdit := myGui.AddEdit("R1 Number w40 x+4", "1000")
    global backupLimitText := myGui.AddText("+0x200 h22 x+4", backLimitTextArr[1])
    
    myGui.AddText("+0x200 Section xs h22", "最小备份间隔：")
    global minBackupTimeEdit := myGui.AddEdit("R1 Number w40 x+" guiMarginX, "5")
    myGui.AddText("+0x200 h22 x+4", "分钟(1-180)")

    global isEnableHotkeyCB := myGui.AddCheckbox("Section Checked xs h22 w160", "启用“手动备份”快捷键：")
    global backupHotkeyCtrl := myGui.AddHotkey("Limit192 hp w108 x+" guiMarginX, "F1")
    
    ;添加分割线
    myGui.AddText("0x10 h1 w" tabW-guiMarginX " xs-" guiMarginX)
    
    logBtnW := 32
    global logMaxCountText := myGui.AddText("+0x200 Section xs y+2 h22", "运行日志(最多200条)：")
    global exportLogBtn := myGui.AddButton("hp x+" guiMarginX, "导出")
    global clearLogBtn := myGui.AddButton("hp x+" guiMarginX, "清空")
    ;运行日志列表
    global logListView := myGui.AddListView("xs y+2 Count210 NoSortHdr NoSort ReadOnly -Hdr h140 w" tabW-guiMarginX*2, ["运行日志(最多200条)"])
    logListView.ModifyCol(1, "AutoHdr")

    ;启动按钮。暂时只能用progress来充当背景色，原生Button及Text无法设置背景色
    startBtnW := 122
    ; global startBtn := myGui.AddButton("y242 h120 w" startBtnW " x" tabW-startBtnW+3, "启动")
    global startBackground := myGui.AddProgress("BackgroundDefault y244 h117 Disabled w" startBtnW " x" tabW-startBtnW+2)
    global startBtn := myGui.AddText("0x200 BackgroundTrans Border Center xp yp hp wp", "启动")
    startBtn.SetFont("s26 bold")
    startBtn.gmxrStatus := false

    ;用户头像
    global userLogoHolder := myGui.AddText("0x200 C808080 Border Center y100 w64 h64 x" tabW-64+1, "用户头像")
    global userLogoPicCtrl := myGui.AddPicture("y100 w64 h64 x" tabW-64 + 1)
    userLogoPicCtrl.Visible := false
    
    tabCtrl.UseTab(2)
    backupIdDDLW := 254
    myGui.AddText("+0x200 c800000 Section h22", "已备份用户ID")
    global backupUserIdDDL := myGui.AddDropDownList("x+" guiMarginX " w" backupIdDDLW)

    myGui.AddText("+0x200 c800000 Section xs h22", "已备份游戏ID")
    global backupGameIdDDL := myGui.AddDropDownList("x+" guiMarginX " w" backupIdDDLW)

    global backupListView := myGui.AddListView("Section xs Grid Checked Count100 ReadOnly h346 w" tabW-guiMarginX*2, ["备份时间(右键管理)","备份文件夹", "大小(MB)", "备注"])
    backupListView.ModifyCol(1, 142)
    backupListView.ModifyCol(2, 98)
    backupListView.ModifyCol(3, 62)
    backupListView.ModifyCol(4, "AutoHdr")

    managerBtnW := Floor((tabW - guiMarginX * 2 - guiMarginX * 2 * 3) / 4)
    backupBtnH := 50
    global rcyLastBackupBtn := myGui.AddButton("xs w88 h" backupBtnH, "还原最新`n备份存档")
    global rcyChooseBackupBtn := myGui.AddButton("wp hp x+" guiMarginX*2, "还原表中`n勾选存档")
    global openChooseBackupBtn := myGui.AddButton("wp hp x+" guiMarginX*2, "打开表中`n勾选存档")
    global delChooseBackupBtn := myGui.AddButton("wp hp x+" guiMarginX*2, "删除表中`n勾选存档")
    rcyLastBackupBtn.SetFont("s12 bold")
    openChooseBackupBtn.SetFont("s12 bold")
    rcyChooseBackupBtn.SetFont("s12 bold")
    delChooseBackupBtn.SetFont("s12 bold")

    ;备份一栏用户头像
    global backupUserLogoHolder := myGui.AddText("0x200 C808080 Border Center y32 w64 h64 x" tabW-64+1, "用户头像")
    global backupUserLogoPicCtrl := myGui.AddPicture("y32 w64 h64 x" tabW-64 + 1)
    backupUserLogoPicCtrl.Visible := false

    tabCtrl.UseTab(0)
    ;帮助&关于
    helpBtnW := 70
    global helpBtn := myGui.AddButton("h22 yp x+-" helpBtnW+2 " w" helpBtnW, "帮助/关于")
    global toolLink :=myGui.AddLink("right c800000 yp+4 h12 xp-136", '开源:<a href="https://github.com/GameXueRen/UbiSaveAutoBackup">UbiSaveAutoBackup</a>')
}
;添加控件事件
addMyGuiCtrlEvent(*)
{
    ;添加Tab1里的控件事件
    autoDetectBtn.OnEvent("Click", autoDetect)
    selectSaveDirBtn.OnEvent("Click", selectSaveDir)
    openSaveDirBtn.OnEvent("Click", openSaveDir)
    userIdDDL.OnEvent("Change", changeUserID)
    gameIdDDL.OnEvent("Change", changeGameID)
    editGameNameBtn.OnEvent("Click", editGameName)

    selectBackupDirBtn.OnEvent("Click", selectBackupDir)
    openBackupDirBtn.OnEvent("Click", openBackupDir)
    managerBackupBtn.OnEvent("Click", managerBackup)

    backupLimitDDL.OnEvent("Change", changeBackupLimitMethod)
    backupLimitEdit.OnEvent("Change", changeBackupLimitValue)

    minBackupTimeEdit.OnEvent("Change", changeMinBackupTime)

    isEnableHotkeyCB.OnEvent("Click", enableHotkey)
    backupHotkeyCtrl.OnEvent("Change", changeBackupHotkey)

    openExtensionBtn.OnEvent("Click", openGameExtension)

    startBtn.OnEvent("Click", startBtnClick)

    exportLogBtn.OnEvent("Click", exportLog)
    clearLogBtn.OnEvent("Click", clearLog)
    logListView.OnEvent("ContextMenu", logListViewContextMenu)

    ;添加Tab2里的控件事件
    backupUserIdDDL.OnEvent("Change", changeBackupUserId)
    backupGameIdDDL.OnEvent("Change", changeBackupGameId)
    backupListView.OnEvent("ContextMenu", backupListViewContextMenu)

    rcyLastBackupBtn.OnEvent("Click", rcyLastBackup)
    openChooseBackupBtn.OnEvent("Click", openChooseBackup)
    rcyChooseBackupBtn.OnEvent("Click", rcyChooseBackup)
    delChooseBackupBtn.OnEvent("Click", delChooseBackup)

    ;Tab切换事件
    tabCtrl.OnEvent("Change", changeTab)

    helpBtn.OnEvent("Click", showHelpInfo)

    ;工具退出
    myGui.OnEvent("Close", myGuiClose)
    myGui.OnEvent("Size", myGuiSize)
    ;退出之前的处理
    OnExit(exitAppFunc)
}
;定制托盘右键菜单
customTrayMenu(*)
{
    ;托盘右键菜单定制
    A_TrayMenu.Delete()
    A_TrayMenu.Add("打开", clickOpen(*) => myGui.Show())
    A_TrayMenu.Add("重新加载", clickReload)
    A_TrayMenu.Add("退出", clickExit)
    A_TrayMenu.ClickCount := 1
    A_TrayMenu.Default := "打开"
    A_IconTip := toolName toolVersion
}
;加载配置文件数据及刷新控件
loadMainCtrlData(*)
{
    ;加载配置文件数据及预处理
    global saveGamesDir := readMainCfg(ubiSaveDirPathKey)
    global backupSaveDir := readMainCfg(backupDirPathKey, "C:\Users\" A_UserName "\Saved Games\育碧存档备份")
    global currentUserId := readMainCfg(userIdKey)
    global currentGameId := readMainCfg(gameIdKey)

    backupLimitMethod := readMainCfg(backupLimitMethodKey, "1")
    minBackupTime := readMainCfg(minBackupTimeKey, "5")
    isEnableHotkey := readMainCfg(isEnableHotkeyKey, "1")
    global backupHotkey := readMainCfg(backupHotkeyKey, "F1")
    readMaxShowLogCount := readMainCfg(maxShowLogCountKey, "200")
    if !IsInteger(readMaxShowLogCount)
        readMaxShowLogCount := 200
    if readMaxShowLogCount < 1
        readMaxShowLogCount := 1
    global maxShowLogCount := readMaxShowLogCount
    readEnableGMAutoSave := readMainCfg(isEnableGMAutoSaveKey, "0")
    if (readEnableGMAutoSave = "1")
    {
        global isEnableGMAutoSave := true
    } else
    {
        global isEnableGMAutoSave := false
    }
    readPlaySound := readMainCfg(isPlayBackupSoundKey, "1")
    if (readPlaySound = "0")
    {
        isPlayBackupSound := false
    } else
    {
        isPlayBackupSound := true
    }

    ;更新控件
    if saveGamesDir && DirExist(saveGamesDir)
    {
        changeUbiSaveDir(saveGamesDir)
    }else
    {
        autoDetect()
    }
    changeBackupDir(backupSaveDir)
    
    if !IsInteger(backupLimitMethod)
        backupLimitMethod := 1
    if (backupLimitMethod < 1)
        backupLimitMethod := 1
    else if (backupLimitMethod > 3)
        backupLimitMethod := 3
    ControlChooseIndex(backupLimitMethod, backupLimitDDL, myGui)
    
    if !IsInteger(minBackupTime)
        minBackupTime := 5
    if (minBackupTime < 1)
        minBackupTime := 1
    if (minBackupTime > 180)
        minBackupTime := 180
    minBackupTimeEdit.Text := minBackupTime
    
    if isEnableHotkey
    {
        ControlSetChecked(1, isEnableHotkeyCB, myGui)
    }else
    {
        ControlSetChecked(0, isEnableHotkeyCB, myGui)
    }
    backupHotkeyCtrl.Value := backupHotkey
    logMaxCountText.Text := "运行日志(最多" maxShowLogCount "条)："
    if FileExist(profilesName)
    {
        addRuningLog("已加载配置文件数据")
    }
}
;添加控件提示
addMyGuiCtrlTip(*)
{
    isShowTip := readMainCfg(isShowTipKey, "1")
    if (isShowTip = "0")
    {
        GuiSetTipEnabled(myGui, false)
        return
    }
	ControlAddTip(autoDetectBtn, "自动探测“育碧平台安装目录”`n并自动识别获取“育碧游戏存档目录”")
	ControlAddTip(selectSaveDirBtn, "手动选择“育碧游戏存档目录”`n一般为“育碧平台安装目录”下的`nsavegames目录")
	ControlAddTip(openSaveDirBtn, "打开“育碧游戏存档目录”")
	ControlAddTip(userLogoPicCtrl, "“用户ID”对应的育碧账户头像")
	ControlAddTip(editGameNameBtn, "编辑“游戏ID”对应的游戏名称`n并保存到下次显示")
	ControlAddTip(selectBackupDirBtn, "选择“游戏存档备份目录”`n此为备份总目录")
	ControlAddTip(openBackupDirBtn, "打开“游戏存档备份目录”")
	ControlAddTip(managerBackupBtn, "管理当前选择的用户ID及游戏ID的`n已备份存档")
	ControlAddTip(backupLimitDDL, "选择“备份限制”方式(三选一)`n当该游戏所有备份达到限制后`n运行时会依次清理超过限制的最早备份")
    ControlAddTip(backupLimitEdit, "输入“备份限制”数值，达到该限制后`n运行时会依次清理超过限制的最早备份")
	ControlAddTip(minBackupTimeEdit, "与上一次备份的最小间隔时间，运行时`n仅当超过该间隔时间且存档有变化时`n才执行下一次备份")
	ControlAddTip(isEnableHotkeyCB, "启用后，运行时`n可随时按下设定的快捷键`n来执行“手动备份”")
	ControlAddTip(backupHotkeyCtrl, "按下对应的按键来设置`n支持设置组合按键：`n比如F1、Ctrl+B、Ctrl+Alt+B等等")
	ControlAddTip(rcyLastBackupBtn, "建议在游戏未运行状态下`n进行“还原存档”操作")
	ControlAddTip(rcyChooseBackupBtn, "建议在游戏未运行状态下`n进行“还原存档”操作")
	ControlAddTip(toolLink, "https://github.com/GameXueRen/UbiSaveAutoBackup")
	GuiSetTipDelayTime(myGui, 800)
	GuiSetTipEnabled(myGui, true)
}

;切换选项卡---------------------------------------------------------------------------------
changeTab(GuiCtrlObj, info)
{
    index := GuiCtrlObj.Value
    if (index = 1)
    {
        if extensionGui
        {
            openGameExtension()
        }
        return
    }else if (index = 2)
    {
        if extensionGui
        {
            extensionGui.Hide()
        }
        ;判断是否需要重新加载备份列表数据
        if (currentUserId = backedupUserId) && (currentGameId = backedupGameId)
            return
        backupUserIdDDL.Delete()
        userIdIndex := 0
        if backupSaveDir
        {
            if DirExist(backupSaveDir)
            {
                userIdArr := Array()
                loop files backupSaveDir "\*", "D"
                {
                    if !RegExMatch(A_LoopFileName, "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}")
                        continue
                    userIdArr.Push(A_LoopFileName)
                    if (currentUserId = A_LoopFileName)
                    {
                        userIdIndex := userIdArr.Length
                    }
                }
                backupUserIdDDL.Add(userIdArr)
            } else
            {
                addRuningLog("“游戏存档备份目录”不存在：" backupSaveDir)
            }
        } else
        {
            addRuningLog("“游戏存档备份目录”为空！")
        }
        global backedupUserId := currentUserId
        global backedupGameId := currentGameId
        ControlChooseIndex(userIdIndex, backupUserIdDDL, myGui)
        rcyLastBackupBtn.Focus()
    }
}

;Tab1子控件事件---------------------------------------------------------------------------------
;改变存档目录
changeUbiSaveDir(ubiSaveDir)
{
    ;加载新数据
    userIdDDL.Delete()
    userIdIndex := 0
    if ubiSaveDir
    {
        if DirExist(ubiSaveDir)
        {
            userIdArr := Array()
            loop files ubiSaveDir "\*", "D"
            {
                if !RegExMatch(A_LoopFileName, "\w{8}-\w{4}-\w{4}-\w{4}-\w{12}")
                    continue
                userIdArr.Push(A_LoopFileName)
                if (currentUserId = A_LoopFileName)
                {
                    userIdIndex := userIdArr.Length
                }
            }
            userIdDDL.Add(userIdArr)
        } else
        {
            addRuningLog("“育碧游戏存档目录”不存在：" ubiSaveDir)
        }
    }else
    {
        addRuningLog("“育碧游戏存档目录”为空！")
    }
    if saveGamesDir != ubiSaveDir
    {
        global saveGamesDir := ubiSaveDir
        writeMainCfg(ubiSaveDir, ubiSaveDirPathKey)
    }
    ubiSaveDirEdit.Text := ubiSaveDir
    ControlChooseIndex(userIdIndex, userIdDDL, myGui)
}
;重新探测存档目录
autoDetect(*)
{
    showLoading(true, "自动探测中...")
    ubiInstallDir := RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Ubisoft\Launcher", "InstallDir", "C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher")
    ubiInstallDir := RTrim(ubiInstallDir, "\")
    if !DirExist(ubiInstallDir)
    {
        showLoading(false)
        addRuningLog("未探测到“育碧游戏存档目录”！")
        return false
    }
    ubiSaveDir := ubiInstallDir "\savegames"
    if !DirExist(ubiSaveDir)
    {
        ;存档目录不存在
        showLoading(false)
        addRuningLog("未探测到育碧平台的“savegames”存档目录：" ubiInstallDir)
        return false
    }
    addRuningLog("已探测到“育碧游戏存档目录”：" ubiSaveDir)
    changeUbiSaveDir(ubiSaveDir)
    showLoading(false)
    return true
}
;手动选择育碧存档目录
selectSaveDir(GuiCtrlObj, info)
{
    myGui.Opt("+OwnDialogs")
    ; 允许用户选择 此电脑 目录下的文件夹
    folder := RegExReplace(DirSelect("::{20D04FE0-3AEA-1069-A2D8-08002B30309D}", 2, "选择“育碧平台存档目录”"), "\\$")
    if !folder
        return
    changeUbiSaveDir(folder)
}
;打开育碧存档目录
openSaveDir(GuiCtrlObj, info)
{
    if !saveGamesDir
        return
    try
    {
        Run("explore " saveGamesDir)
    } catch
    {
        warningMsgBox(saveGamesDir "`n打开目录失败！`n请确保已选择有效目录！", "打开目录失败！")
    }
}
;改变用户ID
changeUserID(GuiCtrlObj, info)
{
    userId := GuiCtrlObj.Text
    if (currentUserId != userId)
    {
        global currentUserId := userId
        writeMainCfg(userId, userIdKey)
    }
    ;控件更新
    ;刷新游戏ID列表
    gameIdIndex := 0
    gameIdDDL.Delete()
    if userId
    {
        userDir := saveGamesDir "\" userId
        if DirExist(userDir)
        {
            gameIDTextArr := Array()
            loop files userDir "\*", "D"
            {
                if !IsInteger(A_LoopFileName)
                    continue
                gameIDTextArr.Push(A_LoopFileName ":" readGameName(A_LoopFileName))
                if (currentGameId = A_LoopFileName)
                {
                    gameIdIndex := gameIDTextArr.Length
                }
            }
            gameIdDDL.Add(gameIDTextArr)
        }
    }
    ;同步更新用户头像
    reloadUserLogo(userId)
    ;同步刷新游戏ID
    ControlChooseIndex(gameIdIndex, gameIdDDL, myGui)
}
;改变游戏ID
changeGameID(GuiCtrlObj, info)
{
    gameIdText := GuiCtrlObj.Text
    gameId := parseGameIdFromText(gameIdText)
    if (currentGameId != gameId)
    {
        global currentGameId := gameId
        writeMainCfg(gameId, gameIdKey)
    }
    ;控件更新
    if gameIdText
    {
        editGameNameBtn.Enabled := true
    } else
    {
        editGameNameBtn.Enabled := false
    }
    ;更新提示
    ControlAddTip(GuiCtrlObj, gameIdText)
    ;更新扩展界面显示
    if (gameId = "1771") or (gameId = "3559")
    {
        openExtensionBtn.Visible := true
        if (!extensionGui) && readMainCfg(isAutoPopUpKey, "1")
        {
            openGameExtension()
        }
    }else
    {
        openExtensionBtn.Visible := false
        if extensionGui
        {
            extensionGui.Destroy()
            global extensionGui := ""
        }
    }
}
;编辑游戏名称
editGameName(GuiCtrlObj, info)
{
    myGui.Opt("+OwnDialogs")
	myGui.GetPos(&myGuiX, &myGuiY, &myGuiW, &myGuiH)
	inputBoxW := 300
	inputBoxH := 110
	inputBoxX := Integer(myGuiX + (myGuiW - inputBoxW) / 2)
	inputBoxY := Integer(myGuiY + (myGuiH - inputBoxH) / 2)
	gameNameBox := InputBox("游戏ID：" currentGameId "`n输入游戏名：", "编辑游戏名称(最多50字)", "x" inputBoxX " y" inputBoxY " w" inputBoxW " h" inputBoxH, parseGameNameFromText(gameIdDDL.Text))
	if (gameNameBox.Result != "OK")
	    return
	gameName := gameNameBox.Value
	if !gameName
        return
	if (StrLen(gameName) > 50)
	{
	    warningMsgBox("游戏名称不能超过50个字！", "编辑失败！")
	    return
	}
    writeGameName(gameName,currentGameId)
    ;更新游戏名称显示
    gameIdTextArr := ControlGetItems(gameIdDDL, myGui)
    currentIndex := gameIdDDL.Value
    gameIdTextArr[currentIndex] := currentGameId ":" gameName
    gameIdDDL.Opt("-Redraw")
    gameIdDDL.Delete()
    gameIdDDL.Add(gameIdTextArr)
    gameIdDDL.Value := currentIndex
    gameIdDDL.Opt("+Redraw")
}
;加载用户头像
reloadUserLogo(userId := "")
{
    userLogoPath := getUserLogoPath(userId)
    if !userLogoPath
    {
        userLogoPicCtrl.Visible := false
        userLogoHolder.Visible := true
        return
    }
    ;加载图片出错会抛出错误，故需额外处理
    try
    {
        userLogoPicCtrl.Value := userLogoPath
    } catch
    {
        userLogoPicCtrl.Visible := false
        userLogoHolder.Visible := true
        addRuningLog("加载“用户ID”对应的头像失败：" userLogoPath)
    } else
    {
        userLogoPicCtrl.Visible := true
        userLogoHolder.Visible := false
    }
}
;创建默认的备份目录
creatDefaultBackupDir(*)
{
    ;默认备份目录为“C:\Users\用户名\Saved Games\育碧存档备份”
    defaultDir := "C:\Users\" A_UserName "\Saved Games"
    if DirExist(defaultDir)
    {
        defaultDir := defaultDir "\育碧存档备份"
        if !DirExist(defaultDir)
        {
            try
            {
                DirCreate(defaultDir)
            } catch
            {
                addRuningLog("创建默认的“游戏存档备份目录”失败：" defaultDir)
                return false
            } else
            {
                writeMainCfg(defaultDir, backupDirPathKey)
                addRuningLog("已创建默认的“游戏存档备份目录”：" defaultDir)
                return true
            }
        }
    } else
    {
        try
        {
            DirCreate(defaultDir)
        } catch
        {
            addRuningLog("创建默认的备份上一级目录失败：" defaultDir)
            return false
        } else
        {
            defaultDir := defaultDir "\育碧存档备份"
            try
            {
                DirCreate(defaultDir)
            } catch
            {
                addRuningLog("创建默认的“游戏存档备份目录”失败：" defaultDir)
                return false
            } else
            {
                writeMainCfg(defaultDir, backupDirPathKey)
                addRuningLog("已创建默认的“游戏存档备份目录”：" defaultDir)
                return true
            }
        }
    }
}
;改变备份目录
changeBackupDir(backupDir)
{
    if backupSaveDir != backupDir
    {
        global backupSaveDir := backupDir
        writeMainCfg(backupDir, backupDirPathKey)
        ;重置备份列表
        global backedupUserId := ""
        global backedupGameId := ""
    }
    backupDirEdit.Text := backupDir
}
;选择备份目录
selectBackupDir(GuiCtrlObj, info)
{
    myGui.Opt("+OwnDialogs")
    ; 允许用户选择 此电脑 目录下的文件夹
    folder := RegExReplace(DirSelect("::{20D04FE0-3AEA-1069-A2D8-08002B30309D}", 2, "选择“游戏存档备份目录”"), "\\$")
    if !folder
        return
    changeBackupDir(folder)
}
;打开备份目录
openBackupDir(GuiCtrlObj, info)
{
    if !backupSaveDir
        return
    try
    {
        Run("explore " backupSaveDir)
    } catch
    {
        warningMsgBox(backupSaveDir "`n打开目录失败！`n请确保已选择有效目录！", "打开目录失败！")
    }
}
;还原备份
managerBackup(GuiCtrlObj, info)
{
    ;切换到管理备份Tab
    ControlChooseIndex(2, tabCtrl, myGui)
}
;改变备份限制方式
changeBackupLimitMethod(GuiCtrlObj, info)
{
    index := GuiCtrlObj.Value
    if !index
        return
    limitText := ""
    if (index = 1)
    {
        limitText := readMainCfg(backupLimitDataKey, "1000")
    }else if (index = 2)
    {
        limitText := readMainCfg(backupLimitTimeKey, "30")
    }else if (index = 3)
    {
        limitText := readMainCfg(backupLimitCountKey, "200")
    }
    backupLimitEdit.Text := limitText
    backupLimitText.Text := backLimitTextArr[index]
    writeMainCfg(index, backupLimitMethodKey)
}
;改变备份限制值
changeBackupLimitValue(GuiCtrlObj, info)
{
    index := backupLimitDDL.Value
    if !index
        return
    limitValue := GuiCtrlObj.Text
    if !IsInteger(limitValue)
        return
    cfgKey := ""
    if (index = 1)
    {
        cfgKey := backupLimitDataKey
    } else if (index = 2)
    {
        cfgKey := backupLimitTimeKey
    } else if (index = 3)
    {
        cfgKey := backupLimitCountKey
    }
    if cfgKey && limitValue
    {
        writeMainCfg(limitValue, cfgKey)
    }
}
;改变最小备份间隔
changeMinBackupTime(GuiCtrlObj, info)
{
    minValue := GuiCtrlObj.Text
    if !IsInteger(minValue)
        return
    writeMainCfg(minValue, minBackupTimeKey)
}
;启用手动备份热键
enableHotkey(GuiCtrlObj, info)
{
    if GuiCtrlObj.Value
    {
        backupHotkeyCtrl.Enabled := true
    }else
    {
        backupHotkeyCtrl.Enabled := false
    }
    writeMainCfg(GuiCtrlObj.Value, isEnableHotkeyKey)
}
;改变备份热键
changeBackupHotkey(GuiCtrlObj, info)
{
    hotkey := GuiCtrlObj.Value
    if backupHotkey != hotkey
    {
        global backupHotkey := hotkey
        writeMainCfg(hotkey, backupHotkeyKey)
    }
}
;手动备份
backupHotkeyFunc(*)
{
    backupTime := A_Now
    gameBackupDir := backupSaveDir "\" currentUserId "\" currentGameId
    gameBackupTimeDir := gameBackupDir "\" backupTime
    if DirExist(gameBackupTimeDir)
    {
        ;同一秒不重复手动备份
        return
    }
    try {
        DirCreate(gameBackupTimeDir)
    } catch {
        ;创建备份文件夹失败
        addRuningLog("创建当前备份目录失败：" backupTime)
        return
    } else {
        ;执行复制存档文件夹来备份
        gameSaveDir := saveGamesDir "\" currentUserId "\" currentGameId
        ; global isOpenWatchSave := false
        try {
            DirCopy(gameSaveDir, gameBackupTimeDir, true)
        } catch {
            ;复制存档文件夹失败
            ; global isOpenWatchSave := true
            addRuningLog("手动备份存档失败: " gameSaveDir)
            return
        } else {
            ;输出备份成功运行日志
            writeGameBackupInfo(gameBackupDir, backupTime, "手动备份")
            ;备份列表同步增加
            if (currentUserId = backedupUserId) && (currentGameId = backedupGameId)
            {
                nowBackupSizeKB := 0
                loop files gameBackupTimeDir "\*", "F"
                {
                    nowBackupSizeKB += A_LoopFileSizeKB
                }
                try {
                    backupListView.Insert(1, , FormatTime(backupTime, "yyyy/MM/dd HH:mm:ss"), backupTime, Round(nowBackupSizeKB / 1024, 3), "手动备份")
                }
            }
            ; global isOpenWatchSave := true
            ;播放提示音
            if isPlayBackupSound
            {
                SoundPlay("*64")
            }
            addRuningLog("已手动备份存档至：" backupTime )
        }
    }
}
;日志表格单击右键
logListViewContextMenu(GuiCtrlObj, item, isRightClick, menuX, menuY)
{
    if !isRightClick
        return
    static logRightMenu := ""
    if !logRightMenu
    {
        logRightMenu := Menu()
        logRightMenu.Add("导出日志", exportLog)
        logRightMenu.Add("复制此行", copyRowLog)
        logRightMenu.Add("清空日志", clearLog)
    }
    logRightMenu.Show(menuX, menuY)
}
;导出运行日志
exportLog(*)
{
    myGui.Opt("+OwnDialogs")
    saveFilePath := FileSelect("S", A_ScriptDir "\运行日志-" A_Now ".txt", "保存运行日志", ".txt")
    if !saveFilePath
        return
    allLogText := ""
    loop logListView.GetCount()
    {
        allLogText := allLogText logListView.GetText(A_Index) "`n"
    }
    try {
        FileAppend(allLogText, saveFilePath, "`n UTF-8")
    } catch {
        warningMsgBox("导出运行日志失败！", "导出失败！")
    }
}
;复制此行日志
copyRowLog(*)
{
    selectRow := logListView.GetNext(0, "Focused")
    if !selectRow
        return
    selectLog := ""
    try {
        selectLog := logListView.GetText(selectRow)
    }
    if !selectLog
        return
    A_Clipboard := selectLog
}
;清空运行日志
clearLog(*)
{
    result := warningMsgBox("确定清空所有运行日志？", "确定清空？", "OKCancel Default2 Icon!")
    if (result = "OK")
    {
        logListView.Delete()
        logListView.ModifyCol(1, "AutoHdr")
    }
}

;Tab2子控件事件---------------------------------------------------------------------------------
;改变已备份用户ID
changeBackupUserId(GuiCtrlObj, info)
{
    userId := GuiCtrlObj.Text
    gameIdIndex := 0
    backupGameIdDDL.Delete()
    if userId
    {
        userDir := backupSaveDir "\" userId
        if DirExist(userDir)
        {
            gameIDTextArr := Array()
            loop files userDir "\*", "D"
            {
                if !IsInteger(A_LoopFileName)
                    continue
                gameIDTextArr.Push(A_LoopFileName ":" readGameName(A_LoopFileName))
                if (currentGameId = A_LoopFileName)
                {
                    gameIdIndex := gameIDTextArr.Length
                }
            }
            backupGameIdDDL.Add(gameIDTextArr)
        }
    }
    global backedupUserId := userId
    ;同步更新用户头像
    reLoadBackupUserLogo(userId)
    ;同步刷新游戏ID
    ControlChooseIndex(gameIdIndex, backupGameIdDDL, myGui)
}
;改变已备份游戏ID
changeBackupGameId(GuiCtrlObj, info)
{
    gameIdText := GuiCtrlObj.Text
    ;更新提示
    ControlAddTip(GuiCtrlObj, gameIdText)
    global backedupGameId := parseGameIdFromText(gameIdText)
    ;刷新备份列表
    reloadBackupListView(backedupUserId, backedupGameId)
}
;加载备份用户头像
reloadBackupUserLogo(userId := "")
{
    userLogoPath := getUserLogoPath(userId)
    if !userLogoPath
    {
        backupUserLogoPicCtrl.Visible := false
        backupUserLogoHolder.Visible := true
        return
    }
    ;加载图片出错会抛出错误，故需额外处理
    try {
        backupUserLogoPicCtrl.Value := userLogoPath
    } catch {
        backupUserLogoPicCtrl.Visible := false
        backupUserLogoHolder.Visible := true
        addRuningLog("加载“用户ID”对应的头像失败：" userLogoPath)
    } else {
        backupUserLogoPicCtrl.Visible := true
        backupUserLogoHolder.Visible := false
    }
}
;加载备份列表数据
reloadBackupListView(userId, gameId, isShowLoading := true)
{
    backupListView.Delete()
    if !backupSaveDir
        return
    if !userId
        return
    if !gameId
        return
    if isShowLoading
    {
        showLoading(true, "加载数据中...")
    }
    gameBackupDir := backupSaveDir "\" userId "\" gameId
    allDirName := ""
    allDirInfo := Map()
    allDirSizeKB := 0
    ;按文件夹名时间排序 YYYYMMDDHH24MISS
    loop files gameBackupDir "\*", "D"
    {
        if (StrLen(A_LoopFileName) != 14)
            continue
        if !IsTime(A_LoopFileName)
            continue
        if allDirName
        {
            allDirName := allDirName "," A_LoopFileName
        } else
        {
            allDirName := A_LoopFileName
        }
        ;统计每个备份文件夹的大小
        dirSizeKB := 0
        loop files gameBackupDir "\" A_LoopFileName "\*", "F"
        {
            dirSizeKB += A_LoopFileSizeKB
        }
        allDirInfo[A_LoopFileName] := Round(dirSizeKB / 1024, 3)
        allDirSizeKB += dirSizeKB
    } else
    {
        ;当前游戏存档备份目录不存在
        if isShowLoading
        {
            showLoading(false)
        }
        addRuningLog("未备份过存档：用户ID：" userId " 游戏ID：" gameId)
        return
    }
    allDirName := Sort(allDirName, "D, N R")
    backupListView.Delete()
    backupListView.Opt("-Redraw")
    backupCount := 0
    loop parse allDirName, ","
    {
        backupListView.Add(, FormatTime(A_LoopField, "yyyy/MM/dd HH:mm:ss"), A_LoopField, allDirInfo[A_LoopField], readGameBackupInfo(gameBackupDir, A_LoopField, defaultBackupInfo))
        backupCount += 1
    }
    backupListView.ModifyCol(4, "AutoHdr")
    backupListView.Opt("+Redraw")
    ;清空占用内存
    allDirName := ""
    allDirInfo := ""
    if isShowLoading
    {
        showLoading(false)
    }
    addRuningLog("已加载游戏所有备份：用户ID：" userId " 游戏ID：" gameId)
    ;添加已备份存档统计信息
    addRuningLog("此游戏所有备份累计占用：" Round(allDirSizeKB / 1024, 3) " MB，累计数量：" backupCount " 份")
}
;备份表格单击右键
backupListViewContextMenu(GuiCtrlObj, item, isRightClick, menuX, menuY)
{
    if !isRightClick
        return
    ;点击表格标题与空白处，点击表格的数据行，分别显示不同的右键菜单
    if (item < 1) or (item > GuiCtrlObj.GetCount())
    {
        showSecondRightClickMenu(menuX, menuY)
    } else
    {
        showRightClickMenu(menuX, menuY)
    }
}
;添加列表右键菜单
showRightClickMenu(menuX, menuY)
{
    static rightMenu := ""
    if !rightMenu
    {
        rightMenu := Menu()
        rightMenu.Add("还原当前存档", restoreHighLightBackup)
        rightMenu.Add()
        rightMenu.Add("打开当前存档", openHighLightBackup)
        rightMenu.Add("编辑当前备注", editHighLightBackupInfo)
        rightMenu.Add()
        rightMenu.Add("删除当前存档", deleteHighLightBackup)
        rightMenu.Add()
        rightMenu.Add("勾选全部存档", selectAllBackup)
        rightMenu.Add("取消所有勾选", cancelSelectAllBackup)
    }
    rightMenu.Show(menuX, menuY)
}
;添加备份列表空白处右键菜单
showSecondRightClickMenu(menuX, menuY)
{
    static secondRightMenu := ""
    if !secondRightMenu
    {
        secondRightMenu := Menu()
        secondRightMenu.Add("勾选全部存档", selectAllBackup)
        secondRightMenu.Add("取消所有勾选", cancelSelectAllBackup)
    }
    secondRightMenu.Show(menuX, menuY)
}
;表格全选
selectAllBackup(*)
{
    backupListView.Modify(0, "Check")
}
;表格取消全选
cancelSelectAllBackup(*)
{
    backupListView.Modify(0, "-Check")
}
;编辑表格高亮行存档备注
editHighLightBackupInfo(*)
{
    selectRow := backupListView.GetNext(0, "Focused")
    if !selectRow
    {
        warningMsgBox("表中未找到当前备份存档！", "编辑失败！")
        return
    }
    selectBackupTime := ""
    try
    {
        selectBackupTime := backupListView.GetText(selectRow, 2)
    }
    if !selectBackupTime
    {
        warningMsgBox("当前存档文件夹：`n" selectBackupTime "`n未找到！", "编辑失败！")
        return
    }
    gameBackupDir := backupSaveDir "\" backedupUserId "\" backedupGameId
    myGui.Opt("+OwnDialogs")
	myGui.GetPos(&myGuiX, &myGuiY, &myGuiW, &myGuiH)
	inputBoxW := 300
	inputBoxH := 110
	inputBoxX := Integer(myGuiX + (myGuiW - inputBoxW) / 2)
	inputBoxY := Integer(myGuiY + (myGuiH - inputBoxH) / 2)
	backupSaveInfo := ""
	try
	{
	    backupSaveInfo := backupListView.GetText(selectRow, 4)
	}
	editBox := InputBox("备份文件夹：" selectBackupTime "`n输入备注：", "编辑当前存档备注(最多50字)", "x" inputBoxX " y" inputBoxY " w" inputBoxW " h" inputBoxH, backupSaveInfo)
	if (editBox.Result != "OK")
	    return
	backupSaveInfo := editBox.Value
	if (StrLen(backupSaveInfo) > 50)
	{
	    warningMsgBox("备注不能超过50个字！", "编辑失败！")
	    return
	}
    writeGameBackupInfo(gameBackupDir, selectBackupTime, backupSaveInfo)
    ;更新列表备注显示
    backupListView.Modify(selectRow, , , , , backupSaveInfo)
    backupListView.ModifyCol(4, "AutoHdr")
}
;打开表格高亮行存档
openHighLightBackup(*)
{
    selectRow := backupListView.GetNext(0, "Focused")
    if !selectRow
    {
        warningMsgBox("表中未找到当前备份存档！", "打开失败！")
        return
    }
    selectBackupTime := ""
    try{
        selectBackupTime := backupListView.GetText(selectRow, 2)
    }
    if !selectBackupTime
    {
        warningMsgBox("当前备份文件夹：`n" selectBackupTime "`n未找到！", "打开失败！")
        return
    }
    selectBackupDir := backupSaveDir "\" backedupUserId "\" backedupGameId "\" selectBackupTime
    try{
        Run("explore " selectBackupDir)
    } catch{
        warningMsgBox("打开备份文件夹：`n" selectBackupTime "`n失败！`n请确保当前存档对应的目录正常！", "打开失败！")
    }
}
;还原表格高亮行存档
restoreHighLightBackup(*)
{
    ; 还原当前存档
    selectRow := backupListView.GetNext(0, "Focused")
    if !selectRow
    {
        warningMsgBox("表中未找到当前备份存档！", "还原失败！")
        return
    }
    selectBackupTime := ""
    try
    {
        selectBackupTime := backupListView.GetText(selectRow, 2)
    }
    if !selectBackupTime
    {
        warningMsgBox("当前备份文件夹：`n" selectBackupTime "`n未找到！", "还原失败！")
        return
    }
    selectBackupDir := backupSaveDir "\" backedupUserId "\" backedupGameId "\" selectBackupTime
    gameSaveDir := saveGamesDir "\" backedupUserId "\" backedupGameId
    if !DirExist(selectBackupDir)
    {
        warningMsgBox("当前备份文件夹：`n" selectBackupTime "`n不存在！", "还原失败！")
        return
    }
    if !DirExist(gameSaveDir)
    {
        warningMsgBox("当前游戏存档目录：`n" gameSaveDir "`n不存在！", "还原失败！")
        return
    }
    result := warningMsgBox("建议游戏未运行状态下进行还原存档！！！`n确定还原当前备份文件夹：`n" selectBackupTime "`n到当前游戏存档目录：`n" gameSaveDir, "确定还原当前备份存档？", "OKCancel Icon! Default2")
    if (result != "OK")
        return
    global isOpenWatchSave := false
    try {
        ;若是在运行中，不能直接删除原存档文件夹，否则会使监控失效，因为新生成的存档文件夹是新的句柄
        if startBtn.gmxrStatus
        {
            deleteFileArr := Array()
            loop Files gameSaveDir "\*.*"
            {
                deleteFileArr.Push(A_LoopFilePath)
            }
            for deleteFile in deleteFileArr
            {
                try {
                    FileDelete(deleteFile)
                }
            }
            deleteFileArr := ""
        } else
        {
            try {
                DirDelete(gameSaveDir, true)
            }
        }
        DirCopy(selectBackupDir, gameSaveDir, 1)
    } catch {
        global isOpenWatchSave := true
        addRuningLog("还原当前备份存档失败：" selectBackupTime)
        warningMsgBox("还原当前备份存档：`n" selectBackupTime "`n复制粘贴失败！`n请退出游戏再试或检查相关目录权限", "还原失败！")
    } else {
        global isOpenWatchSave := true
        addRuningLog("已还原当前备份存档：" selectBackupTime)
        warningMsgBox("还原当前备份存档：`n" selectBackupTime "`n成功！", "还原成功！")
    }
}
;删除表格高亮行
deleteHighLightBackup(*)
{
    selectRow := backupListView.GetNext(0, "Focused")
    if !selectRow
    {
        warningMsgBox("表中未找到当前备份存档！", "删除失败！")
        return
    }
    selectBackupTime := ""
    try
    {
        selectBackupTime := backupListView.GetText(selectRow, 2)
    }
    if !selectBackupTime
    {
        warningMsgBox("当前备份文件夹：`n" selectBackupTime "`n未找到！", "删除失败！")
        return
    }
    selectBackupDir := backupSaveDir "\" backedupUserId "\" backedupGameId "\" selectBackupTime
    if !DirExist(selectBackupDir)
    {
        warningMsgBox("当前备份文件夹：`n" selectBackupTime "`n不存在！", "删除失败！")
        return
    }
    result := warningMsgBox("确定要删除当前备份文件夹：`n" selectBackupTime, "确定删除？", "OKCancel Icon! Default2")
    if (result != "OK")
        return
    try {
        DirDelete(selectBackupDir, true)
    } catch {
        addRuningLog("删除当前备份目录失败：" selectBackupTime)
        warningMsgBox("删除当前备份文件夹：`n" selectBackupTime "`n失败！`n请检查相关目录权限！", "删除失败！")
    } else {
        ;同步删除表中的行
        backupListView.Opt("-Redraw")
        backupListView.Delete(selectRow)
        backupListView.Opt("+Redraw")
        addRuningLog("已删除当前备份存档：" selectBackupTime)
        warningMsgBox("删除当前备份存档：`n" selectBackupTime "`n成功", "删除成功！")
    }
}
;还原最新备份存档
rcyLastBackup(GuiCtrlObj, info)
{
    backupCount := backupListView.GetCount()
    if !backupCount
    {
        warningMsgBox("最新备份存档不存在！", "还原失败！")
        return
    }
    try {
        lastBackup := backupListView.GetText(1,2)
    } catch {
        warningMsgBox("最新备份存档不存在！", "还原失败！")
        return
    }
    lastBackupDir := backupSaveDir "\" backedupUserId "\" backedupGameId "\" lastBackup
    gameSaveDir := saveGamesDir "\" backedupUserId "\" backedupGameId
    if !DirExist(lastBackupDir)
    {
        warningMsgBox("最新备份存档文件夹：`n" lastBackup "`n不存在！", "还原失败！")
        return
    }
    if !DirExist(gameSaveDir)
    {
        warningMsgBox("游戏存档目录：`n" gameSaveDir "`n不存在！", "还原失败！")
        return
    }
    result := warningMsgBox("建议游戏未运行状态下进行还原存档！！！`n确定还原最新备份存档：`n" lastBackup "`n到游戏存档目录：`n" gameSaveDir, "确定还原最新备份存档？", "OKCancel Icon! Default2")
    if (result != "OK")
        return
    global isOpenWatchSave := false
    try {
        if startBtn.gmxrStatus
        {
            deleteFileArr := Array()
            loop Files gameSaveDir "\*.*"
            {
                deleteFileArr.Push(A_LoopFilePath)
            }
            for deleteFile in deleteFileArr
            {
                try {
                    FileDelete(deleteFile)
                }
            }
            deleteFileArr := ""
        } else
        {
            try {
                DirDelete(gameSaveDir, true)
            }
        }
        DirCopy(lastBackupDir, gameSaveDir, 1)
    } catch {
        global isOpenWatchSave := true
        addRuningLog("还原最新备份存档失败：" lastBackup)
        warningMsgBox("还原最新备份存档：`n" lastBackup "`n复制粘贴失败！`n请退出游戏再试或检查相关目录权限！", "还原失败！")
    } else {
        global isOpenWatchSave := true
        addRuningLog("已还原最新备份存档：" lastBackup)
        warningMsgBox("还原最新备份存档：`n" lastBackup "`n成功！", "还原成功！")
    }
}
;打开表中勾选存档
openChooseBackup(GuiCtrlObj, info)
{
    selectRow := backupListView.GetNext(0, "Checked")
    if !selectRow
    {
        warningMsgBox("备份列表中未勾选需要打开的存档！", "打开表中勾选存档失败！")
        return
    }
    if (backupListView.GetNext(selectRow, "Checked"))
    {
        ;说明选择了多个
        warningMsgBox("备份列表中勾选了多个存档！`n请仅勾选一个存档再打开！", "打开失败！")
        return
    }else
    {
        try {
            selectBackupTime := backupListView.GetText(selectRow, 2)
        } catch {
            warningMsgBox("备份列表中勾选的“备份存档文件夹”获取失败！", "打开失败！")
            return
        }
        ;仅选择了1个，正常打开
        selectBackupDir := backupSaveDir "\" backedupUserId "\" backedupGameId "\" selectBackupTime
        try {
            Run("explore " selectBackupDir)
        } catch {
            warningMsgBox(selectBackupDir "`n打开目录失败！`n请确保勾选存档对应的目录正常！", "打开失败！")
        }
    }
}
;还原表中勾选存档
rcyChooseBackup(GuiCtrlObj, info)
{
    selectRow := backupListView.GetNext(0, "Checked")
    if !selectRow
    {
        warningMsgBox("备份列表中未勾选需要还原的存档！", "还原失败！")
        return
    }
    if (backupListView.GetNext(selectRow, "Checked"))
    {
        ;说明选择了多个
        warningMsgBox("备份列表中勾选了多个存档！`n请仅勾选一个存档再还原！", "还原失败！")
        return
    }else
    {
        ;仅选择了1个，正常还原
        try {
            selectBackupTime := backupListView.GetText(selectRow, 2)
        } catch {
            warningMsgBox("备份列表中勾选的“备份存档文件夹”获取失败！", "还原失败！")
            return
        }
        selectBackupDir := backupSaveDir "\" backedupUserId "\" backedupGameId "\" selectBackupTime
        gameSaveDir := saveGamesDir "\" backedupUserId "\" backedupGameId
        if !DirExist(selectBackupDir)
        {
            warningMsgBox("备份列表中勾选的备份存档文件夹：`n" selectBackupTime "`n不存在！", "还原失败！")
            return
        }
        if !DirExist(gameSaveDir)
        {
            warningMsgBox("游戏存档目录：`n" gameSaveDir "`n不存在！", "还原失败！")
            return
        }
        result := warningMsgBox("建议游戏未运行状态下进行还原存档！！！`n确定还原当前备份文件夹：`n" selectBackupTime "`n到当前游戏存档目录：`n" gameSaveDir, "确定还原当前备份存档？", "OKCancel Icon! Default2")
        if (result != "OK")
            return
        global isOpenWatchSave := false
        try {
            if startBtn.gmxrStatus
            {
                deleteFileArr := Array()
                loop Files gameSaveDir "\*.*"
                {
                    deleteFileArr.Push(A_LoopFilePath)
                }
                for deleteFile in deleteFileArr
                {
                    try {
                        FileDelete(deleteFile)
                    }
                }
                deleteFileArr := ""
            } else
            {
                try {
                    DirDelete(gameSaveDir, true)
                }
            }
            DirCopy(selectBackupDir, gameSaveDir, 1)
        } catch {
            global isOpenWatchSave := true
            addRuningLog("还原备份列表中勾选存档失败：" selectBackupTime)
            warningMsgBox("还原备份列表中勾选备份存档：`n" selectBackupTime "`n复制粘贴失败！`n请退出游戏再试或检查相关目录权限", "还原失败！")
        } else {
            global isOpenWatchSave := true
            addRuningLog("已还原备份列表中勾选存档：" selectBackupTime)
            warningMsgBox("还原备份列表中勾选备份存档：`n" selectBackupTime "`n成功！", "还原成功！")
        }
    }
}
;删除表中勾选存档
delChooseBackup(GuiCtrlObj, info)
{
    allDeleteRow := Array()
    ;检查是否有选择的行
    nextCheckedRow := backupListView.GetNext(0, "Checked")
    if !nextCheckedRow
    {
        warningMsgBox("未勾选表中存档！`n请至少勾选一个存档再来删除！", "删除失败！")
        return
    }
    result := warningMsgBox("确定要删除“表中所有已勾选的备份存档”？", "确定删除？", "OKCancel Icon! Default2")
    if (result != "OK")
        return
    allDeleteRow := Array()
    gameBackupDir := backupSaveDir "\" backedupUserId "\" backedupGameId
    loopCount := backupListView.GetCount()
    nextCheckedRow -= 1
    loopCount -= nextCheckedRow
    loop loopCount
    {
        nextCheckedRow := backupListView.GetNext(nextCheckedRow, "Checked")
        if !nextCheckedRow
            break
        checkedBackupDir := backupListView.GetText(nextCheckedRow, 2)
        try {
            DirDelete(gameBackupDir "\" checkedBackupDir, true)
        } catch {
            addRuningLog("删除备份列表中勾选存档失败：" checkedBackupDir)
        } else {
            allDeleteRow.Push(nextCheckedRow)
            addRuningLog("已删除备份列表中勾选存档：" checkedBackupDir)
        }
    }
    ;同步删除表中的行
    backupListView.Opt("-Redraw")
    for deleteRow in allDeleteRow
    {
        backupListView.Delete(deleteRow)
    }
    backupListView.Opt("+Redraw")
    if allDeleteRow.Length
    {
        warningMsgBox("删除表中勾选存档成功！", "删除成功！")
    } else
    {
        warningMsgBox("删除表中勾选存档时：`n执行删除目录操作失败！`n请检查相关目录权限！", "删除失败！")
    }
}

;启动----------------------------------------------------------------------------------
;启动按钮点击
startBtnClick(GuiCtrlObj, info)
{
    if startBtn.gmxrStatus
    {
        ;停止
        startBtn.Enabled := false
        global isOpenWatchSave := false
        result := stop()
        global isOpenWatchSave := !result
        if result
        {
            SetTimer(reEnableStartCtrl, -1000)
        } else
        {
            SetTimer(reEnableStopCtrl, -100)
        }
    }else
    {
        ;启动
        startBtn.Enabled := false
        autoDetectBtn.Enabled := false
        selectSaveDirBtn.Enabled := false
        userIdDDL.Enabled := false
        gameIdDDL.Enabled := false
        editGameNameBtn.Enabled := false
        selectBackupDirBtn.Enabled := false
        backupLimitDDL.Enabled := false
        backupLimitEdit.Enabled := false
        minBackupTimeEdit.Enabled := false
        isEnableHotkeyCB.Enabled := false
        backupHotkeyCtrl.Enabled := false
        if extensionGui
        {
            extensionGui["GMSave"].Enabled := false
            extensionGui["CacheLevel"].Enabled := false
        }
        global isOpenWatchSave := false
        result := start()
        global isOpenWatchSave := result
        if result
        {
            SetTimer(reEnableStopCtrl, -1000)
        } else
        {
            SetTimer(reEnableStartCtrl, -100)
        }
    }
    reEnableStopCtrl()
    {
        startBtn.gmxrStatus := true
        startBtn.Text := "停止"
        startBtn.SetFont("cFFFFFF")
        startBackground.Opt("Background800000")
        startBtn.Enabled := true
    }
    reEnableStartCtrl()
    {
        autoDetectBtn.Enabled := true
        selectSaveDirBtn.Enabled := true
        userIdDDL.Enabled := true
        gameIdDDL.Enabled := true
        editGameNameBtn.Enabled := true
        selectBackupDirBtn.Enabled := true
        backupLimitDDL.Enabled := true
        backupLimitEdit.Enabled := true
        minBackupTimeEdit.Enabled := true
        isEnableHotkeyCB.Enabled := true
        backupHotkeyCtrl.Enabled := true
        if extensionGui
        {
            extensionGui["GMSave"].Enabled := true
            extensionGui["CacheLevel"].Enabled := true
        }
        startBtn.gmxrStatus := false
        startBtn.Text := "启动"
        startBtn.SetFont("cDefault")
        startBackground.Opt("BackgroundDefault")
        startBtn.Enabled := true
    }
}
;启动
start(*)
{
    ;检查配置
    if (!saveGamesDir) or (!FileExist(saveGamesDir))
    {
        warningMsgBox("“育碧游戏存档目录”不存在！`n请选择有效的“育碧游戏存档目录”！", "启动失败！")
        return false
    }
    if !currentUserId
    {
        warningMsgBox("选择的“用户ID”为空！", "启动失败！")
        return false
    }
    userSaveDir := saveGamesDir "\" currentUserId
    if !DirExist(userSaveDir)
    {
        warningMsgBox("“用户ID”对应的存档目录不存在！", "启动失败！")
        return false
    }
    if !currentGameId
    {
        warningMsgBox("选择的“游戏ID”为空！", "启动失败！")
        return false
    }
    gameSaveDir := userSaveDir "\" currentGameId
    if !DirExist(gameSaveDir)
    {
        warningMsgBox("“游戏ID”对应的游戏存档目录不存在！", "启动失败！")
        return false
    }
    if !backupSaveDir
    {
        warningMsgBox("“游戏存档备份目录”为空！", "启动失败！")
        return false
    }
    if !DirExist(backupSaveDir)
    {
        ;文件夹不存在时，判断是否是默认目录，是则提醒用户创建
        if (backupSaveDir != "C:\Users\" A_UserName "\Saved Games\育碧存档备份")
        {
            warningMsgBox("“游戏存档备份目录”不存在！", "启动失败！")
            return false
        }
        creatBackupResult := warningMsgBox("“游戏存档备份目录”未创建：`n" backupSaveDir "`n`n是否创建该目录以继续？", "是否创建“游戏存档备份目录”？", "YesNo Iconi Default1")
        if creatBackupResult = "Yes"
        {
            creatDefaultResult := creatDefaultBackupDir()
            if !creatDefaultResult
            {
                warningMsgBox(backupSaveDir "`n备份目录创建失败！`n请检查是否有足够的权限创建！", "启动失败！")
                return false
            }
        } else
        {
            warningMsgBox("“游戏存档备份目录”不存在！", "启动失败！")
            return false
        }
    }
    userBackupDir := backupSaveDir "\" currentUserId
    gameBackupDir := userBackupDir "\" currentGameId
    if !DirExist(gameBackupDir)
    {
        if !DirExist(userBackupDir)
        {
            try {
                DirCreate(userBackupDir)
            } catch {
                addRuningLog("创建“用户存档备份目录”失败：" userBackupDir)
                warningMsgBox("创建“用户存档备份文件夹”失败！`n" userBackupDir "`n请检查当前配置的“游戏存档备份目录”是否有权限操作！", "启动失败！")
                return false
            }
        }
        try {
            DirCreate(gameBackupDir)
        } catch {
            addRuningLog("创建“游戏存档备份目录”失败：" gameBackupDir)
            warningMsgBox("创建“游戏存档备份文件夹”失败！`n请检查当前配置的“游戏存档备份目录”是否有权限操作！", "启动失败！")
            return false
        }
        addRuningLog("已创建“游戏存档备份目录”：" gameBackupDir)
    }
    limitMethod := backupLimitDDL.Value
    if !limitMethod
    {
        warningMsgBox("请选择“最大备份限制”的方式！", "启动失败！")
        return false
    }
    limitValue := backupLimitEdit.Text
    if !limitValue
    {
        warningMsgBox("请输入“最大备份限制”的数值！", "启动失败！")
        return false
    }
    if !IsInteger(limitValue)
    {
        warningMsgBox("“最大备份限制”的数值不是整数！`n请输入在有效范围内的整数数值！", "启动失败！")
        return false
    }
    if (limitMethod = 1)
    {
        if (limitValue < 10) or (limitValue > 9999)
        {
            warningMsgBox("“最大备份空间”的数值不在规定范围内！`n请输入在(10-9999)有效范围内的整数数值！", "启动失败！")
            return false
        }
    } else if (limitMethod = 2)
    {
        if (limitValue < 1) or (limitValue > 366)
        {
            warningMsgBox("“最大保留天数”的数值不在规定范围内！`n请输入在(1-366)有效范围内的整数数值！", "启动失败！")
            return false
        }
    } else if (limitMethod = 3)
    {
        if (limitValue < 1) or (limitValue > 9999)
        {
            warningMsgBox("“最大备份数量”的数值不在规定范围内！`n请输入在(1-9999)有效范围内的整数数值！", "启动失败！")
            return false
        }
    }else
    {
        warningMsgBox("选择的“最大备份限制”方式不支持！`n请选择有效的“最大备份限制”方式！", "启动失败！")
        return false
    }
    minBackupTime := minBackupTimeEdit.Text
    if !minBackupTime
    {
        warningMsgBox("请输入“最小备份间隔”的有效数值！", "启动失败！")
        return false
    }
    if !IsInteger(minBackupTime)
    {
        warningMsgBox("“最小备份间隔”的数值不是整数！`n请输入在有效范围内的整数数值！", "启动失败！")
        return false
    }
    if (minBackupTime < 1) or (minBackupTime > 180)
    {
        warningMsgBox("“最小备份间隔”的数值不在规定范围内！`n请输入在有效范围内的整数数值！", "启动失败！")
        return false
    }
    isEnableHotkey := isEnableHotkeyCB.Value
    if isEnableHotkey
    {
        if !backupHotkey
        {
            warningMsgBox("“手动备份”快捷键为空！`n请设置“手动备份”快捷键！", "启动失败！")
            return false
        }
        if (backupHotkey = "#") or (backupHotkey = "!") or (backupHotkey = "^") or (backupHotkey = "+")
        {
            warningMsgBox("设置的“手动备份”快捷键不支持！`n请设置有效的“手动备份”快捷键！", "启动失败！")
            return false
        }
    }
    ;最后的备份时间
    global lastBackupTime := ""
    ;已备份大小
    global backedSizeKB := 0
    ;最早的备份时间
    global earliestBackupTime := ""
    ;已备份数量
    global backedNumber := 0
    ;备份备注
    global backupSaveInfo := defaultBackupInfo
    
    ;根据备份限制清理超过限制的已备份文件
    allDirName := ""
    loop files gameBackupDir "\*", "D"
    {
        if (StrLen(A_LoopFileName) != 14)
            continue
        if !IsTime(A_LoopFileName)
            continue
        if allDirName
        {
            allDirName := allDirName "," A_LoopFileName
        } else
        {
            allDirName := A_LoopFileName
        }
    }
    if allDirName
    {
        ;按时间大小逆序排序
        allDirName := Sort(allDirName, "D, N R")
        isExpiredBackups := false
        if limitMethod = 1
        {
            ;清理已超过限制容量的备份,并记录最新备份、最早备份
            loop parse allDirName, ","
            {
                if isExpiredBackups or (backedSizeKB >= (limitValue * 1024))
                {
                    isExpiredBackups := true
                    try{
                        DirDelete(gameBackupDir "\" A_LoopField, true)
                    } catch{
                        addRuningLog("删除超过限制的备份失败：" A_LoopField)
                    } else {
                        addRuningLog("已删除超过限制的备份：" A_LoopField)
                    }
                } else
                {
                    loop files gameBackupDir "\" A_LoopField "\*", "F"
                    {
                        global backedSizeKB += A_LoopFileSizeKB
                    }
                    if !lastBackupTime
                    {
                        global lastBackupTime := A_LoopField
                    }
                    global earliestBackupTime := A_LoopField
                }
            }
        } else if (limitMethod = 2)
        {
            ;清理已过期的备份
            loop parse allDirName, ","
            {
                if isExpiredBackups or (DateDiff(A_Now, A_LoopField, "Days") >= limitValue)
                {
                    isExpiredBackups := true
                    try {
                        DirDelete(gameBackupDir "\" A_LoopField, true)
                    } catch {
                        addRuningLog("删除超过限制的备份失败：" A_LoopField)
                    } else {
                        addRuningLog("已删除超过限制的备份：" A_LoopField)
                    }
                } else
                {
                    if !lastBackupTime
                    {
                        global lastBackupTime := A_LoopField
                    }
                    global earliestBackupTime := A_LoopField
                }
            }
        } else if (limitMethod = 3)
        {
            ;清理已超过限制数量的备份
            loop parse allDirName, ","
            {
                if isExpiredBackups or (backedNumber >= limitValue)
                {
                    isExpiredBackups := true
                    try {
                        DirDelete(gameBackupDir "\" A_LoopField, true)
                    } catch {
                        addRuningLog("删除超过限制的备份失败：" A_LoopField)
                    } else {
                        addRuningLog("已删除超过限制的备份：" A_LoopField)
                    }
                } else
                {
                    if !lastBackupTime
                    {
                        global lastBackupTime := A_LoopField
                    }
                    global backedNumber += 1
                    global earliestBackupTime := A_LoopField
                }
            }
        }
        allDirName := ""
        ;有过期的备份被清理，则重置备份列表显示
        if isExpiredBackups
        {
            global backedupUserId := ""
            global backedupGameId := ""
        }
    }
    ;判断是否需要立即备份
    ;1、是否存在最新备份。存在时检查最新备份是否超过最小备份间隔，超过则立即备份
    ;2、最后再检查当前立即备份下下来的，是否与最新备份一致，一致则删除当前备份
    if (!lastBackupTime) or (DateDiff(A_Now, lastBackupTime, "Minutes") > minBackupTime)
    {
        nowTime := A_Now
        nowBackupDir := gameBackupDir "\" nowTime
        try{
            ; DirCreate(nowBackupDir)
            ;DirCopy：如果目标目录的结构不存在, 则可行时会自动创建
            DirCopy(gameSaveDir, nowBackupDir, true)
        } catch {
            ;此时备份失败，说明备份操作权限有问题，立即失败
            addRuningLog("备份存档失败：" gameSaveDir)
            warningMsgBox("备份存档：`n" gameSaveDir "`n失败！`n请检查相关目录是否有足够的权限操作！", "启动失败！")
            return false
        } else {
            isDiffBackup := false
            nowBackupSizeKB := 0
            ;判断最新的备份文件是否一致，一致则删除最新备份
            if lastBackupTime
            {
                nowBackupFileNumber := 0
                lastBackupDir := gameBackupDir "\" lastBackupTime
                loop files nowBackupDir "\*", "F"
                {
                    nowBackupFileNumber += 1
                    nowBackupSizeKB += A_LoopFileSizeKB
                    lastBackupFileName := lastBackupDir "\" A_LoopFileName
                    if FileExist(lastBackupFileName)
                    {
                        ;判断文件修改时间和大小是否一致
                        if DateDiff(FileGetTime(lastBackupFileName), A_LoopFileTimeModified, "Seconds")
                        {
                            isDiffBackup := true
                            break
                        }
                        if (FileGetSize(lastBackupFileName) != A_LoopFileSizeKB)
                        {
                            isDiffBackup := true
                            break
                        }
                    } else
                    {
                        isDiffBackup := true
                        break
                    }
                }
                if !isDiffBackup
                {
                    ;当同文件名的文件大小和时间都一致时，再接着判断文件数量是否一致
                    lastBackupFileNumber := 0
                    loop files lastBackupDir "\*", "F"
                    {
                        lastBackupFileNumber += 1
                    }
                    if (nowBackupFileNumber != lastBackupFileNumber)
                        isDiffBackup := true
                }
            } else
            {
                ;最新备份不存在，立即备份
                isDiffBackup := true
            }
            if isDiffBackup
            {
                lastBackupTime := nowTime
                ;备份限制检查
                if (limitMethod = 1)
                {
                    global backedSizeKB += nowBackupSizeKB
                } else if (limitMethod = 3)
                {
                    global backedNumber += 1
                }
                ;备份列表同步增加
                if (currentUserId = backedupUserId) && (currentGameId = backedupGameId)
                {
                    try{
                        backupListView.Insert(1, , FormatTime(nowTime, "yyyy/MM/dd HH:mm:ss"), nowTime, Round(nowBackupSizeKB / 1024, 3), backupSaveInfo)
                    }
                }
                addRuningLog("已备份存档至：" nowTime)
            } else
            {
                ;清理相同的当前备份，保证每个不同的备份仅有一份
                try{
                    DirDelete(nowBackupDir, true)
                }
            }
        }
    }
    if isOpenGMAutoSave(currentGameId)
    {
        global lastCache := userSaveDir "\" currentGameId "-" lastCacheExt
        if !DirExist(lastCache)
        {
            try {
                DirCreate(lastCache)
            } catch {
                addRuningLog("创建“幽灵模式”存档缓存目录失败：" lastCache)
                warningMsgBox("启用“幽灵模式”自动续档功能失败！`n原因：创建存档缓存目录：`n" lastCache "`n失败！`n请检查当前配置的“游戏存档目录”是否有权限操作！", "启动失败！")
                return false
            }
        }
        global saveCacheMap := Map()
        saveCacheMap.Default := 0
        ;加载已有的缓存
        loop Files lastCache "\*", "F"
        {
            ; addRuningLog(A_LoopFileExt)
            if (StrLen(A_LoopFileExt) != 14)
                continue
            if !IsTime(A_LoopFileExt)
                continue
            ;清理已超过最小备份间隔的缓存
            if DateDiff(A_Now, A_LoopFileExt, "Minutes") > minBackupTime
            {
                try {
                    FileDelete(A_LoopFilePath)
                }
                continue
            }
            ;加载未失效缓存
            loopFileNameNoExt := RTrim(A_LoopFileName, "." A_LoopFileExt)
            cacheArr := saveCacheMap[loopFileNameNoExt]
            if cacheArr
            {
                cacheArr.Push(A_LoopFileExt)
            }else 
            {
                saveCacheMap[loopFileNameNoExt] := Array(A_LoopFileExt)
            }
        }
        ;同时立即拷贝一份备份到缓存目录
        try {
            FileCopy(gameBackupDir "\" lastBackupTime "\*.save", lastCache "\*.*", true)
        } catch {
            addRuningLog("拷贝存档至缓存目录失败：" lastCache)
            warningMsgBox("启用“幽灵模式”自动续档功能失败！`n原因：拷贝存档至缓存目录：`n" lastCache "`n失败！`n请检查当前配置的“育碧游戏存档目录”是否有权限操作！", "启动失败！")
            return false
        }
        readCacheLevel := readMainCfg(cacheLevelKey, "2")
        if IsInteger(readCacheLevel)
        {
            readCacheLevel := Integer(readCacheLevel)
            if readCacheLevel < 1
                readCacheLevel := 1
            else if readCacheLevel > 10
                readCacheLevel := 10
        } else
        {
            readCacheLevel := 2
        }
        global saveCacheLevel := readCacheLevel
        ;开启监测存档变化（1：文件创建、重命名、删除；16：文件修改）
        result := WatchFolder(gameSaveDir, GMSaveFileChanges, false, 1+16)
    } else
    {
        result := WatchFolder(gameSaveDir, gameSaveFileChanges, false, 1+16)
    }
    if !result
    {
        addRuningLog("监控游戏存档目录失败：" gameSaveDir)
        warningMsgBox("监控游戏存档目录：`n" gameSaveDir "`n失败！`n请检查当前配置的“游戏存档目录”`n或工具是否有足够的权限操作！", "启动失败！")
        return false
    }
    if isEnableHotkey
    {
        ;启用手动备份快捷键
        Hotkey("~" backupHotkey, backupHotkeyFunc, "On")
    }
    return true

    ;监测到存档文件发生变化
    gameSaveFileChanges(folder, changes)
    {
        if !isOpenWatchSave
            return
        if DateDiff(A_Now, lastBackupTime, "Minutes") < minBackupTime
            return
        nowTime := A_Now
        nowBackupDir := gameBackupDir "\" nowTime
        ;输出运行日志
        changeLog := "存档有变化："
        for change in changes
        {
            SplitPath(change.Name, &fileName)
            changeLog := changeLog " " fileName getFileChangeActionDesc(change.Action)
        }
        addRuningLog(changeLog)
        ;执行备份
        ; global isOpenWatchSave := false
        try {
            DirCopy(folder, nowBackupDir, true)
        } catch {
            ;输出备份失败运行日志
            global isOpenWatchSave := true
            addRuningLog("备份存档失败：" folder)
            return
        } else {
            if backupSaveInfo != defaultBackupInfo
            {
                writeGameBackupInfo(gameBackupDir, nowTime, backupSaveInfo)
            }
            global lastBackupTime := nowTime
            if (limitMethod = 1)
            {
                nowBackupSizeKB := 0
                loop files nowBackupDir "\*", "F"
                {
                    nowBackupSizeKB += A_LoopFileSizeKB
                }
                global backedSizeKB += nowBackupSizeKB
            } else if (limitMethod = 2)
            {

            } else if (limitMethod = 3)
            {
                global backedNumber += 1
            }
            ;备份列表同步增加
            if (currentUserId = backedupUserId) && (currentGameId = backedupGameId)
            {
                try {
                    backupListView.Insert(1, , FormatTime(nowTime, "yyyy/MM/dd HH:mm:ss"), nowTime, Round(nowBackupSizeKB / 1024, 3), backupSaveInfo)
                }
            }
            if earliestBackupTime
            {
                ;备份限制检查
                SetTimer(checkBackupLimit, -10)
            }
            ; global isOpenWatchSave := true
            addRuningLog("已备份存档至：" nowTime)
        }
        checkBackupLimit(*)
        {
            ;执行检查限制
            isDeleteEarliestBackup := false
            if (limitMethod = 1)
            {
                if (backedSizeKB > (limitValue*1024))
                    isDeleteEarliestBackup := true
            }else if (limitMethod = 2)
            {
                if (DateDiff(nowTime, earliestBackupTime, "Days") > limitValue)
                    isDeleteEarliestBackup := true
            } else if (limitMethod = 3)
            {
                if backedNumber > limitValue
                    isDeleteEarliestBackup := true
            }
            if !isDeleteEarliestBackup
                return
            earliestBackupSizeKB := 0
            if (limitMethod = 1)
            {
                loop files gameBackupDir "\" earliestBackupTime "\*", "F"
                {
                    earliestBackupSizeKB += A_LoopFileSizeKB
                }
            }
            try {
                DirDelete(gameBackupDir "\" earliestBackupTime, true)
            } catch {
                addRuningLog("删除超过限制的备份失败：" earliestBackupTime)
            } else {
                addRuningLog("已删除超过限制的备份：" earliestBackupTime)
                if (limitMethod = 1)
                {
                    global backedSizeKB -= earliestBackupSizeKB
                } else if (limitMethod = 3)
                {
                    global backedNumber -= 1
                }
                ;重新计算最早的备份时间
                oldBackupTime := ""
                loop files gameBackupDir "\*", "D"
                {
                    if (StrLen(A_LoopFileName) != 14)
                        continue
                    if !IsTime(A_LoopFileName)
                        continue
                    if oldBackupTime
                    {
                        if (DateDiff(oldBackupTime, A_LoopFileName, "Seconds") > 0)
                        {
                            oldBackupTime := A_LoopFileName
                        }
                    } else
                    {
                        oldBackupTime := A_LoopFileName
                    }
                }
                global earliestBackupTime := oldBackupTime
                ;备份列表同步删除
                if (currentUserId = backedupUserId) && (currentGameId = backedupGameId)
                {
                    try {
                        backupListView.Delete(backupListView.GetCount())
                    }
                }
            }
        }
    }
    ;自动续档
    GMSaveFileChanges(folder, changes)
    {
        isDeleteSaveFile := false
        allChangeFiles := Map()
        for change in changes
        {
            if change.IsDir
                continue
            SplitPath(change.Name, &fileName, , &fileExt, &fileNameNoExt)
            if (change.action = 4) && (fileExt = "delete")
            {
                ;此为删档动作，需要立即还原存活存档
                isDeleteSaveFile := true
                allChangeFiles[fileNameNoExt] := A_Now
                try {
                    FileDelete(change.Name)
                } catch {
                    addRuningLog("删除删档标记失败：" fileName)
                } else {
                    addRuningLog("已删除删档标记：" fileName)
                }
                continue
            }
            if isDeleteSaveFile
                continue
            if fileExt != "save"
                continue
            if (fileName = "1.save") or (fileName = "2.save")
                continue
            ;正常将有变化的存档缓存
            allChangeFiles[fileName] := A_Now
        }
        if isDeleteSaveFile
        {
            ; global isOpenWatchSave := false
            for changeFile, changeTime in allChangeFiles
            {
                saveCacheArr := saveCacheMap[changeFile]
                if saveCacheArr && (saveCacheArr.Length)
                {
                    ;被删档，还原2分钟内的最早缓存存档
                    try {
                        FileCopy(lastCache "\" changeFile "." saveCacheArr[1], folder "\" changeFile, 1)
                    } catch {
                        addRuningLog("还原缓存中的存活存档失败：" changeFile "." saveCacheArr[1])
                    } else {
                        ;兼容育碧云存档同步功能
                        if !FileExist(folder "\" changeFile ".upload")
                        {
                            FileAppend("", folder "\" changeFile ".upload", "UTF-8")
                        }
                        addRuningLog("已还原缓存中的存活存档：" changeFile "." saveCacheArr[1])
                    }
                    ;至少保留一个最早的缓存，依次清理其他缓存，防止死亡存档污染缓存
                    while (saveCacheArr.Length > 1)
                    {
                        try {
                            FileDelete(lastCache "\" changeFile "." saveCacheArr[saveCacheArr.Length])
                        } catch {
                            ; addRuningLog("清理非存活存档的缓存失败：" changeFile "." saveCacheArr[saveCacheArr.Length])
                        } else {
                            ; addRuningLog("已清理非存活存档的缓存：" changeFile "." saveCacheArr[saveCacheArr.Length])
                        }
                        saveCacheArr.RemoveAt(saveCacheArr.Length)
                    }
                } else
                {
                    ;缓存为空，则从最近的备份还原
                    try {
                        FileCopy(lastCache "\" changeFile, folder "\" changeFile, 1)
                    } catch {
                        addRuningLog("还原缓存中的存活存档失败：" changeFile)
                    } else {
                        ;兼容育碧云存档同步功能
                        if !FileExist(folder "\" changeFile ".upload")
                        {
                            FileAppend("", folder "\" changeFile ".upload", "UTF-8")
                        }
                        addRuningLog("已还原缓存中的存活存档：" changeFile)
                    }
                }
            }
            ; global isOpenWatchSave := true
            global backupSaveInfo := "疑似未存活"
        } else
        {
            for changeFile, changeTime in allChangeFiles
            {
                ;备份有变化的存档至缓存
                try {
                    FileCopy(folder "\" changeFile, lastCache "\" changeFile "." changeTime, 1)
                } catch {
                    ; addRuningLog("缓存有变化的存档失败：" changeFile)
                } else {
                    ; addRuningLog("已缓存有变化的存档至：" changeFile "." changeTime)
                    ;清理过期缓存
                    saveCacheArr := saveCacheMap[changeFile]
                    if saveCacheArr
                    {
                        ;只循环保留对应缓存深度的份数，这样恢复存活存档，能完美续接之前的进度
                        while (saveCacheArr.Length > saveCacheLevel)
                        {
                            try {
                                FileDelete(lastCache "\" changeFile "." saveCacheArr[1])
                            } catch {
                                ; addRuningLog("清理过期的缓存存档失败：" changeFile "." saveCacheArr[1])
                            } else {
                                ; addRuningLog("已清理过期的缓存存档：" changeFile "." saveCacheArr[1])
                            }
                            saveCacheArr.RemoveAt(1)
                        }
                        saveCacheArr.Push(changeTime)
                    } else
                    {
                        saveCacheMap[changeFile] := Array(changeTime)
                    }
                }
            }
            global backupSaveInfo := defaultBackupInfo
        }
        allChangeFiles := ""
        gameSaveFileChanges(folder, changes)
    }
}
;停止
stop(*)
{
    if isEnableHotkeyCB.Value && backupHotkey
    {
        ;停止手动备份热键
        Hotkey("~" backupHotkey, backupHotkeyFunc, "Off")
    }
    gameSaveDir := saveGamesDir "\" currentUserId "\" currentGameId
    result := WatchFolder(gameSaveDir, "**DEL")
    if !result
    {
        addRuningLog("停止监测游戏存档目录失败：" gameSaveDir)
    }
    return result
}

;游戏扩展-----------------------------------------------------------------------------------------------------
;打开游戏扩展界面
openGameExtension(*)
{
    if !extensionGui
    {
        global extensionGui := Gui("+Owner -MinimizeBox -MaximizeBox", ">>游戏扩展")
        extensionGui.MarginX := guiMarginX
        extensionGui.MarginY := guiMarginY
        isEnableGMSaveCB := extensionGui.AddCheckbox("vGMSave Section h22 Checked" isEnableGMAutoSave " Disabled" startBtn.gmxrStatus, "启用“幽灵模式”自动续档复活")
        isAutoPopUpCB := extensionGui.AddCheckbox("hp x+" guiMarginX*3 " Checked" readMainCfg(isAutoPopUpKey, "1"), "自动弹出此界面")
        extensionGui.AddText("+0x200 c800000  h22 y+8 xs", "续档无缝级别：")
        cacheLevelDDL := extensionGui.AddDropDownList("vCacheLevel w40 x+2 Choose" readMainCfg(cacheLevelKey, "2") " Disabled" startBtn.gmxrStatus, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
        extensionGui.AddText("c800000 h22 x+" guiMarginX, "越小，复活后越接近最后存活进度。`n若续档复活失效，可尝试逐级调大。")
        helpInfo := "
        (
此功能仅适用《幽灵行动：荒野》的“幽灵模式”！！！
请确保在角色存活之前勾选此功能并启动！！！
- - - - - - - - - - - - - - - - - - - - - - - - - -

勾选并启动后，当游玩“幽灵模式”时，角色不幸身亡：

1、显示“你的战士已死亡”，按下 Enter 键“离开游戏”

2、显示“你在幽灵模式战役中死亡，因此你的存档已被删除”

***此时此功能，将会自动还原当前模式最近的存活存档***

3、按下 Esc 键“返回”到主菜单，游戏将自动重启加载

4、游戏重启后进入“幽灵模式”，已续档复活，继续游玩

- - - - - - - - - - - - - - - - - - - - - - - - - -
提示：若是未自动续档复活，可关闭游戏及育碧平台的云存档
进入工具的“管理备份”一栏，手动还原适当时间的备份存档
最后重新启动游戏续档游玩
        )"
        extensionGui.AddText("y+8 xs", helpInfo)

        isEnableGMSaveCB.OnEvent("Click", enableGMAutoSave)
        isAutoPopUpCB.OnEvent("Click", enableAutoPopUp)
        cacheLevelDDL.OnEvent("Change", changeGMCacheLevel)
        extensionGui.OnEvent("Close", extensionGuiClose)
    }
    openExtensionBtn.GetPos(&extBtnX, &extBtnY, &extBtnW, &extBtnH)
    myGui.GetClientPos(&myGuiClientX, &myGuiClientY, &myGuiClientW, &myGuiClientH)
    extensionGui.Show("x" myGuiClientX + extBtnX + extBtnW " y" myGuiClientY + extBtnY " h" myGuiClientH - extBtnY - 32)
    ;勾选幽灵模式自动续档
    enableGMAutoSave(GuiCtrlObj, info)
    {
        checkedValue := GuiCtrlObj.Value
        global isEnableGMAutoSave := checkedValue
        writeMainCfg(checkedValue, isEnableGMAutoSaveKey)
        if !checkedValue
        {
            ;清理缓存
            clearGMSaveCache()
        }
    }
    ;勾选自动弹出扩展界面
    enableAutoPopUp(GuiCtrlObj, info)
    {
        writeMainCfg(GuiCtrlObj.Value, isAutoPopUpKey)
    }
    ;改变缓存深度
    changeGMCacheLevel(GuiCtrlObj, info)
    {
        global saveCacheLevel := GuiCtrlObj.Value
        writeMainCfg(saveCacheLevel, cacheLevelKey)
    }
    ;扩展界面关闭
    extensionGuiClose(GuiObj)
    {
        GuiObj.Destroy()
        global extensionGui := ""
    }
}

;配置文件处理-------------------------------------------------------------------------------------------------
;读取配置文件main
readMainCfg(Key?, default := "")
{
    return IniRead(profilesName, mainConfigName, Key ?? unset, default)
}
;写入配置文件main
writeMainCfg(value, key)
{
    if !FileExist(profilesName)
    {
        FileAppend "[" mainConfigName "]", profilesName, "CP0"
        defaultGameIDCfg()
    }
    IniWrite(value, profilesName, mainConfigName, key)
}
;读取游戏名称
readGameName(gameId)
{
    gameName := IniRead(profilesName, ubiGameIdConfigName, gameId, "")
    if gameName
        return gameName
    switch gameId {
        case 1771:
            return "《幽灵行动：荒野》纯育碧版"
        case 3559:
            return "《幽灵行动：荒野》Steam版"
        default:
            return "游戏名未收录,自行查询后编辑"
    }
}
;写入游戏名称
writeGameName(gameName, gameId)
{
    if !FileExist(profilesName)
    {
        FileAppend "[" mainConfigName "]", profilesName, "CP0"
        defaultGameIDCfg()
    }
    IniWrite(gameName, profilesName, ubiGameIdConfigName, gameId)
}
;读取游戏备份备注信息
readGameBackupInfo(gameBackupDir, backupTime, default := "")
{
    return IniRead(gameBackupDir "\" backupInfoIniName, backupTime, backupInfoKey, default)
}
;写入游戏备份备注信息
writeGameBackupInfo(gameBackupDir, backupTime, info)
{
    if !FileExist(gameBackupDir "\" backupInfoIniName)
    {
        FileAppend "[" mainConfigName "]", gameBackupDir "\" backupInfoIniName, "CP0"
    }
    IniWrite(info, gameBackupDir "\" backupInfoIniName, backupTime, backupInfoKey)
}

;工具退出时的处理-----------------------------------------------------------------------
exitAppFunc(*)
{
    if startBtn.gmxrStatus
    {
        stop()
    }
    ;清理幽灵模式自动续档缓存
    if isOpenGMAutoSave(currentGameId)
        clearGMSaveCache()
}
;工具点击关闭按钮
myGuiClose(thisGui)
{
	myGui.Opt("+OwnDialogs")
	result := warningMsgBox("确定退出？", "退出", "OKCancel Icon! Default2")
	if result = "OK"
	{
		ExitApp
	}else
		return true
}
;工具最小化、最大化
myGuiSize(GuiObj, MinMax, Width, Height)
{
    if (MinMax = -1)
    {
        if extensionGui
        {
            extensionGui.Hide()
        }
    } else
    {
        if extensionGui && (tabCtrl.Value = 1)
        {
            openGameExtension()
        }
    }
}
;重新加载
clickReload(*)
{
	Reload
}
;退出
clickExit(*)
{
	ExitApp
}
;清理幽灵模式自动续档缓存
clearGMSaveCache(*)
{
    if !saveGamesDir
        return
    if !currentUserId
        return
    if !currentGameId
        return
    if !isOpenGMAutoSave(currentGameId)
        return
    ;清理缓存
    lastCachePath := saveGamesDir "\" currentUserId "\" currentGameId "-" lastCacheExt
    if DirExist(lastCachePath)
    {
        try {
            DirDelete(lastCachePath, true)
        }
    }
}
;帮助/关于
showHelpInfo(*)
{
    MsgBox "
(
育碧存档全自动备份Beta1.1
GameXueRen制作。此工具开源免费，玩的开心！
https://github.com/GameXueRen/UbiSaveAutoBackup
游戏交流群：299177445（游击战王牌大队）

功能特色：
1. 仅在存档有变化时、一定时间间隔外才进行自动备份，无重复备份。
2. 可选择备份限制，超过限制自动清理最早的备份。
3. 支持游戏内按下快捷键进行“手动备份存档”。
4. 支持多用户多游戏的备份管理，支持对每个备份进行备注。
5. 额外扩展支持“幽灵模式”自动续档复活。

更新记录：
Beta1.0（2024/12/14）：
公测版1.0发布
Beta1.1（2024/12/19）：
1.修复已知BUG
2.更新界面排版，并收录大部分育碧游戏ID对应的名称
3.优化扩展功能：幽灵模式自动续档复活
)", "帮助/关于"
}

;通用----------------------------------------------------------------------------------
;获取文件变更动作对应的描述
getFileChangeActionDesc(action)
{
    switch action {
        case 1:
            return "已创建"
        case 2:
            return "已删除"
        case 3:
            return "已修改"
        case 4:
            return "已重命名(旧)"
        case 5:
            return "已重命名(新)"
        default:
            return "其他变化"
    }
}
;获取用户ID对应的头像路径
getUserLogoPath(userId)
{
    userLogoPath := RTrim(saveGamesDir, "\savegames") "\cache\avatars\" userId "_64.png"
    if !FileExist(userLogoPath)
    {
        userLogoPath := ""
    }
    return userLogoPath
}
;判断是否开启幽灵模式自动续档
isOpenGMAutoSave(gameId)
{
    if isEnableGMAutoSave && ((gameId = "1771") or (gameId = "3559"))
        return true
    return false
}
;从显示的游戏ID文本中获取游戏ID
parseGameIdFromText(gameIdText)
{
    if !gameIdText
        return ""
    parseIdTextArr := StrSplit(gameIdText, ":", , 2)
    if parseIdTextArr.Has(1)
    {
        return parseIdTextArr[1]
    }
    return ""
}
;从显示的游戏ID文本中获取游戏名称
parseGameNameFromText(gameIdText)
{
    if !gameIdText
        return ""
    parseIdTextArr := StrSplit(gameIdText, ":", , 2)
    if parseIdTextArr.Has(2)
    {
        return parseIdTextArr[2]
    }
    return ""
}
;新增运行日志
addRuningLog(logInfo)
{
    logListView.Add(, A_Hour ":" A_Min ":" A_Sec " " logInfo)
    count := logListView.GetCount()
    if count > maxShowLogCount
    {
        logListView.Delete(1)
        count := count-1
    }
    logListView.ModifyCol(1, "AutoHdr")
    logListView.Modify(count, "Vis")
}
;加载中提示界面
showLoading(isShow := true, loadText := "")
{
    static loadingGui := ""
    if isShow
    {
        if !loadingGui
        {
            ; +ToolWindow +Caption 
            loadingGui := Gui("+Disabled -Resize -SysMenu +ToolWindow +Owner" myGui.Hwnd, "正在加载中...")
            loadingGui.SetFont("s16 bold")
            loadingGui.gmxrW := 160
            loadingGui.gmxrH := 40
            loadingGui.AddText("vloadText +0x200 x0 y0 w" loadingGui.gmxrW " h" loadingGui.gmxrH, "正在加载中...")
        }
        if loadText
        {
            loadingGui["loadText"].Text := loadText
            loadingGui.Title := loadText
        }
        myGui.GetPos(&myGuiX, &myGuiY, &myGuiW, &myGuiH)
        myGui.Opt("+Disabled")
        loadingGui.Show("x" Integer(myGuiX + (myGuiW-loadingGui.gmxrW)/2) " y" Integer(myGuiY + (myGuiH-loadingGui.gmxrH)/2) " w" loadingGui.gmxrW " h" loadingGui.gmxrH)
        loadingGui.gmxrShowTime := A_TickCount
    }else
    {
        if !loadingGui
            return
        ;至少显示1秒的加载时间
        loadTime := A_TickCount - loadingGui.gmxrShowTime
        if loadTime < 1000
        {
            SetTimer(hideLoading, loadTime-1000)
        }else
        {
            hideLoading()
        }
    }
    ;取消加载中显示
    hideLoading(*)
    {
        myGui.Opt("-Disabled")
        loadingGui.Destroy()
        loadingGui := ""
    }
}
;以管理员身份运行
runAsAdmin()
{
    full_command_line := DllCall("GetCommandLine", "str")
    if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
    {
        try
        {
            if A_IsCompiled
                Run '*RunAs "' A_ScriptFullPath '" /restart'
            else
                Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
        }
        ExitApp
    }
}
;向GuiControl添加、更新、删除工具提示
;Tooltip文档：https://learn.microsoft.com/zh-cn/windows/win32/controls/tooltip-control-reference
ControlAddTip(GuiCtrlObj, TipText)
{
	if !(GuiCtrlObj is Gui.Control)
		return 0
	currGui := GuiCtrlObj.Gui
	guiHwnd := currGui.Hwnd
	ctrlHwnd := GuiCtrlObj.Hwnd
	if currGui.HasProp("gmxrTipHwnd")
		tipHwnd := currGui.gmxrTipHwnd
	else
		tipHwnd := 0
	if !tipHwnd
	{
		;初始化创建工具提示，并返回窗口句柄
		CW_USEDEFAULT := 0x80000000
		tipHwnd := DllCall("CreateWindowEx"
			, "UInt", 0                      			  ;-- dwExStyle WS_EX_TOPMOST := 0x8
			, "Str", "TOOLTIPS_CLASS32"                   ;-- lpClassName
			, "Ptr", 0                                    ;-- lpWindowName
			, "UInt", 0x1 | 0x2        					  ;-- dwStyle TTS_ALWAYSTIP | TTS_NOPREFIX
			, "UInt", CW_USEDEFAULT                       ;-- x
			, "UInt", CW_USEDEFAULT                       ;-- y
			, "UInt", CW_USEDEFAULT                       ;-- nWidth
			, "UInt", CW_USEDEFAULT                       ;-- nHeight
			, "Ptr", guiHwnd                              ;-- hWndParent
			, "Ptr", 0                                    ;-- hMenu
			, "Ptr", 0                                    ;-- hInstance
			, "Ptr", 0                                    ;-- lpParam
			, "Ptr")                                      ;-- Return type
		currGui.gmxrTipHwnd := tipHwnd
		;设置工具提示支持多行显示，且最大宽度为屏幕宽度
		SendMessage 0x0418, 0, A_ScreenWidth*96//A_ScreenDPI, tipHwnd ;TTM_SETMAXTIPWIDTH
	}
	cbSize := 24 + (A_PtrSize * 6)
	TOOLINFO := Buffer(cbSize, 0)
	; cbSize
	; uFlags：TTF_SUBCLASS | TTF_IDISHWND (0x10 | 0x1).将鼠标信息转发给控制器、uId参数为Hwnd
	; hwnd, uID
	NumPut("UInt", cbSize, "UInt", 0x11, "Ptr", guiHwnd, "Ptr", ctrlHwnd, TOOLINFO)
	;查询工具提示中是否已注册该控件
	try
		isRegister := SendMessage(0x435, 0, TOOLINFO, tipHwnd) ;TTM_GETTOOLINFOW
	catch Error
		isRegister := false
	;向控件添加、更新或删除工具提示
	if TipText
	{
		;填充工具提示文本到 TOOLINFO
		NumPut("Ptr", StrPtr(TipText), TOOLINFO, 24 + (A_PtrSize * 3))
		;文本不为空，如果控件已注册则更新提示，否则添加注册
		if isRegister
			SendMessage(0x0439, 0, TOOLINFO, tipHwnd) ;TTM_UPDATETIPTEXTW
		else
			SendMessage(0x0432, 0, TOOLINFO, tipHwnd) ;TTM_ADDTOOLW
	} else
	{
		;文本为空且已注册则删除提示
		if isRegister
			SendMessage(0x0433, 0, TOOLINFO, tipHwnd) ;TTM_DELTOOLW
	}
	return tipHwnd
}
;主动启用或停用工具提示(默认启用)
GuiSetTipEnabled(GuiObj, isEnable)
{
	if !(GuiObj is Gui)
		return
	if !GuiObj.HasProp("gmxrTipHwnd")
		return
	tipHwnd := GuiObj.gmxrTipHwnd
	if !tipHwnd
		return
	if isEnable
		SendMessage 0x401, True, 0, tipHwnd ;TTM_ACTIVATE 启用
	else
		SendMessage 0x401, False, 0, tipHwnd ;停用
}
;设置工具提示的延迟时间
GuiSetTipDelayTime(GuiObj, Automatic?, Initial?, AutoPop?, Reshow?)
{
	if !(GuiObj is Gui)
		return
	if !GuiObj.HasProp("gmxrTipHwnd")
		return
	tipHwnd := GuiObj.gmxrTipHwnd
	if !tipHwnd
		return
	;自动档，依据初始显示延迟时间，自动弹出和重新显示延迟时间分别为其10倍、1/5
	if IsSet(Automatic)
	{
		if !IsInteger(Automatic) or (Automatic < 0)
			Automatic := -1 ;默认值
		else if Automatic > 3200
			Automatic := 3200
		SendMessage 0x403, 0, Automatic, tipHwnd ;TTM_SETDELAYTIME TTDT_AUTOMATIC		
		return
	}
	;设置初始显示延迟时间
	if IsSet(Initial)
	{
		if !IsInteger(Initial) or (Initial < 0)
			Initial := -1 ;默认值为500毫秒
		else if Initial > 32000
			Initial := 32000
		SendMessage 0x403, 3, Initial, tipHwnd ;TTM_SETDELAYTIME TTDT_INITIAL
	}
	;设置自动弹出延迟时间
	if IsSet(AutoPop)
	{
		if !IsInteger(AutoPop) or (AutoPop < 0)
			AutoPop := -1 ;默认值为5000毫秒
		else if AutoPop > 32000
			AutoPop := 32000 ;允许的最大值为32000毫秒
		SendMessage 0x403, 2, AutoPop, tipHwnd ;TTM_SETDELAYTIME TTDT_AUTOPOP
	}
	;设置从一个控件移动到另一个控件，重新显示延迟时间
	if IsSet(Reshow)
	{
		if !IsInteger(Reshow) or (Reshow < 0)
			Reshow := -1 ;默认值为100毫秒
		else if Reshow > 32000
			Reshow := 32000
		SendMessage 0x403, 1, Reshow, tipHwnd ;TTM_SETDELAYTIME TTDT_RESHOW
	}
}
;普通的警告样式弹窗
warningMsgBox(text?, title?, options?)
{
    if IsSet(myGui)
    {
        myGui.Opt("+OwnDialogs")
        myGui.GetPos(&myGuiX, &myGuiY)
        msgBoxX := myGuiX + 50
        msgBoxY := myGuiY + 180
        res := MsgBoxAt(msgBoxX, msgBoxY, text ?? unset, title ?? "警告！", options ?? "Icon!")
    } else
        res := MsgBox(text ?? unset, title ?? "警告！", options ?? "Icon!")
    return res ?? ""
}
;支持自定义弹出坐标的MsgBox
MsgBoxAt(x, y, text?, title?, options?)
{
    if hHook := DllCall("SetWindowsHookExW", "int", 5, "ptr", cb := CallbackCreate(CBTProc), "ptr", 0, "uint", DllCall("GetCurrentThreadId", "uint"), "ptr") {
        res := MsgBox(text ?? unset, title ?? unset, options ?? unset)
        if hHook
            DllCall("UnhookWindowsHookEx", "ptr", hHook)
    }
    CallbackFree(cb)
    return res ?? ""
    CBTProc(nCode, wParam, lParam) {
        if nCode == 3 && WinGetClass(wParam) == "#32770" {
            DllCall("UnhookWindowsHookEx", "ptr", hHook)
            hHook := 0
            pCreateStruct := NumGet(lParam, "ptr")
            NumPut("int", x, pCreateStruct, 44)
            NumPut("int", y, pCreateStruct, 40)
        }
        return DllCall("CallNextHookEx", "ptr", 0, "int", nCode, "ptr", wParam, "ptr", lParam)
    }
}
;已收录游戏ID对应的名称
defaultGameIDCfg(*)
{
    FileAppend "
    (

[ubiGameIdInfo]
4=《刺客信条2》
26=Assassin's Creed Brotherhood
40=《刺客信条：启示录》
54=《刺客信条3》
82=Assassin's Creed
103=Assassin's Creed III (RU)
104=Assassin's Creed III (JPN)
105=Assassin's Creed III (CZ)
273=《刺客信条：大革命》纯育碧版
437=《刺客信条：大革命》Steam版
441=Assassin's Creed IV Black Flag (RU)
442=Assassin's Creed IV Black Flag (Asia)
625=Assassin's Creed Liberation HD
632=Assassin's Creed Liberation HD (Uplay version/Australia)
664=Assassin's Creed Freedom Cry
720=《刺客信条：大革命》纯育碧版
857=《刺客信条：大革命》Steam版
895=《刺客信条：叛变》
934=Assassin's Creed Rogue (Steam Version)
944=Assassin's Creed Unity (RU)
945=Assassin's Creed Unity (RU) (Steam Version)
1186=Assassin's Creed Rogue (RU)
1187=Assassin's Creed Rogue (RU) (Steam Version)
1651=Assassin's Creed Chronicles China
1661=Assassin's Creed Rogue Asia
1662=Assassin's Creed Rogue Asia (Steam)
1841=Assassin's Creed Chronicles China (Steam Version)
1847=Assassin's Creed Chronicles India
1848=Assassin's Creed Chronicles Russia
1849=Assassin's Creed Chronicles India (Steam)
1850=Assassin's Creed Chronicles Russia (Steam)
1875=《刺客信条：枭雄》纯育碧版
1955=Assassin's Creed Syndicate (RU)
1956=Assassin's Creed Syndicate Asia
1957=《刺客信条：枭雄》Steam版
1958=Assassin's Creed Syndicate (RU) (Steam Version)
3539=《刺客信条：起源》纯育碧版
4919=Assassin's Creed II (Steam Version)
4923=《刺客信条：起源》Steam版
5059=《刺客信条：奥德赛》纯育碧版
5092=《刺客信条：奥德赛》Steam版
5100=Discovery Tour by Assassin's Creed: Ancient Egypt
5183=《刺客信条3重制版》纯育碧版
5184=《刺客信条3重制版》Steam版
5404=Discovery Tour: Ancient Greece by Ubisoft
6100=《刺客信条：幻景》纯育碧版
6101=《刺客信条：幻景》Steam版
7013=《刺客信条：英灵殿》Steam版
11373=Discovery Tour: Ancient Egypt by Assassin's Creed (Steam)
13504=《刺客信条：英灵殿》纯育碧版
19000=Discovery Tour: Viking Age by Ubisoft

46=Far Cry 3
84=Far Cry
85=Far Cry 2
205=《孤岛惊魂3：血龙》
420=《孤岛惊魂4》纯育碧版
856=Far Cry 4 (Steam version/Australia)
969=Far Cry 4 RU
1803=《孤岛惊魂5》纯育碧版
4311=《孤岛惊魂5》Steam版
2010=《孤岛惊魂：原始杀戮》
2029=Far Cry Primal (Steam version/Australia)
5210=《孤岛惊魂：新曙光》纯育碧版
5211=《孤岛惊魂：新曙光》Steam版
5266=《孤岛惊魂6》纯育碧版
920=《孤岛惊魂6》Steam版
17772=Far Cry 6 Episode 1 Insanity DLC
17773=Far Cry 6 Episode 2 Pagan: Control DLC
17774=Far Cry 6 Episode 3 Joseph: Collapse DLC
19028=Far Cry 6 Offline Mode "DLC"

274=Watch_Dogs
541=Watch_Dogs (Steam)
543=Watch_Dogs (RU)
545=Watch Dogs Asia
741=Watch_Dogs (Steam)
828=Watch Dogs Asia (Steam)
1428=Watch_Dogs Complete Edition
2688=《看门狗2》纯育碧版
3353=《看门狗：军团》纯育碧版
3619=《看门狗2》Steam版
7017=《看门狗：军团》Steam版

2=Tom Clancy's Splinter Cell Conviction
53=Tom Clancy's Ghost Recon Future Soldier
83=Tom Clancy's EndWar
88=Tom Clancy's Rainbow Six Vegas
91=Tom Clancy's Splinter Cell Blacklist
95=Tom Clancy's Splinter Cell Chaos Theory™
108=Tom Clancy's Rainbow Six Vegas 2
109=Tom Clancy's Splinter Cell
110=Tom Clancy's Splinter Cell Double Age
358=Tom Clancy's Rainbow Six Lockdown
449=Tom Clancy's Splinter Cell Blacklist (Steam)
568=Tom Clancy's The Division
635=《彩虹六号：围攻》
1771=《幽灵行动：荒野》纯育碧版
2970=Tom Clancy's Ghost Recon Wildlands (Open Beta)
1835=Tom Clancy's The Division (RU)
1842=Tom Clancy's Rainbow Six Siege (RU)
1843=Tom Clancy's Rainbow Six Siege (Steam)
2036=Tom Clancy's The Division Beta
2235=Tom Clancy's Rainbow Six 3 Gold
2297=Tom Clancy's Ghost Recon
2298=Tom Clancy's Rainbow Six
3502=Tom Clancy's The Division PTS
3559=《幽灵行动：荒野》Steam版
4865=Tom Clancy's Rainbow Six Siege Test Server
4932=Tom Clancy's The Division 2
4984=Tom Clancy's Ghost Recon Wildlands Open Beta
5159=Tom Clancy's The Division 2 - PPS
5271=Tom Clancy's Rainbow Six Extraction
10424=Tom Clancy's Rainbow Six Siege Test Server (Steam)
11903=《幽灵行动：断点》
12737=Tom Clancy's Ghost Recon Breakpoint (Uplay Open + Closed Beta)

11=Prince of Persia The Forgotten Sands
111=Prince of Persia: The Sands of Time
113=Prince of Persia: The Two Thrones
121=Prince of Persia: Warrior Within
277=Prince of Persia (2008)
6145=Prince of Persia: The Lost Crown

22=Anno 2070
71=Anno 2070 (Steam)
89=Anno 1404
678=ANNO 2070 Complete Edition
680=Anno 2070 RUS
1253=Anno 2205
2990=Anno 1602
4553=Anno 1800 (Uplay)
4554=Anno 1800 (Uplay+Steam)
13800=Anno 1800 - Open Beta
16232=Anno 1404 - History Edition
16234=Anno 1503 - History Edition
16236=Anno 1602 - History Edition
16238=Anno 1701 - History Edition

413=The Crew (Worldwide)
507=The Crew (Russian)
665=The Crew 2 (Steam Version)
750=The Crew (Beta)
2855=The Crew 2 (Uplay Connect)
5037=The Crew 2

8=The Settlers 7: Paths to a Kingdom
18=The Settlers Online
3037=The Settlers - New Allies
11662=The Settlers - History Edition
11783=The Settlers 2: Veni, Vidi, Vici=History Edition
11784=The Settlers 3 - History Edition
11785=The Settlers 4 - History Edition
11786=The Settlers 5: Heritage of Kings=History Edition
11787=The Settlers 6 - History Edition
11788=The Settlers 7: Paths to a Kingdom=History Edition

80=Rayman Origins
360=Rayman 3 Hoodlum Havoc
361=Rayman 2 The Great Escape
362=Rayman Raving Rabbids
410=Rayman Legends
411=Rayman Legends Demo
509=Rayman Chinese Special Edition
2968=Rayman Forever
5850=Rayman Jungle Run
5860=Rayman Fiesta Run
61578=Rabbids: Party of Legends

44=Might & Magic Heroes VI
64=Might & Magic VI-Pack
87=Heroes of Might and Magic V
348=Might and Magic VII: For Blood and Honor
349=Might & Magic VIII: Day of the Destroyer
350=Might & Magic IX
352=Heroes of Might & Magic II Gold Edition
353=Heroes of Might & Magic III Complete Edition
354=Heroes of Might & Magic IV Complete Edition
401=《魔法门10：传承》
402=Might & Magic X Legacy (Steam)
403=Might & Magic X Legacy (Uplay+Steam)
1176=《魔法门之英雄无敌7》纯育碧版
1177=《魔法门之英雄无敌7》Steam版
5042=Might & Magic Heroes VI
5613=Might & Magic - Chess Royale

78=Trials Evolution: Gold Edition
297=Trials Fusion
318=Trials Fusion (Steam)
834=Trials Fusion Demo (Steam)
1275=Trials Fusion Multiplayer Beta
3301=Trials of the Blood Dragon (Steam)
3600=《特技摩托：崛起》纯育碧版
3601=《特技摩托：崛起》Steam版
5233=Trials Rising - Open Beta
5454=Trials Rising Demo

3352=UNO (Uplay)
3360=UNO (Uplay+Steam)
3361=UNO Demo
3765=UNO - Rayman Theme Cards
3766=UNO - Just Dance Theme Cards
3776=UNO - Winter Theme Cards
16383=UNO - Flip Theme Cards
17860=UNO - Fenyx's Quest Theme Cards
17942=UNO - 50th Anniversary Theme Cards
59689=UNO - The Call of Yara Theme Cards
60710=UNO - AC Valhalla Theme Cards

3=Silent Hunter: Battle of the Atlantic Gold Edition
5=Trial Rising Demo
13=Driver: San Francisco
20=Shaun White Snowboarding
30=From Dust
68=Silent Hunter 5
90=World In Conflict
93=I am Alive
232=Beyond Good and Evil
233=Cold Fear
270=Brothers in Arms: Road to Hill 30
271=Brothers in Arms: Earned in Blood
272=Brothers in Arms: Hell's Highway
292=Silent Hunter III
293=Silent Hunter 4 Gold Edition
422=Flashback
423=Flashback Demo
424=Driver San Francisco (Steam)
540=ShootMania Storm Elite Demo
569=For Honor
609=《光之子》纯育碧版
611=《光之子》Steam版
659=Valiant Hearts (Uplay)
661=Valiant Hearts (Steam)
688=Lock On
693=Petz Horsez 2
698=Silent Hunter 4 Wolves of the Pacific (Uplay)
699=Silent Hunter 4 Wolves of the Pacific: U-Boat Missions (Uplay)
801=Child of Light Demo
825=Champions of Anteria
1653=ZOMBI (Uplay)
1713=Skull and Bones
1832=Zombi (Uplay+Steam)
2070=Trackmania Turbo
2170=Champions of Anteria (Steam)
2988=Silent Hunter 2
2992=Panzer General 3D Assault
2993=Panzer General 2
3044=POD Gold
3050=Imperialism
3051=Imperialism 2
3052=Speed Busters: American Highways
3053=Warlords Battlecry
3054=Warlords Battlecry 2
3088=South Park: The Fractured But Whole
3097=Champions of Anteria Demo
3098=Champions of Anteria Demo (Steam)
3130=Just Dance 2017
3131=Just Dance 2017 (Steam)
3279=Steep
3280=Steep (Steam)
3445=Steep Open Beta
3458=For Honor
3584=South Park - The Stick of Truth
3774=Monopoly Plus
3775=Monopoly Plus (Steam)
4472=Steep Open Beta (Steam)
4740=Avatar: Frontier of Pandora (Uplay)
4502=South Park: The Fractured But Whole (Steam)
5277=Starlink: Battle For Atlas
5405=Immortals Fenyx Rising
5408=《疯狂兔子：编程学院》
5487=Riders Republic
5595=Trackmania
5705=Scott Pilgrim vs the World: The Game
5726=Immortal Fenyx Rising Demo
5870=Hungry Shark World
6116=The Last Friend
6150=Skull and Bones Open Beta Closed Beta
9662=Valiant Hearts: Coming Home
9797=Ode
10871=Transference
10885=Steep Road To The Olympics Beta
10886=Steep Road To The Olympics Beta (Steam)
11899=Roller Champions
11957=Hyper Scape
15657=XDefiant Closed Beta
17903=Star Wars: Outlaws
17905=Monopoly Madness
60951=Project U
61432=Fell Seal: Arbiter's Mark
61499=Evan's Remains
61503=Astrologaster
61515=Lake
61517=A Normal Lost Phone
62326=Immortals Fenyx Rising (Steam)

276=Prince of Persia
2052=Anno 2205 (unknown Version)
    )", profilesName, "CP0"
}