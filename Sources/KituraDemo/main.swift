import Kitura
import HeliumLogger
import LoggerAPI

// custom logging
let helium = HeliumLogger(.verbose)
Log.logger = helium

//// no custom logging
//HeliumLogger.use()

let router = Router()

router.get("/") { (request, response, next) in
    defer {
        next()
    }
    Log.info("Custom log - about to send a Hello World response to the user.")
    Log.verbose("Things are going just fine.")

    response.send("Hello world!\n")
}

router.get("/") { request, response, next in
    Log.warning("Something looks fishy!")
    Log.error("OH NO!")

    response.send("And hello again!\n")

    next()
}

// start server on provided port using router instance
Kitura.addHTTPServer(onPort: 8080, with: router)

// FastCGI app config
Kitura.addFastCGIServer(onPort: 9000, with: router)

Kitura.run()
