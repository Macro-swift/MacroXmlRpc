//
//  RouteKeeper.swift
//  MacroXmlRpc
//
//  Created by Helge Hess.
//  Copyright © 2020 ZeeZide GmbH. All rights reserved.
//

import MacroExpress
import XmlRpc

extension RouteKeeper {
  
  @discardableResult
  func rpc(_ methodName: String? = nil,
           execute: @escaping
             ( XmlRpc.Call ) throws -> XmlRpcValueRepresentable)
       -> Self
  {
    post { req, res, next in
      if let methodName = methodName {
        let methods = (req.extra["rpc.methods"] as? [ String ]) ?? []
        req.extra["rpc.methods"] = methods + [ methodName ]
      }
      
      guard let call = XmlRpc.parseCall(req.body.text ?? "") else {
        return res.sendStatus(400)
      }
      
      if let methodName = methodName, call.methodName != methodName {
        return next()
      }

      do {
        let value = try execute(call)
        res.send(XmlRpc.Response.value(value.xmlRpcValue).xmlString)
      }
      catch let error as XmlRpc.Fault {
        res.send(XmlRpc.Response.fault(error).xmlString)
      }
      catch {
        res.sendStatus(500)
      }
    }
  }

  @discardableResult
  func systemListMethods() -> Self {
    post { req, res, next in
      guard let call = XmlRpc.parseCall(req.body.text ?? ""),
            call.methodName == "system.listMethods" else {
        return next()
      }
      let methods = (req.extra["rpc.methods"] as? [ String ]) ?? []
      res.send(XmlRpc.Response(methods).xmlString)
    }
  }
}

extension RouteKeeper {
          
  @discardableResult
  func rpc<A1>(_ methodName: String,
               execute: @escaping ( A1 )
                          throws -> XmlRpcValueRepresentable)
       -> Self
       where A1: XmlRpcValueRepresentable
  {
    rpc(methodName) { call in
      guard call.parameters.count == 1,
            let a1 = A1(xmlRpcValue: call.parameters[0])
       else { throw XmlRpc.Fault(code: 400, reason: "Invalid parameters") }
      return try execute(a1)
    }
  }
          
  @discardableResult
  func rpc<A1, A2>(_ methodName: String,
                   execute: @escaping ( A1, A2 )
                              throws -> XmlRpcValueRepresentable)
       -> Self
       where A1: XmlRpcValueRepresentable,
             A2: XmlRpcValueRepresentable
  {
    rpc(methodName) { call in
      guard call.parameters.count == 2,
            let a1 = A1(xmlRpcValue: call.parameters[0]),
            let a2 = A2(xmlRpcValue: call.parameters[1])
       else { throw XmlRpc.Fault(code: 400, reason: "Invalid parameters") }
      return try execute(a1, a2)
    }
  }
}
