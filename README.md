# ExtensionUbiquitySampleProject

## Getting Started

These instructions will get you a copy of the project up and running on your 
local machine for development and testing purposes. See deployment for notes on 
how to deploy the project on a live system.

### Prerequisites

This application is dependency managed using [Carthage][], the decentralized 
package manager for iOS frameworks. Ensure you  have Carthage installed by running

```shell
brew install carthage
```

if you don't have `brew` installed on your machine, get it here: [homebrew][]

[Carthage]: https://github.com/Carthage/Carthage
[homebrew]: https://brew.sh

If you haven't used Carthage in a while, or run into problems building dependencies,
make sure your carthage binary is up to date with

```shell
brew update
```

### Makefile

[Makefile][] contains quick shortcuts for basic activities in the command line.

[Makefile]: ./Makefile

### Installing

First install the dependencies for the project using Carthage:

```
make install
```

Once carthage finishes downloading and building the dependencies open 
[xcodeproj][] and build (⌘B) the project to ensure the dependency 
installation went smoothly. 

[xcodeproj]: ./com.github.kautenja.ExtensionUbiquitySampleProject.ExtensionUbiquitySampleProject.xcodeproj

### Entitlements / Capabilities

i imagine the entitlements will be messed up given their account based nature? 
Make sure for both the application target _as well as_ (i always forget this 
part) the extension target have the required capabilities pointing to the same 
containers:

* icloud: `iCloud.com.github.kautenja.EUSP`
* app groups: `group.com.github.kautenja.EUSP`

if for whatever reason you need to specify different values for those 
containers you'll need to change the hard coded strings at the top of 
[ CoreDataStack.swift](./TodayExtension/CoreDataStack.swift) to match:

```swift
...
/// the id of the shared group for the applications
let appGroupID = "group.com.github.kautenja.EUSP"

/// the id for the CloudKit container
let cloudKitContainerID = "iCloud.com.github.kautenja.EUSP"

...
```

## Deployment

This application is sample code not intended for production use. It was designed
as a tool to help resolve bugs.

## Built With

* [SyncKit][] - Syncs the core data store with the users CloudKit container

[SyncKit]: https://github.com/mentrena/SyncKit

## License

Do whatever you like with anything in this repository. I do require that you
please **_remove_** my name from anything that you might alter.
