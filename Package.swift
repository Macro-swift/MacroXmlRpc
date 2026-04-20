// swift-tools-version:6.0

import PackageDescription

let package = Package(

  name: "MacroXmlRpc",

  platforms: [ .macOS(.v15), .iOS(.v18), .visionOS(.v2) ],

  products: [
    .library(name: "MacroXmlRpc", targets: [ "MacroXmlRpc" ])
  ],
  
  dependencies: [
    .package(url: "https://github.com/Macro-swift/Macro.git",
             from: "1.0.46"),
    .package(url: "https://github.com/Macro-swift/MacroExpress.git",
             from: "1.0.46"),
    .package(url: "https://github.com/helje5/SwiftXmlRpc.git",
             from: "1.0.0")
  ],
  
  targets: [
    .target(name: "MacroXmlRpc", dependencies: [ 
      "Macro", "MacroExpress", 
      .product(name: "XmlRpc", package: "SwiftXmlRpc") 
    ])
  ]
)
