# XAC VST3 插件（配套 XAC 虚拟音频设备）

用 JUCE 8 编写的两个 VST3 效果插件，作为 XAC 虚拟音频设备的处理/桥接节点
（等价于 Windows 上 WDM2VST + VST2WDM 的分工）：

- **XAClive.vst3** —— 虚拟麦克风处理节点。放一条轨道：input = 真实麦，output = `XAC live` 设备 → 得到「处理后的虚拟麦」。
- **XACmusic.vst3** —— 虚拟喇叭处理节点。放一条轨道：input = `XAC music` 设备，output = 真实喇叭 → 捕获/处理系统音频。

## 功能（v1 桥接）
输入增益、输出电平、相位反转、旁路直通、输入/输出电平表。

## 构建
GitHub Actions（macOS runner）自动编译并打包成单个 `XACVST.pkg`，
安装到 `/Library/Audio/Plug-Ins/VST3/`。

## 许可
JUCE GPLv3 + Steinberg VST3 SDK GPLv3。仅限个人 / 非商业使用。
商用需 JUCE 商业许可 + Steinberg 授权。