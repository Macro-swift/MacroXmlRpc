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
    return post(xmlrpc.synchronousCall(methodName, execute: execute))
  }
}
