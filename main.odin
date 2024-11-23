package main

import "core:fmt"
import "core:log"
import "core:mem/virtual"
import "core:net"
import http "odin-http"

hello_storage: ^Storage
hello_options: Options


main :: proc() {
	context.logger = log.create_console_logger(.Info)

	s: http.Server
	http.server_shutdown_on_interrupt(&s)
	router: http.Router
	http.router_init(&router)
	defer http.router_destroy(&router)

	hello_options = Options {
		spammers_len               = 299,
		friends_len                = 300,
		name_len                   = 25,
		friend_until_repeat_in_sec = 60,
	}
	arena: virtual.Arena
	arena_allocator := virtual.arena_allocator(&arena)
	hello_storage = storage_init(allocator = arena_allocator)


	http.route_get(
		&router,
		"/hello/(%w+)",
		http.handler(proc(req: ^http.Request, res: ^http.Response) {
				name := req.url_params[0]
				resp_hello, _ := hello_from(hello_storage, hello_options, name)
				http.respond_plain(res, resp_hello)
			}),
	)

	routed := http.router_handler(&router)

	log.info("Listening on http://localhost:6969")

	err := http.listen_and_serve(&s, routed, net.Endpoint{address = net.IP4_Loopback, port = 6969})
	fmt.assertf(err == nil, "server stopped with error: %v", err)
}
