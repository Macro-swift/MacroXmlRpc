//
//  TypedRoutes.swift
//  MacroXmlRpc
//
//  Created by Helge Hess.
//  Copyright © 2020 ZeeZide GmbH. All rights reserved.
//

import MacroExpress
import XmlRpc

public protocol IntrospectibleXmlRpcValue: XmlRpcValueRepresentable {
  static var xmlRpcValueType : XmlRpc.Value.ValueType { get }
}

public extension RouteKeeper {
  
  // TODO: To finish up introspection, this needs to be decoupled from
  //       `synchronousCall`.
  
  @inlinable
  @discardableResult
  func rpc<A1, R>(_ methodName: String, execute: @escaping ( A1 ) throws -> R)
       -> Self
       where A1 : IntrospectibleXmlRpcValue,
             R  : IntrospectibleXmlRpcValue
  {
    return post(xmlrpc.synchronousCall(methodName) { call in
      guard call.parameters.count == 1,
            let a1 = A1(xmlRpcValue: call.parameters[0])
       else { throw XmlRpc.Fault(code: 400, reason: "Invalid parameters") }
      return try execute(a1)
    })
  }
          
  @inlinable
  @discardableResult
  func rpc<A1, A2, R>(_ methodName: String,
                      execute: @escaping ( A1, A2 ) throws -> R)
       -> Self
       where A1 : IntrospectibleXmlRpcValue,
             A2 : IntrospectibleXmlRpcValue,
             R  : IntrospectibleXmlRpcValue
  {
    return post(xmlrpc.synchronousCall(methodName) { call in
      guard call.parameters.count == 2,
            let a1 = A1(xmlRpcValue: call.parameters[0]),
            let a2 = A2(xmlRpcValue: call.parameters[1])
       else { throw XmlRpc.Fault(code: 400, reason: "Invalid parameters") }
      return try execute(a1, a2)
    })
  }
}


// MARK: - IntrospectibleXmlRpcValue types

extension String: IntrospectibleXmlRpcValue {
  @inlinable
  public static var xmlRpcValueType : XmlRpc.Value.ValueType { return .string }
}

extension Int: IntrospectibleXmlRpcValue {
  @inlinable
  public static var xmlRpcValueType : XmlRpc.Value.ValueType { return .int }
}

extension Double: IntrospectibleXmlRpcValue {
  @inlinable
  public static var xmlRpcValueType : XmlRpc.Value.ValueType { return .double }
}

extension Bool: IntrospectibleXmlRpcValue {
  @inlinable
  public static var xmlRpcValueType : XmlRpc.Value.ValueType { return .bool }
}

extension Collection where Element : IntrospectibleXmlRpcValue {
  @inlinable
  public static var xmlRpcValueType : XmlRpc.Value.ValueType { return .array }
}

extension Array   : IntrospectibleXmlRpcValue
    where Element : IntrospectibleXmlRpcValue
{
}
extension Set     : IntrospectibleXmlRpcValue
    where Element : IntrospectibleXmlRpcValue
{
}

extension Dictionary : IntrospectibleXmlRpcValue
    where Key       == String,
          Value      : IntrospectibleXmlRpcValue
{
  @inlinable
  public static var xmlRpcValueType : XmlRpc.Value.ValueType {
    return .dictionary
  }
}

#if canImport(Foundation)
  import struct Foundation.URL
  import struct Foundation.DateComponents
  
  extension DateComponents: IntrospectibleXmlRpcValue {
    @inlinable
    public static var xmlRpcValueType : XmlRpc.Value.ValueType {
      return .dateTime
    }
  }

  extension URL: IntrospectibleXmlRpcValue {
    @inlinable
    public static var xmlRpcValueType : XmlRpc.Value.ValueType {
      return .string
    }
  }
#endif // canImport(Foundation)
