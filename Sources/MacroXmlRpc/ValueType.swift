//
//  ValueType.swift
//  MacroXmlRpc
//
//  Created by Helge Hess.
//  Copyright © 2020 ZeeZide GmbH. All rights reserved.
//

import protocol XmlRpc.XmlRpcValueRepresentable

public extension XmlRpc.Value {
  
  #if swift(>=5.1)
  /**
   * The various possible XML-RPC value types used in XML-RPC introspection.
   * Note that those are flat, i.e. arrays and dictionaries are not further
   * described.
   */
  @frozen
  enum ValueType: Hashable {
    case null
    case string, bool, int, double, dateTime, data
    case array, dictionary
  }
  #else
  enum ValueType: Hashable {
    case null
    case string, bool, int, double, dateTime, data
    case array, dictionary
  }
  #endif
  
  @inlinable
  var xmlRpcValueType: ValueType {
    switch self {
      case .null       : return .null
      case .string     : return .string
      case .bool       : return .bool
      case .int        : return .int
      case .double     : return .double
      case .dateTime   : return .dateTime
      case .data       : return .data
      case .array      : return .array
      case .dictionary : return .dictionary
    }
  }
}

extension XmlRpc.Value.ValueType: XmlRpcValueRepresentable {

  public init?(xmlRpcValue: XmlRpc.Value) {
    switch xmlRpcValue.stringValue {
      case "i4", "int"        : self = .int
      case "boolean"          : self = .bool
      case "string"           : self = .string
      case "double"           : self = .double
      case "base64"           : self = .data
      case "dateTime.iso8601" : self = .dateTime
      case "struct"           : self = .dictionary
      case "array"            : self = .array
      case "null"             : self = .null
      default: return nil
    }
  }
  public var xmlRpcValue : XmlRpc.Value {
    switch self {
      case .null       : return "null"
      case .string     : return "string"
      case .bool       : return "boolean"
      case .int        : return "int"
      case .double     : return "double"
      case .dateTime   : return "dateTime.iso8601"
      case .data       : return "base64"
      case .array      : return "array"
      case .dictionary : return "struct"
    }
  }
}
