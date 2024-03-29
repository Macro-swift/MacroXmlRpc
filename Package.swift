// swift-tools-version:5.5

import PackageDescription

let package = Package(
  
  name: "MacroXmlRpc",

  products: [
    .library(name: "MacroXmlRpc", targets: [ "MacroXmlRpc" ])
  ],
  
  dependencies: [
    .package(url: "https://github.com/Macro-swift/Macro.git",
             from: "1.0.0"),
    .package(url: "https://github.com/Macro-swift/MacroExpress.git",
             from: "1.0.0"),
    .package(url: "https://github.com/helje5/SwiftXmlRpc.git",
             from: "0.8.6")
  ],
  
  targets: [
    .target(name: "MacroXmlRpc", dependencies: [ 
      "Macro", "MacroExpress", 
      .product(name: "XmlRpc", package: "SwiftXmlRpc") 
    ])
  ]
)
