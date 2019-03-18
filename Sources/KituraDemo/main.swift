import Kitura
import HeliumLogger
import LoggerAPI

// custom logging
let helium = HeliumLogger(.verbose)
Log.logger = helium

//// no custom logging
//HeliumLogger.use()

let router = Router()

router.all("/request-info") { (request, response, next) in
    response.send("You are accessing \(request.hostname) on port \(request.port).\n")

    // request.method contains the req method as a RouterMethod enum case
    // but we can use rawValue prop to get the method as a printable string
    response.send("The request method was \(request.method.rawValue).\n")

    // request headesr are in the headers prop, which itself is an instance of a
    // Headers struct. The important thing is that it's subscriptable so it can
    // be treated like a simple [String: String] dict
    if let agent = request.headers["User-Agent"] {
        response.send("Your user-agent is \(agent).\n")
    }

    next()
}

router.get("/") { (request, response, next) in
    defer {
        next()
    }
    Log.info("Custom log - about to send a Hello World response to the user.")
    Log.verbose("Things are going just fine.")

    response.send("Hello world!\n")
}

router.get("/") { (request, response, next) in
    Log.warning("Something looks fishy!")
    Log.error("OH NO!")

    response.send("And hello again!\n")

    next()
}

router.get("/hello-you") { (request, response, next) in
    if let name = request.queryParameters["name"] {
        response.send("Hello, \(name)!\n")
    } else {
        response.send("Hello, whatever your name is!\n")
    }

    next()
}

router.get("/admin") { (request, response, next) in
    response.status(.forbidden)
    response.send("Hey, you don't have permission to do that!")
    next()
}

router.get("/custom-headers") { (request, response, next) in
    response.headers["X-Generator"] = "Kitura!"
    response.headers.setType("text/plain", charset: "utf-8")
    response.send("Hello!")
    next()
}

router.get("/redirect") { (request, response, next) in
    // redirect client to home page
    try? response.redirect("/", status: .movedPermanently)
    next()
}

router.get("/stock-data") { (request, response, next) in
    // completely made up stock value data
    let stockData = ["AAPL": 120.44, "MSFT": 88.48, "IBM": 74.11, "DVMT": 227.44]
    response.send(json: stockData)
    next()
}

router.get("/calc") { (request, response, next) in
    guard let paramA = request.queryParameters["a"], let paramB = request.queryParameters["b"] else {
        response.status(.badRequest)
        response.send("param a or b is missing\n")
        Log.error("param missing from the request")
        return
    }

    guard let valueA = Float(paramA), let valueB = Float(paramB) else {
        response.status(.badRequest)
        response.send("param a or b could not be converted to a Float\n")
        Log.error("Parameter uncastable")
        return
    }

    let sum = valueA + valueB
    Log.info("Successfully added a+b: \(sum)")
    response.send("The calculation resulted in \(sum)\n")
    next()
}

router.get("/get-only") { (request, response, next) in
    response.send("GET Success!\n")
    next()
}

router.lock("/lock-only") { (request, response, next) in
    response.send("LOCK success!\n")
    next()
}

// requests to /some-path w/ methods other than GET or POST will still
// automatically result in a "404 Not Found" response
router.get("/some-path") { (request, response, next) in
    // do something
    next()
}

router.post("/some-path") { (request, response, next) in
    // do something else
    next()
}

// ## PATH PARAMS ##
router.get("/post/1") { (request, response, next) in
    // load & show post 1
    next()
}

router.get("/post/2") { (request, response, next) in
    // load & show post 2
    next()
}

// start server on provided port using router instance
Kitura.addHTTPServer(onPort: 8080, with: router)

// FastCGI app config
Kitura.addFastCGIServer(onPort: 9000, with: router)

Kitura.run()
