# Wine桌面

## 这是什么？

这是一个使用Termux、Termux-X11、Box64以及Wine，在Android上运行Windows软件的方案。

### 什么是Termux

这是一个终端模拟器（

简单地说，Termux能够让你在Android上使用一个类似于Linux上的命令行。
并且通过chroot或者proot能够模拟一个Linux环境。

### 什么是Termux-X11

这是一个显示器模拟器（

这个软件实现了部分Xorg协议，能够免于使用VNC并直接访问一个Linux环境桌面。

### 什么是Wine

这是一个Windows模拟器（

~~以下只是个人目前了解的一些，或许不完全对~~

简单来说，Wine是一种兼容层软件，并且与虚拟化软件不同。
打个比方，虚拟化软件通过“翻译”指令的方式运行其他格式的软件。
而Wine使用“翻译”系统调用的方式运行软件。
这种方式使得Wine能有更高的效率，以及更低的资源占用。
但由于Windows与Linux（或者说类Unix）的系统调用并不相同，
Wine并不保证能够完全兼容Windows软件。

### 什么是Box64

这是一个x64模拟器（

这个项目使x86-64（有时也称作amd64）或者x86[^box86]
（也就是Intel 80x86系列的处理器架构，比如i386）架构的软件，
能够在ARM架构的处理器上运行。

[^box86]: 需要使用Box86

## 有什么用？

没什么用，~~只是能够帮助你安装并使用Wine x64版本，附带启动一个Wine桌面。~~
或许需要手动安装，不过我的另一个项目
[wine桌面安装器](https://github.com/Huzerovo/wine-desktop-installer)提供了一个
方便的命令。

## 项目怎么用？

1. 下载[Termux](https://github.com/termux/termux-app)与
   [Termux-X11](https://github.com/termux/termux-x11)
2. `git clone https://github.com/Huzerovo/wine-desktop.git`下载本项目
3. 切换到项目文件夹，并运行`chmod +x ./install.sh && ./install.sh`
4. 按照提示完成安装，若中间的安装出错，可尝试重新执行`./install.sh`重试安装

## 一些注意事项

- 使用了`proot-distro`模拟了一个Debian Linux环境
- 有一个快捷程序`start-debian`安装在了`$HOME/.local/bin`
- 安装时会附带安装[wine桌面安装器](https://github.com/Huzerovo/wine-desktop-installer)。
  你可以使用`start-debian`切换到PRoot后，在`.local/share/wine-desktop`找到它
- 需要一个流程的网络环境
- 项目大概自用，维护看心情。~~反正也没人用òᆺó~~
- 有问题也可以在issues提一下

## 相关项目

- [Termux](https:/termux.dev)
- [Termux PRoot](https://wiki.termux.com/wiki/PRoot)
- [Wine](https:/www.winehq.org)
- [Box64](https:/github.com/ptitSeb/box64)
- [Box86](https:/github.com/ptitSeb/box86)

感谢以下项目的启发

- [Box64Droid](https://github.com/llya114/Box64Droid)
- [AnBox86_64](https://github.com/Kualid/AnBox86)
