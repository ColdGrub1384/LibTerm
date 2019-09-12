# LibTerm

LibTerm is a terminal for iOS with Python 3.7 and Lua 5.3. Supports iOS 13 dark mode and multi window.

[![Download on the App Store](https://pisth.github.io/appstorebadge.svg)](https://itunes.apple.com/us/app/libterm/id1380911705?ls=1&mt=8)

# Features

The app supports most of OpenTerm features, but LibTerm has Python 3.7 instead of Cub. It supports opening directories outside the sandbox with `UIDocumentPickerViewController`, multi tabbing and suggestions. Errors are shown in red!

## Programming languages

LibTerm contains Python 2.7, Python 3.7, Lua and you can even code C. Compile your C sources with `clang` into LLVM IR code and interpret the LLVM IR code with the `lli` command.

## `package`

LibTerm contains a `package` command. With `package`, you can download and install third party commands. You can publish your own commands by submitting a Pull Request to https://github.com/ColdGrub1384/LibTerm-Packages.

# Building

1. `$ ./setup.sh`
2. Build `LibTerm` or `LibTermCore` target from `LibTerm.xcodeproj`

# Acknowledgments

- [llvm](https://github.com/holzschu/llvm) (fork by Nicolas Holzschuch)
- [InputAssistant](https://github.com/IMcD23/InputAssistant)
- [ios_system](https://github.com/holzschu/ios_system)
- [OpenTerm](https://github.com/louisdh/openterm) (This is not a fork of OpenTerm but I used some code like the ANSI parser and I learned from it.)
- [TabView](https://github.com/IMcD23/TabView)

