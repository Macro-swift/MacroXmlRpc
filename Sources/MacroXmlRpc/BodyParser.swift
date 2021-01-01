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
   *     app.use(bodyParser.xmlRpcCall())
   *
   *     app.post("/RPC2") { req, res, next in
   *       guard let call = req.xmlRpcCall else { return next() }
   *       console.log("received call:", call)
   *     }
   *
   * This plays well w/ other body parsers. If no other parser was active,
   * it will fill `request.body` as `.text`.
   */
  func xmlRpcCall() -> Middleware {
    return { req, res, next in
      if req.extra[xmlRpcRequestKey] != nil { return next() } // parsed already
      
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
          return next()
      }
    }
  }

}

@usableFromInline
let xmlRpcRequestKey = "macro.xmlrpc.body-parser"

public extension IncomingMessage {
  
  /**
   * Returns the XML-RPC body parsed by e.g. `bodyParser.xmlRpcCall`. It is
   * only filled when the middleware executed, otherwise it returns `.invalid`.
   */
  @inlinable
  var xmlRpcBody: bodyParser.XmlRpcBodyParserBody {
    set { extra[xmlRpcRequestKey] = newValue }
    get {
      return (extra[xmlRpcRequestKey] as? bodyParser.XmlRpcBodyParserBody)
          ?? .invalid
    }
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

private func concatError(request : IncomingMessage,
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
