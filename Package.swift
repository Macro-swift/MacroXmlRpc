// swift-tools-version:5.2

import PackageDescription

let package = Package(
  
  name: "MacroXmlRpc",

  products: [
    .library(name: "MacroXmlRpc", targets: [ "MacroXmlRpc" ])
  ],
  
  dependencies: [
    .package(url: "https://github.com/Macro-swift/Macro.git",
             from: "0.8.11"),
    .package(url: "https://github.com/Macro-swift/MacroExpress.git",
             from: "0.8.8"),
    .package(url: "https://github.com/AlwaysRightInstitute/SwiftXmlRpc.git",
             from: "0.8.6")
  ],
  
  targets: [
    .target(name: "MacroXmlRpc", dependencies: [ 
      "Macro", "MacroExpress", 
      .product(name: "XmlRpc", package: "SwiftXmlRpc") 
    ])
  ]
)
