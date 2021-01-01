//
//  RouteKeeper.swift
//  MacroXmlRpc
//
//  Created by Helge Hess.
//  Copyright © 2020 ZeeZide GmbH. All rights reserved.
//

import MacroExpress
import XmlRpc

public extension RouteKeeper {
  
  @inlinable
  @discardableResult
  func rpc(_ methodName: String? = nil,
           execute: @escaping
             ( XmlRpc.Call ) throws -> XmlRpcValueRepresentable)
       -> Self
  {
    post(xmlrpc.synchronousCall(methodName, execute: execute))
  }
}

public extension RouteKeeper {
          
  @inlinable
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
          
  @inlinable
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
