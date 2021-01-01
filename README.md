<h2>Macro XML-RPC
  <img src="http://zeezide.com/img/macro/MacroExpressIcon128.png"
       align="right" width="100" height="100" />
</h2>

XML-RPC support for
[MacroExpress](https://github.com/Macro-swift/MacroExpress).

This is covered in the
[Writing an Swift XML-RPC Server](http://www.alwaysrightinstitute.com/macro-xmlrpc/)
blog entry.


## What does it look like?

```swift
#!/usr/bin/swift sh
import MacroExpress // @Macro-swift
import MacroXmlRpc  // @Macro-swift

let app = express()

app.route("/RPC2")
   .use(bodyParser.xmlRpcCall())
   .rpc("ping") { _ in "pong" }
   .rpc("add")  { ( a: Int, b: Int ) in a + b }
   .use(xmlrpc.introspection())

app.listen(1337)
```

## Environment Variables

- `macro.core.numthreads`
- `macro.core.iothreads`
- `macro.core.retain.debug`
- `macro.concat.maxsize`
- `macro.streams.debug.rc`
- `macro.router.debug`
- `macro.router.matcher.debug`
- `macro.router.walker.debug`

### Links

- [Writing an Swift XML-RPC Server](http://www.alwaysrightinstitute.com/macro-xmlrpc/)
- [MacroExpress](https://github.com/Macro-swift/MacroExpress).
- [Macro](https://github.com/Macro-swift/Macro/)
- [XML-RPC Homepage](http://xmlrpc.com)
  - [XML-RPC Spec](http://xmlrpc.com/spec.md)
  - [XML-RPC for Newbies](http://scripting.com/davenet/1998/07/14/xmlRpcForNewbies.html)
  - [Original site](http://1998.xmlrpc.com)
  - [XML-RPC HowTo](https://tldp.org/HOWTO/XML-RPC-HOWTO/index.html) by Eric Kidd
- [Python](https://docs.python.org/3/library/xmlrpc.client.html#module-xmlrpc.client) Client

### Who

**Macro XML-RPC** is brought to you by
the
[Always Right Institute](http://www.alwaysrightinstitute.com)
and
[ZeeZide](http://zeezide.de).
We like 
[feedback](https://twitter.com/ar_institute), 
GitHub stars, 
cool [contract work](http://zeezide.com/en/services/services.html),
presumably any form of praise you can think of.

There is a `#microexpress` channel on the 
[Noze.io Slack](http://slack.noze.io/). Feel free to join!
