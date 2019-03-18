import Foundation
import HeliumLogger
import Kitura
import KituraFirefoxDetector
import LoggerAPI
import SwiftKuery
import SwiftKuerySQLite

// Using NSString below is gross, but it lets us use the very handy
// expandingTildeInPath property. Unfortunately no equivalent exists in the
// Swift standard library or elsewhere in Foundation.
// Don't forget to change this path to where you copied the file on your system!
let path = NSString(string: "~/repos/KituraDemo/Chinook_Sqlite.sqlite").expandingTildeInPath

let cxn = SQLiteConnection(filename: String(path))

cxn.connect() { error in
    if error == nil {
        print("Success opening database.")
    }
    else if let error = error {
        print("Error opening database: \(error.description)")
    }
}

// custom logging
let helium = HeliumLogger(.verbose)
Log.logger = helium

//// no custom logging
//HeliumLogger.use()

let router = Router()
let detector = FirefoxDetector()

// declare middleware for path
router.get("/ffcheck", middleware: detector)

// add handler
router.get("/ffcheck") { (request, response, next) in
    guard let ffStatus = request.userInfo["usingFirefox"] as? Bool else {
        response.send("Oops! Our middleware didn't run.")
        next()
        return
    }

    if ffStatus {
        response.send("Congrats! You're a FireFox user!")
    } else {
        response.send("Hey! You need to use FireFox to get the cool status.")
    }
    next()
}

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

// add middleware to route for ALL HTTP requests
// allowPartialMatch will block middleware from firing on subpaths
router.all("/admin", allowPartialMatch: false, middleware: detector)
router.get("/admin") { (request, response, next) in
    response.status(.forbidden)
    response.send("Hey, you don't have permission to do that!")
    next()
}

router.get("/admin/subpath") { (request, response, next) in
    guard let ffStatus = request.userInfo["usingFirefox"] as? Bool else {
        response.send("Oops! Our middleware didn't run...")
        next()
        return
    }

    response.send("The middleware ran.")
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
//router.get("/post/:postId") { (request, response, next) in
//    guard let postId = request.parameters["postId"], let postIdAsInt = UInt(postId) else {
//        response.status(.notFound)
//        response.send("The post ID provided is not a number.\n")
//        return
//    }
//    response.send("Now showing post #\(postIdAsInt)\n")
//    // load & show post according to param
//    next()
//}

// using regex to define path param instead
// ^ and $ regex tokens are implicitly added by Kitura
router.get("/post/:postId(\\d+)") { (request, response, next) in
    let postId = request.parameters["postId"]!
    response.send("Now showing post #\(postId)\n")
    // load & show post according to param
    next()
}

router.get("/:author/post/:postId") { (request, response, next) in
    let author = request.parameters["author"]!
    let postId = request.parameters["postId"]!
    response.send("Now showing post #\(postId) by \(author)\n")
    // load & show post according to author & param
    next()
}

router.get("/albums") { (request, response, next) in
    let albumSchema = Album()
    let titleQuery = Select(albumSchema.Title, from: albumSchema)
        .order(by: .ASC(albumSchema.Title))

    // check the SQL query built by Kuery API
    print(try! titleQuery.build(queryBuilder: cxn.queryBuilder))

    cxn.execute(query: titleQuery) { queryResult in
        if let rows = queryResult.asRows {
            for row in rows {
                let title = row["Title"] as! String
                response.send(title + "\n")
            }
        }
    }
    next()
}

router.get("/albums/:letter") { (request, response, next) in
    guard let letter = request.parameters["letter"] else {
        response.status(.notFound)
        return
    }

    let albumSchema = Album()

    // sanitize param values
    let titleQuery = Select(albumSchema.Title, from: albumSchema)
        .where(albumSchema.Title.like(Parameter("searchLetter")))
        .order(by: .ASC(albumSchema.Title))

    let parameters: [String: Any?] = ["searchLetter": letter + "%"]

    cxn.execute(query: titleQuery, parameters: parameters) { queryResult in
        if let rows = queryResult.asRows {
            for row in rows {
                let title = row["Title"] as! String
                response.send(title + "\n")
            }
        }
    }

    next()
}

// start server on provided port using router instance
Kitura.addHTTPServer(onPort: 8080, with: router)

// FastCGI app config
Kitura.addFastCGIServer(onPort: 9000, with: router)

Kitura.run()
