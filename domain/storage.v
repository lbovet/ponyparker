module domain

import os
import io
import json

pub interface Storage {
	mut:
		read_user(token string) User
	 	write_user(token string, user User)

		init()

		add_event(e Event)
		read_events() []Event
}

const ( filename = "./db.txt" )

pub struct FileStorage {
}

pub fn (mut s FileStorage) write_user(token string, user User) {

}

pub fn (mut s FileStorage) read_user(token string) User {
	return User{token, token}
}

pub fn (mut s FileStorage) init() {
	os.rm(filename) or {}
}

pub fn (mut s FileStorage) add_event(event Event) {
	mut f := os.open_append(filename) or  { panic(err) }
	defer { f.close() }
	serialized := json.encode(event)
	f.write_string(serialized + "\n") or { panic(err) }
}

pub fn (mut s FileStorage) read_events() []Event {
	mut result := []Event{}
	mut f := os.open(filename) or { return []Event{} }
	defer { f.close() }
	mut r := io.new_buffered_reader(reader: f)
	for {
		l := r.read_line() or { break }
		event := json.decode(Event, l) or { panic(err) }
		result << event
	}
	return result
}
