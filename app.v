module main

import domain { Event, BidEvent, CancelEvent, UserState, user_state, User, Storage, FileStorage }
import postgres { PostgresStorage }
import auth
import time { now }
import vweb
import os
import crypto.sha256
import net.http { new_request, Method }

struct App {
	vweb.Context
	mut:
		storage Storage
		user_id string
}

fn main() {
	mut app := &App{storage: storage()}
	port := os.getenv('PORT').int()
	app.handle_static('static', true)
	vweb.run(app, if port > 0 { port } else { 8082 })
}

fn storage() Storage {
	$if debug {
		return FileStorage{}
	} $else {
		return PostgresStorage{}
	}
}

pub fn (mut app App) index() vweb.Result {
	return app.file("static/index.html")
}

fn (mut app App) auth() bool {
	authorization := app.get_header('Authorization')
	token := authorization.all_after("Bearer").trim_space()
	if authorization == '' || token == '' {
		app.set_status(401, "Not Authorized")
		return false
	}
	mut user := app.storage.resolve_user(token) or {
		app.storage.resolve_user(sha256.hexhash(token)) or {
			User{}
		}
	}
	if user.user_id != '' {
		app.user_id = user.user_id
	} else {
		if token.len == 64 {
			app.set_status(403, "Forbidden")
			return false
		} else {
			user = auth.fetch_profile(token) or {
				app.user_id = ''
				app.set_status(401, "Authentication Failed")
				return false
			}
			app.user_id = user.user_id
			app.storage.create_user(sha256.hexhash(token), user) or { return false }
		}
	}
	return true
}

['/state']
pub fn (mut app App) state() vweb.Result {
	if app.user_id != '' || app.auth() {
		user_state := user_state(app.user_id, app.storage.read_events() or { return app.server_error(1) }, now())
		winner := app.storage.read_user(user_state.winner) or { User{display_name: ''} }
		return app.json(UserState{user_state.relative_rank, user_state.reservation_state, winner.display_name})
	} else {
		return app.text("Authentication failed")
	}
}

[post]
['/bid']
pub fn (mut app App) bid() vweb.Result {
	if app.auth() {
		app.storage.add_event(BidEvent{ timestamp: now(), user_id: app.user_id }) or {
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
		app.storage.add_event(CancelEvent{ timestamp: now(), user_id: app.user_id }) or { return app.server_error(2) }
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
		app.set_status(418, "401 Token Reset")
	} else {
		app.set_status(401, "401 Token Reset")
	}
	return app.text("401 Token Reset")
}

['/locks.ics']
pub fn (mut app App) get_locks() !vweb.Result {
	mut request := new_request(Method.get, os.getenv("LOCK_CALENDAR"), '')
	response := request.do() or { return app.server_error(4) }
	if response.status_code == 200 {
		app.set_content_type("text/calendar")
		return app.ok(response.body)
	} else {
		return error('cannot get calendar')
	}
}
