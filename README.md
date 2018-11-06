# LibTerm

LibTerm is a terminal for iOS.

This app is like @louisdh - [OpenTerm](https://github.com/louisdh/openterm) but this terminal is embeddable in your own app and it supports Lua and Python 2.7.

## Motivation

I like a lot [OpenTerm](https://github.com/louisdh/openterm) but I wanted to make the code better. Also, I wanted to integrate a local shell into [Pisth](https://github.com/ColdGrub1384/Pisth) so I made the project embeddable. I will upload to app to the App Store soon since [OpenTerm](https://github.com/louisdh/openterm) is no more available. This is not a fork from  [OpenTerm](https://github.com/louisdh/openterm), I rewrote the code.

# Building

1. Clone all submodules
2. Download `release.tar.gz` from [ios_system latest release](https://github.com/holzschu/ios_system/releases/latest).
3. Unarchive the file.
4. Move ios_system to the `ios_system`.

# Embedding

LibTerm is embeddable so you can use it in your own  app. To do it, download releases and embed all frameworks in your app. Then, you can present a `LTTerminalViewController`. You can also compile the `LibTermCore` framework and embed it in your app. You will need to embed `InputAssistant` and `ios_system` also. You also have to include [commandDictionary.plist](https://github.com/ColdGrub1384/LibTerm/blob/master/LibTerm/commandDictionary.plist) and [extraCommandsDictionary.plist](https://github.com/ColdGrub1384/LibTerm/blob/master/LibTerm/extraCommandsDictionary.plist) to your app's bundle.

## Usage

### Instantiating the terminal

```swift
LTTerminalViewController.makeTerminal(preferences: <#LTTerminalViewController.Preferences#>, shell: <#LibShell#>)
```

### Accessing the Text view

```swift
LTTerminalViewController.terminalTextView
```

### Extending

You can add a command by subclassing `LibShell`:

```swift

func python3_main(argc: Int, argv: [String], io: LTIO) -> Int32 {
    // Code here...
    
    return 0
}

class Shell: LibShell {

    var commands: [String : LTCommand] {
        return super.commands+["python3", python3_main]
    }

}

let terminal = LTTerminalViewController(shell: Shell())
```

You can also add it to the suggestion bar:

```swift
LTHelp.append(LTCommandHelp(name: "python3", commandInput: .file))
```

[See documentation](https://coldgrub1384.github.io/LibTerm)

# Acknowledgments

- [InputAssistant](https://github.com/IMcD23/InputAssistant)
- [ios_system](https://github.com/holzschu/ios_system)
- [OpenTerm](https://github.com/louisdh/openterm) (This is not a fork of OpenTerm but I used some code like the ANSI parser and I learned from it.)
- [TabView](https://github.com/IMcD23/TabView)

