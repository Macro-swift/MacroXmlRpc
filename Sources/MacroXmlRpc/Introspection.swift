//
//  Introspection.swift
//  MacroXmlRpc
//
//  Created by Helge Hess.
//  Copyright © 2020 ZeeZide GmbH. All rights reserved.
//

public extension RouteKeeper {

  @inlinable
  @discardableResult
  func systemListMethods() -> Self {
    post { req, res, next in
      guard let call = XmlRpc.parseCall(req.body.text ?? ""),
            call.methodName == "system.listMethods" else {
        return next()
      }
      res.send(XmlRpc.Response(req.knownXmlRpcMethodNames).xmlString)
    }
  }
}

extension IncomingMessage {
  
  @usableFromInline
  var knownXmlRpcMethodNames : [ String ] {
    return (extra["rpc.methods"] as? [ String ]) ?? []
  }
  
  @usableFromInline
  func addKnownXmlRpcMethod(_ methodName: String) {
    if var methods = extra.removeValue(forKey: "rpc.methods") as? [ String ] {
      methods.append(methodName)
      extra["rpc.methods"] = methods
    }
    else {
      extra["rpc.methods"] = [ methodName ]
    }
  }
}
