module main

import domain { Event, BidEvent, CancelEvent, UserState, user_state, User, Storage }
import postgres { PostgresStorage }
import auth
import time { now }
import vweb
import os
import crypto.sha256

struct App {
	vweb.Context
	mut:
		storage PostgresStorage
		user_id string
}

fn main() {
	mut app := &App{storage: PostgresStorage{}}
	port := os.getenv('PORT').int()
	app.handle_static('static', true)
	vweb.run(app, if port > 0 { port } else { 8082 })
}

pub fn (mut app App) index() vweb.Result {
	return app.file("static/index.html")
}

fn (mut app App) auth() bool {
	token := app.get_header('Authorization').after_char(` `)
	mut user := app.storage.resolve_user(token) or { User{} }
	if user.user_id != '' {
		app.user_id = user.user_id
	} else {
		user = auth.fetch_profile(token) or {
			app.user_id = ''
			app.set_status(401, "401 Not Authorized")
			return false
		}
		app.user_id = user.user_id
		app.storage.create_user(sha256.hexhash(token), user) or { return false }
	}
	return true
}

['/state']
pub fn (mut app App) state() vweb.Result {
	if app.user_id != '' || app.auth() {
		user_state := user_state(app.user_id, app.storage.read_events() or { return app.server_error(1)}, now())
		winner := app.storage.read_user(user_state.winner) or { return app.server_error(1) }
		return app.json(UserState{user_state.relative_rank, user_state.reservation_state, winner.display_name})
	} else {
		return app.text("401 Not Authorized")
	}
}

[post]
['/bid']
pub fn (mut app App) bid() vweb.Result {
	if app.auth() {
		app.storage.add_event(BidEvent{ timestamp: now(), user_id: app.user_id }) or {
			println(err)
			return app.server_error(1)
		}
		return app.state()
	} else {
		return app.text("401 Not Authorized")
	}
}

[delete]
['/bid']
pub fn (mut app App) cancel() vweb.Result {
	if app.auth() {
		app.storage.add_event(CancelEvent{ timestamp: now(), user_id: app.user_id }) or { return app.server_error(1) }
		return app.state()
	} else {
		return app.text("401 Not Authorized")
	}
}

[delete]
['/token']
pub fn (mut app App) reset_token() vweb.Result {
	if app.auth() {
		app.storage.reset_token(app.user_id) or { return app.server_error(1) }
	}
	app.set_status(401, "401 Not Authorized")
	return app.text("401 Not Authorized")
}