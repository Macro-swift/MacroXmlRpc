//
//  BodyParser.swift
//  MacroXmlRpc
//
//  Created by Helge Hess.
//  Copyright © 2020 ZeeZide GmbH. All rights reserved.
//

import MacroExpress
import enum XmlRpc.XmlRpc

public extension bodyParser {
  
  enum XmlRpcBodyParserBody {
    case invalid
    case call    (XmlRpc.Call)
    case response(XmlRpc.Response)
  }

  /**
   * If available, parse an XML-RPC method call into the `request.xmlRpcBody`
   * extra slot.
   *
   * Usage:
   *
   *     app.route("/RPC2")
   *        .use(bodyParser.xmlRpcCall())
   *        .post("/RPC2") { req, res, next in
   *          guard let call = req.xmlRpcCall else { return next() }
   *          console.log("received call:", call)
   *        }
   *
   * Note: Do not unnecessary call this middleware, i.e. maybe not at the top
   *       level, but rather as part of an actual XML-RPC route.
   *
   * This plays well w/ other body parsers. If no other parser was active,
   * it will fill `request.body` as `.text`.
   */
  static func xmlRpcCall() -> Middleware {
    return { req, res, next in
      if req[XmlRpcBodyKey.self] != nil { return next() } // parsed already
      
      func registerCallInLogger() {
        guard let call = req.xmlRpcCall else { return }
        // If we parsed an XML-RPC call, add its method name to the logging
        // meta data. It is important contextual information.
        req.log[metadataKey: "xmlrpc"] = .string(call.methodName)
      }
      
      // This deals w/ other bodyParsers being active. If we already have
      // content (e.g. from bodyParser.text or .raw) we reuse that.
      switch req.body {
      
        case .notParsed:
          guard typeIs(req, [ "text/xml" ]) != nil else { return next() }
          
          // Collect request content using the `concat` stream.
          return concatError(request: req, next: next) { bytes in
            do {
              let string     = try bytes.toString()
              req.body       = .text(string)
              req.xmlRpcBody = XmlRpc.parseCall(string).flatMap { .call($0) }
                           ?? .invalid
              registerCallInLogger()
              return nil
            }
            catch {
              req.body = .error(BodyParserError.couldNotDecodeString(error))
              req.xmlRpcBody = .invalid
              return error
            }
          }
        
        case .noBody, .error:
          req.xmlRpcBody = .invalid
          return next()
          
        case .urlEncoded, .json: // TODO: we could try to map those!
          req.xmlRpcBody = .invalid
          return next()
          
        case .raw(let bytes):
          // TBD: check for text/xml?
          do {
            let string     = try bytes.toString()
            req.body       = .text(string)
            req.xmlRpcBody = XmlRpc.parseCall(string).flatMap { .call($0) }
                         ?? .invalid
            registerCallInLogger()
          }
          catch {
            // In this case, this doesn't have to be an error. Could be some
            // other raw data.
            req.xmlRpcBody = .invalid
          }
          return next()

        case .text(let string):
          req.xmlRpcBody = XmlRpc.parseCall(string).flatMap { .call($0) }
                       ?? .invalid
          registerCallInLogger()
          return next()
      }
    }
  }
}

internal enum XmlRpcBodyKey: EnvironmentKey {
  static let defaultValue : bodyParser.XmlRpcBodyParserBody? = nil
  static let loggingKey   = "xmlrpc.body"
}

public extension IncomingMessage {
  
  /**
   * Returns the XML-RPC body parsed by e.g. `bodyParser.xmlRpcCall`. It is
   * only filled when the middleware executed, otherwise it returns `.invalid`.
   */
  var xmlRpcBody: bodyParser.XmlRpcBodyParserBody {
    set { environment[XmlRpcBodyKey.self] = newValue }
    get { return environment[XmlRpcBodyKey.self] ?? .invalid }
  }

  /**
   * Returns the XML-RPC body parsed by e.g. `bodyParser.xmlRpcCall`. It is
   * only filled when the middleware executed and the content was a proper body,
   * otherwise it returns `nil`.
   */
  @inlinable
  var xmlRpcCall: XmlRpc.Call? {
    guard case .call(let call) = xmlRpcBody else { return nil }
    return call
  }
}


// MARK: - Helper

@usableFromInline
func concatError(request : IncomingMessage,
                 next    : @escaping Next,
                 handler : @escaping ( Buffer ) -> Swift.Error?)
{
  var didCallNext = false
  
  request | concat { bytes in
    guard !didCallNext else { return }
    if let error = handler(bytes) {
      next(error)
    }
    else {
      next()
    }
  }
  .onceError { error in
    guard !didCallNext else { return }
    didCallNext = true
    next(error)
  }
}
