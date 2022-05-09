module domain

import os
import io
import json

pub interface Storage {
	mut:
		init() ?

		resolve_user(token string) ?User
	 	create_user(token string, user User) ?
		read_user(user_id string) ?
		reset_token(user_id string) ?

		add_event(e Event) ?
		read_events() ?[]Event
}

const ( filename = "./db.txt" )

pub struct FileStorage {
}

pub fn (mut s FileStorage) create_user(token string, user User) ? {

}

pub fn (mut s FileStorage) resolve_user(token string) ?User {
	return User{token, token}
}

pub fn (mut s FileStorage) read_user(user_id string) ?User {
	return User{user_id, "["+user_id+"]"}
}

pub fn (mut s FileStorage) reset_token(token string) ? {

}

pub fn (mut s FileStorage) init() ? {
	os.rm(filename) or {}
}

pub fn (mut s FileStorage) add_event(event Event) ? {
	mut f := os.open_append(filename) ?
	defer { f.close() }
	serialized := json.encode(event)
	f.write_string(serialized + "\n") ?
}

pub fn (mut s FileStorage) read_events() ?[]Event {
	mut result := []Event{}
	mut f := os.open(filename) ?
	defer { f.close() }
	mut r := io.new_buffered_reader(reader: f)
	for {
		l := r.read_line() or { break }
		event := json.decode(Event, l) ?
		result << event
	}
	return result
}
