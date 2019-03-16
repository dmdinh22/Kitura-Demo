import Kitura

let router = Router()

router.get("/") { request, response, next in
    response.send("Hello world!\n")
    next()
}

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
