# NativeRefresh
Native SwiftUI Pool to Refresh

<img align="left" src="https://github.com/Nayzus/NativeRefresh/blob/main/example.gif" alt="drawing" width="400"/>

## Installation

Ready for use on iOS 13+.

Swift Package Manager

The Swift Package Manager is a tool for automating the distribution of Swift code and is integrated into the swift compiler. It’s integrated with the Swift build system to automate the process of downloading, compiling, and linking dependencies.

Once you have your Swift package set up, adding as a dependency is as easy as adding it to the dependencies value of your Package.swift.


```swift
dependencies: [
    .package(url: "https://github.com/ivanvorobei/SPAlert", .upToNextMajor(from: "4.2.0"))
]
```

## Quick Start

To start, you need to import the package `import NativeRefresh`

```swift
            RefreshableScrollView {
                YourContent()
            }
            .onRefresh {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }

```

## Aviable API

Base function for working with refresh action:

```swift
            RefreshableScrollView {}
                .onRefresh {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                }
```

To customize the Refresh Control stylet, use the protocol  `RefreshControlStyle`:

```swift
            RefreshableScrollView {}
                .refreshControlStyle(CircularRefreshControlStyle())
```

