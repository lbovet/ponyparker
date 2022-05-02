module main

import vweb
import rand
import os

struct App {
	vweb.Context
mut:
	state shared State
}

struct State {
mut:
	cnt int
}

fn main() {
	mut app := &App{}
	port := os.getenv('PORT').int()
	app.handle_static('assets', true)
	vweb.run(app, if port > 0 { port } else { 8082 })
}

['/users/:user']
pub fn (mut app App) user_endpoint(user string) vweb.Result {
	id := rand.intn(100) or { 0 }
	return app.json({
		user: id
	})
}

pub fn (mut app App) index() vweb.Result {
	lock app.state {
		app.state.cnt++
	}
	show := true
	hello := 'Hello world from vweb'
	numbers := [1, 2, 3]
	return $vweb.html()
}

pub fn (mut app App) show_text() vweb.Result {
	return app.text('Hello world from vweb')
}

pub fn (mut app App) cookie() vweb.Result {
	app.set_cookie(name: 'cookie', value: 'test')
	return app.text('Response Headers\n$app.header')
}

[post]
pub fn (mut app App) post() vweb.Result {
	return app.text('Post body: $app.req.data')
}
