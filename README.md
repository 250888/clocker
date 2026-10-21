# Clocker · 钟慢自律 ⏱

> 用狭义相对论，根治拖延症 —— **你的行动速度，决定你的时间流速**
> 努力钟慢、摆烂钟快：专注时界面时间流速变慢，摆烂时变快。
> 在线版（Web）：https://250888.github.io/clocker/

## ⚠️ Clone / 构建路径必须是纯 ASCII

**Windows 下，仓库所在的整条目录路径不能包含中文或其它非 ASCII 字符**，否则
`flutter build windows` 会在读取 `app.dill` 时把路径转成系统 ANSI 代码页（GBK）乱码，
报错形如 `Unable to read file: …锟斤拷…app.dill`，构建直接失败。

```powershell
# ✅ 正确：整条路径纯 ASCII
git clone https://github.com/250888/clocker.git C:\work\clocker
cd C:\work\clocker\clocker_app
flutter pub get
flutter build windows --release

# ❌ 错误：路径含中文
git clone https://github.com/250888/clocker.git C:\项目\clocker
```

只有**目录链**要求 ASCII；README、注释、源码里的中文不受影响。
另外，Windows 构建会在 `windows\flutter\ephemeral\.plugin_symlinks\` 里创建插件符号链接，
需要打开 Windows「开发者模式」才能通过。

## 原始 Flutter 模板说明

clocker
A new Flutter project.
Getting Started
This project is a starting point for a Flutter application.
A few resources to get you started if this is your first Flutter project:
Learn Flutter
Write your first Flutter app
Flutter learning resources
For help getting started with Flutter development, view the
online documentation, which offers tutorials,
samples, guidance on mobile development, and a full API reference.
