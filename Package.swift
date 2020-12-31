// swift-tools-version:5.0

import PackageDescription

let package = Package(
  
  name: "MacroXmlRpc",

  products: [
    .library(name: "MacroXmlRpc", targets: [ "MacroXmlRpc" ])
  ],
  
  dependencies: [
    .package(url: "https://github.com/Macro-swift/MacroExpress.git",
             from: "0.5.7"),
    .package(url: "https://github.com/AlwaysRightInstitute/SwiftXmlRpc.git",
             from: "0.8.5")
  ],
  
  targets: [
    .target(name: "MacroXmlRpc", dependencies: [ "MacroExpress", "XmlRpc" ])
  ]
)
