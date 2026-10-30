# Docker 起不来

2026-10-21，Windows 11 专业版，Docker Desktop 4.96.0。装完引擎一直卡在 "Starting the Docker Engine..."，记一下最后怎么好的。

## 结论：不是 Docker 的问题，是 WSL2 没装成

Docker 4.96 是用户级安装，只支持 WSL2 后端。WSL2 起不来，引擎就一直卡着。

查到的几条：

- `HKCU:\...\Lxss` 不存在，从没装过 WSL 发行版
- `System32\lxss\tools\kernel` 不存在，内核缺失
- `%LOCALAPPDATA%\Docker\wsl` 是空的，虚拟机从没创建过
- `settings-store.json` 只有 6 个键，正常应该几十个，说明初始化没走完
- 系统里有 3 个待重启项（CBS 组件安装 / Windows Update / 文件重命名挂起）
- `vmcompute` 服务 Running，BIOS 虚拟化也开着，虚拟化平台本身没问题

**关键是有 3 个待重启项。** 这种状态下装 WSL 会失败，或者装了不生效，所以第一步得先重启。我一开始先去装 WSL，白折腾了半天。

## 我做的

1. 重启电脑。重启前先退出 Docker Desktop（托盘图标右键 → Quit）
2. `wsl --status` 看状态。显示「默认版本: 2」就直接跳到第 5 步
3. 用**管理员** PowerShell 跑 `wsl --install --no-distribution`。只装内核不装 Ubuntu，Docker 会自己建 `docker-desktop` 发行版
4. **再重启一次**。这步我没省，第二次重启之后引擎才真正起来
5. 打开 Docker Desktop，等 1 到 3 分钟，左下角变绿色的 Engine running
6. 新开一个窗口跑 `docker run --rm hello-world`，出现 `Hello from Docker!` 就算好了

`wsl --install` 报错的话，手动开功能（同样要管理员）：

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

重启之后补两条：

```powershell
wsl --update
wsl --set-default-version 2
```

## 遇到的两个错误码

- `0x8007019e`：WSL 功能没启用，回到上面手动开功能那一步
- `0x80370102`：虚拟化没开，进 BIOS 开 `Intel VT-x` / `AMD-V`。我这台 systeminfo 显示虚拟化已开启，所以不是这条

## 如果 WSL 彻底装不上

还有两条路。

一是换 Hyper-V 后端，需要专业版，开完功能后在 Settings → General 里取消勾选 "Use the WSL 2 based engine"。

二是干脆不用 Docker，本机装 JDK 17 + MySQL 8 + `pip install pyspark`，把 `hello_spark.py` 里的 JDBC 地址从 `mysql:3306` 改成 `localhost:3306`，本地模式跑。效果一样，只是少了容器这一层。

## 再出问题按这个查

```powershell
wsl --status
Get-Content "$env:LOCALAPPDATA\Docker\log\vm\init.log" -Tail 20
Get-Content "$env:APPDATA\Docker\settings-store.json" -Raw   # 只有几个键就是没初始化
Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
```
