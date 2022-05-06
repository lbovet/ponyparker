module main

import domain { Event, BidEvent, CancelEvent, UserState, user_state, Storage, FileStorage }
import time { now }
import vweb
import os

struct App {
	vweb.Context
	mut:
		storage FileStorage
		user_id string
}

fn main() {
	mut app := &App{storage: FileStorage{}}
	app.storage.init()
	port := os.getenv('PORT').int()
	app.handle_static('static', true)
	vweb.run(app, if port > 0 { port } else { 8082 })
}

pub fn (mut app App) index() vweb.Result {
	return app.file("static/index.html")
}

fn (mut app App) auth() bool {
	token := app.get_header('Authorization').after_char(` `)
	user_id := app.storage.read_user(token).user_id
	if user_id != '' {
		app.user_id = user_id
		return true
	} else {
		// TODO: check and save user
		app.user_id = ''
		app.set_status(401, "401 Not Authorized")
		return false
	}
	return false
}

['/state']
pub fn (mut app App) state() vweb.Result {
	if app.user_id != '' || app.auth() {
		return app.json(user_state(app.user_id, app.storage.read_events(), now()))
	} else {
		return app.text("401 Not Authorized")
	}
}

[post]
['/bid']
pub fn (mut app App) bid() vweb.Result {
	if app.auth() {
		app.storage.add_event(BidEvent{ timestamp: now(), user_id: app.user_id })
		return app.state()
	} else {
		return app.text("401 Not Authorized")
	}
}

[delete]
['/bid']
pub fn (mut app App) cancel() vweb.Result {
	if app.auth() {
		app.storage.add_event(CancelEvent{ timestamp: now(), user_id: app.user_id })
		return app.state()
	} else {
		return app.text("401 Not Authorized")
	}
}
