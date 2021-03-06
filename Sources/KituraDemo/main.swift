import Foundation
import HeliumLogger
import Kitura
import KituraFirefoxDetector
import KituraStencil
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
router.setDefault(templateEngine: StencilTemplateEngine())

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
    let albumSchema = AlbumTable()
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

//router.get("/albums/:letter([a-z])") { (request, response, next) in
//    guard let letter = request.parameters["letter"] else {
//        response.status(.notFound)
//        return
//    }
//
//    let albumSchema = AlbumTable()
//
//    // sanitize param values
//    let titleQuery = Select(albumSchema.Title, from: albumSchema)
//        .where(albumSchema.Title.like(Parameter("searchLetter")))
//        .order(by: .ASC(albumSchema.Title))
//
//    let parameters: [String: Any?] = ["searchLetter": letter + "%"]
//
//    cxn.execute(query: titleQuery, parameters: parameters) { queryResult in
//        if let rows = queryResult.asRows {
//            for row in rows {
//                let title = row["Title"] as! String
//                response.send(title + "\n")
//            }
//        }
//    }
//
//    next()
//}
//
//router.get("/songs/:letter([a-z])") { (request, response, next) in
//    let letter = request.parameters["letter"]!
//    let albumSchema = AlbumTable()
//    let trackSchema = TrackTable()
//
//    let query = Select(trackSchema.Name, trackSchema.Composer, albumSchema.Title, from: trackSchema)
//        .join(albumSchema).on(trackSchema.AlbumId == albumSchema.AlbumId)
//        .where(trackSchema.Name.like(letter + "%"))
//        .order(by: .ASC(trackSchema.Name))
//
//    cxn.execute(query: query) { queryResult in
//        if let rows = queryResult.asRows {
//            for row in rows {
//                let trackName = row["Name"] as! String
//                let composer = row["Composer"] as! String? ?? "composer unknown"
//                let albumName = row["Title"] as! String
//                response.send("\(trackName) by \(composer) from \(albumName)\n")
//            }
//        }
//    }
//
//    next()
//}

router.get("songs/:letter") { request, response, next in
    let letter = request.parameters["letter"]!

    let albumSchema = AlbumTable()
    let trackSchema = TrackTable()

    let query = Select(trackSchema.Name, trackSchema.Composer, albumSchema.Title, from: trackSchema)
        .join(albumSchema).on(trackSchema.AlbumId == albumSchema.AlbumId)
        .where(trackSchema.Name.like(letter + "%"))
        .order(by: .ASC(trackSchema.Name))

    cxn.execute(query: query) { queryResult in
        if let rows = queryResult.asRows {
            var tracks: [Track] = []
            for row in rows {
                do {
                    let track = try! Track(fromRow: row)
                    tracks.append(track)
                }
                catch {
                    Log.error("Failed to initialize a track from a row.")
                }
            }

            response.headers["Vary"] = "Accept"
            let output: String
            switch request.accepts(types: ["text/json", "text/xml", "text/html"]) {
            case "text/json"?:
                response.headers["Content-Type"] = "text/json"
                let encoder: JSONEncoder = JSONEncoder()
                do {
                    let jsonData: Data = try encoder.encode(tracks)
                    output = String(data: jsonData, encoding: .utf8)!
                    response.send(output)
                }
                catch {
                    response.status(.internalServerError)
                    Log.error("Failed to JSON encode track list.")
                }
                break
            case "text/xml"?:
                response.headers["Content-Type"] = "text/xml"
                let tracksElement: XMLElement = XMLElement(name: "tracks")
                for track in tracks {
                    tracksElement.addChild(track.asXmlElement())
                }
                let tracksDoc: XMLDocument = XMLDocument(rootElement: tracksElement)
                let xmlData: Data = tracksDoc.xmlData
                output = String(data: xmlData, encoding: .utf8)!
                response.send(output)
                break
            case "text/html"?:
                response.headers["Content-Type"] = "text/html; charset=utf-8"
                var sanitized: [[String: String?]] = []
                for track in tracks {
                    sanitized.append([
                        "name": track.name.webSanitize(),
                        "composer": track.composer?.webSanitize(),
                        "album": track.albumTitle.webSanitize()
                    ])
                }
                let context = ["letter": letter as Any, "tracks": sanitized as Any]
                try! response.render("songs", context: context)
                break
            default:
                response.status(.notAcceptable)
                next()
                return
            }
        }

        else if let queryError = queryResult.asError {
            let builtQuery = try! query.build(queryBuilder: cxn.queryBuilder)
            response.status(.internalServerError)
            response.send("Database error: \(queryError.localizedDescription) - Query: \(builtQuery)")
        }
    }
    next()
}

// hello.stencil route
router.get("/hello/:name?") { request, response, next in
    response.headers["Content-Type"] = "text/html; charset=utf-8"
    let name = request.parameters["name"]
    let context: [String: Any] = ["name": name?.webSanitize() as Any]
    try response.render("hello", context: context)
    next()
}

// goodbye.stencil route
router.get("/goodbye/:name?") { request, response, next in
    response.headers["Content-Type"] = "text/html; charset=utf-8"
    let name = request.parameters["name"]
    let context: [String: Any] = ["name": name?.webSanitize() as Any]
    try response.render("goodbye", context: context)
    next()
}

// start server on provided port using router instance
Kitura.addHTTPServer(onPort: 8080, with: router)

// FastCGI app config
Kitura.addFastCGIServer(onPort: 9000, with: router)

Kitura.run()
