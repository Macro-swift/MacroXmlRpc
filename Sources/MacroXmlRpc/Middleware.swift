//
//  Middleware.swift
//  MacroXmlRpc
//
//  Created by Helge Hess.
//  Copyright © 2020 ZeeZide GmbH. All rights reserved.
//

import enum     XmlRpc.XmlRpc
import protocol XmlRpc.XmlRpcValueRepresentable
import MacroExpress

// TODO: Try to mirror the JS server in http://xmlrpc.com
public enum xmlrpc {}

public extension xmlrpc {
  
  /**
   * Calls an XML-RPC handler function synchronously.
   *
   * It is recommended to invoke the `bodyParser.xmlRpcCall` in a proper place,
   * though if that didn't happen, this method will do it for the user.
   */
  static func synchronousCall(_ methodName: String? = nil,
                              execute: @escaping ( XmlRpc.Call ) throws
                                                  -> XmlRpcValueRepresentable)
       -> Middleware
  {
    return { req, res, next in
      guard req.method == "POST" else { return next() }
      
      if let methodName = methodName {
        req.addKnownXmlRpcMethod(methodName)
      }
      
      /* implementation */
      
      func process() {
        guard let call = req.xmlRpcCall else {
          // TBD: Not quite sure what the best thing is.
          if typeIs(req, [ "text/xml" ]) != nil {
            req.log.error("Could not parse XML-RPC call.")
            return res.sendStatus(400)
          }
          else {
            return next()
          }
        }
        
        if let methodName = methodName, call.methodName != methodName {
          return next()
        }
        
        // It is an XML-RPC call and it matches the requested method (or all).
        do {
          let value = try execute(call)
          
          req.log.log("executed request:", call.methodName)
          return res.send(XmlRpc.Response.value(value.xmlRpcValue).xmlString)
        }
        catch let error as XmlRpc.Fault {
          req.log.error("XML-RPC call failed w/ fault:", error)
          return res.send(XmlRpc.Response.fault(error).xmlString)
        }
        catch {
          req.log.error("XML-RPC call failed w/ non-fault error:", error)
          res.statusCode = 500
          return res.send("Call to XML-RPC function failed.")
        }
      }

      /* Body parser is not active */
      if req.extra[xmlRpcRequestKey] == nil,
         typeIs(req, [ "text/xml" ]) != nil
      {
        req.log.notice("Use of XML-RPC middleware w/o a bodyParser")
        let parser = bodyParser.xmlRpcCall()
        do {
          try parser(req, res) { (args: Any...) in
            assert(req.extra[xmlRpcRequestKey] != nil) // at least .invalid!
            process()
          }
        }
        catch {
          req.log.notice("failed to parse XML-RPC: \(error)")
          return next()
        }
      }
      else { // we have a proper body already
        process()
      }
    }
  }
}
