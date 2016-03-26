/**
 * Copyright IBM Corporation 2016
 * Copyright (c) Pine Mizune 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import KituraSys
import KituraNet
import Kitura

import LoggerAPI
import HeliumLogger
import Environment

#if os(Linux)
    import Glibc
#endif

import Foundation


// All Web apps need a router to define routes
let router = Router()

// Using an implementation for a Logger
Log.logger = HeliumLogger()

router.all("/*", middleware: BodyParser())
router.all("/static/*", middleware: StaticFileServer())


router.get("/") { _, response, next in
    defer { next() }

    do {
        response.status(HttpStatusCode.OK)
        try response.render("index.html", context: [:]).end()
    } catch {
        Log.error("Failed to render template \(error)")
    }
}

router.post("/invite") { request, response, next in
    let team = "gotandamb"
        
    let body = request.body?.asJson()
    guard let
        email = body?["email"].string,
        token = Environment().getVar("SLACK_API_TOKEN")
    else {
        defer { next() }
        do {
            response.status(.BAD_REQUEST)
            try response.sendJson([ "ok": false, "msg": "invalid_parameters" ]).end()
        } catch { }
        return
    }

    let escapedTeam  = Http.escapeUrl(team)
    let escapedEmail = Http.escapeUrl(email)
    let escapedToken = Http.escapeUrl(token)
    
    let options: [ClientRequestOptions] = [
        .Method("GET"),
        .Schema("https://"),
        .Hostname("\(escapedTeam).slack.com"),
        .Port(443),
        .Path("/api/users.admin.invite?email=\(escapedEmail)&token=\(escapedToken)&set_active=true"),
    ]
    
    let req = Http.request(options) { slackResponse in
        defer { next() }
        
        do {
            let contentType = slackResponse?.headers["content-type"]
            
            if slackResponse?.statusCode != .OK {
                response.status(.INTERNAL_SERVER_ERROR)
                try response.sendJson([ "ok": false, "msg": "http_error" ]).end()
            }
            
            else if contentType?.hasPrefix("application/json") != true {
                response.status(.INTERNAL_SERVER_ERROR)
                try response.sendJson([ "ok": false, "msg": "bad_response" ]).end()
            }

            else {
                if let slackBody = try slackResponse?.readString() {
                    response.status(.OK)
                    try response.sendJson([ "ok": false, "res": slackBody ]).end()
                }
            }
        } catch { }
    }
    
    req.end()
}


// Handles any errors that get set
router.error { request, response, next in
	defer { next() }

	response.setHeader("Content-Type", value: "text/plain; charset=utf-8")
	do {
		try response.send("Caught the error: \(response.error!.localizedDescription)").end()
	}
	catch {}
}


// Listen on port 8090
let server = HttpServer.listen(8090, delegate: router)

Server.run()
