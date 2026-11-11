# 花拾归匣

## 版本
v1.0.0

## Android Release 构建

发布构建请使用脚本，自动启用代码混淆、剥离 Dart 调试符号并输出符号文件：

```bash
tool/build_android_release.sh aab
tool/build_android_release.sh apk
```

符号文件位于 `build/symbols/`，请妥善归档，用于解析线上崩溃堆栈。
