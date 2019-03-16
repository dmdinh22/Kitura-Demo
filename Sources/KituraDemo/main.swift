import Kitura

let router = Router()

router.get("/") { (request, response, next) in
    defer {
        next()
    }
    response.send("Hello world!\n")
}

router.get("/") { request, response, next in
    response.send("And hello again!\n")
    next()
}

// start server on provided port using router instance
Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
