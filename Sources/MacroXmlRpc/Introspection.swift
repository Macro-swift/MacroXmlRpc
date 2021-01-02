//
//  Introspection.swift
//  MacroXmlRpc
//
//  Created by Helge Hess.
//  Copyright © 2020 ZeeZide GmbH. All rights reserved.
//

import protocol XmlRpc.XmlRpcValueRepresentable

public extension xmlrpc {
  
  /**
   * Provide method reflection information, as described in:
   *
   *     http://xmlrpc-c.sourceforge.net/introspection.html
   *
   * This middleware needs to be hooked up to the END, after all XML-RPC
   * functions have been registered in a route.
   *
   * Example:
   * 
   *     app.route("/RPC2")
   *        .use(bodyParser.xmlRpcCall())
   *        .rpc("ping") { _ in "pong" }
   *        .rpc("add")  { ( a: Int, b: Int ) in a + b }
   *        .use(xmlrpc.introspection())
   *
   * Specifically hosts implementations for those XML-RPC methods:
   * - system.listMethods
   * - system.methodExists
   * - system.methodSignature
   * - system.methodHelp
   * - getCapabilities
   *
   * Note: Careful w/ security implications!
   */
  static func introspection() -> Middleware {
    return { req, res, next in
      guard let call = req.xmlRpcCall else { return next() }
      
      var missingNameResponse : XmlRpc.Response {
        req.log.error("XML-RPC introspection call was missing a name!")
        return XmlRpc.Response.fault(
                 .init(code: 400, reason: "Missing method name parameter!"))
      }
      func unknownMethodResponse(_ name: String) -> XmlRpc.Response {
        req.log.warn(
          "XML-RPC introspection was asking for an unknown name \(name)!")
        return XmlRpc.Response.fault(
                 .init(code: 404, reason: "Unknown method '\(name)'."))
      }

      switch call.methodName {
      
        case "system.listMethods":
          xmlRpcIntrospectionMethods.forEach { req.addKnownXmlRpcMethod($0) }
          return res.send(XmlRpc.Response(req.knownXmlRpcMethodNames).xmlString)
          
        case "system.methodSignature":
          guard let methodName = call.parameters.first?.stringValue else {
            return res.send(missingNameResponse.xmlString)
          }
          
          switch methodName {
            case "system.listMethods", "getCapabilities":
              req.addSignature([], for: methodName)
            case "system.methodSignature", "system.methodHelp",
                 "system.methodExist":
              req.addSignature([ .string ], for: methodName)
            default: break
          }
          
          if let signatures = req.signatures[methodName] {
            return res.send(XmlRpc.Response(signatures).xmlString)
          }
          else if req.doesMethodExist(methodName) {
            // Forbidden by standard, if we say we do introspection, we should.
            // :-)
            return res.sendStatus(500)
          }
          else {
            return res.send(unknownMethodResponse(methodName).xmlString)
          }
          
        case "system.methodHelp":
          guard let methodName = call.parameters.first?.stringValue else {
            return res.send(missingNameResponse.xmlString)
          }
          
          if let help = req.helps[methodName] {
            return res.send(XmlRpc.Response(help).xmlString)
          }
          else if let signatures = req.signatures[methodName],
                  !signatures.isEmpty
          {
            let help = generateHelpForMethod(methodName, signatures: signatures)
            return res.send(XmlRpc.Response(help).xmlString)
          }
          else if req.doesMethodExist(methodName) {
            let help = "The method '\(methodName)' exists, "
                     + "but no documentation is available."
            return res.send(XmlRpc.Response(help).xmlString)
          }
          else {
            return res.send(unknownMethodResponse(methodName).xmlString)
          }

        case "system.methodExist":
          guard let methodName = call.parameters.first?.stringValue else {
            return res.send(missingNameResponse.xmlString)
          }
          return res.send(XmlRpc.Response(
                            req.doesMethodExist(methodName)).xmlString)
        
        case "getCapabilities":
          // http://xmlrpc-c.sourceforge.net/doc/libxmlrpc_server.html#system.getCapabilities
          // TBD: we could collect more capabilities
          return res.send(XmlRpc.Response([
            "introspection": [
              "specURL"     :
                "http://xmlrpc-c.sourceforge.net/xmlrpc-c/introspection.html",
              "specVersion" : 1
            ]
          ]).xmlString)
        
        default:
          req.log.warn("unprocessed XML-RPC request after introspection:",
                       call.methodName)
          next()
      }
    }
  }
}

@usableFromInline
let xmlRpcIntrospectionMethods : Set<String> = [
  "system.listMethods", "system.methodSignature", "system.methodHelp",
  "system.methodExist", "getCapabilities"
]

fileprivate extension IncomingMessage {
  
  func doesMethodExist(_ methodName: String) -> Bool {
    let exists = xmlRpcIntrospectionMethods .contains(methodName)
              || self.knownXmlRpcMethodNames.contains(methodName)
    return exists
  }
}

private enum MethodNames: EnvironmentKey {
  static let defaultValue : Set<String> = []
  static let loggingKey   = "xmlrpc.names"
}
private enum MethodHelps: EnvironmentKey {
  static let defaultValue : [ String : String ] = [:]
  static let loggingKey   = "xmlrpc.helps"
}
private enum MethodSignatures: EnvironmentKey {
  static let defaultValue : [ String : [ [ XmlRpc.Value.ValueType ] ] ] = [:]
  static let loggingKey   = "xmlrpc.signatues"
}

extension IncomingMessage {
  
  fileprivate var knownXmlRpcMethodNames : Set<String> {
    return environment[MethodNames.self]
  }
  
  @usableFromInline
  func addKnownXmlRpcMethod(_ methodName: String) {
    environment[MethodNames.self].insert(methodName)
  }
  
  @usableFromInline
  func addHelp(_ help: String, for methodName: String) {
    environment[MethodHelps.self][methodName] = help
  }
  
  @usableFromInline
  func addSignature(_ signature: [ XmlRpc.Value.ValueType ],
                    for method: String)
  {
    var values = environment[MethodSignatures.self]
    values[method, default: []].append(signature)
    environment[MethodSignatures.self] = values
  }
  
  fileprivate var helps : [ String : String ] {
    return environment[MethodHelps.self]
  }
  fileprivate var signatures : [ String : [ [ XmlRpc.Value.ValueType ] ] ] {
    return environment[MethodSignatures.self]
  }
}

fileprivate
func generateHelpForMethod(_ methodName: String,
                           signatures: [ [ XmlRpc.Value.ValueType ] ])
     -> String
{
  if signatures.isEmpty {
    return
      "The method '\(methodName)' exists, but no documentation is available."
  }
  
  var ms =
    "The method '\(methodName)' can be called with the following signatures:"
  ms += "\n\n"
  for signature in signatures {
    ms += "    \(methodName)("
    ms += signature.map { $0.xmlRpcValue.stringValue }.joined(separator: ", ")
    ms += ")"
  }
  return ms
}
