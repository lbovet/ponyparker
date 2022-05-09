module postgres

import domain { Event, User, Storage }
import pg
import os
import json

const (
	max_event_count = 200
)

pub struct PostgresStorage {
}

pub fn setup() ?pg.DB {
	url := os.getenv('DATABASE_URL')
	conn_spec := url.all_after("postgres://").all_before_last("/")
	host_spec := conn_spec.all_after("@")
	user_spec := conn_spec.all_before("@")

	return pg.connect(pg.Config{
		host: host_spec.all_before(":")
		port: host_spec.all_after(":").int()
		user: user_spec.all_before(":")
		password: user_spec.all_after(":")
		dbname: url.all_after_last("/")
	})
}

pub fn (mut s PostgresStorage) create_user(token string, user User) ? {
	mut db := setup() ?
	defer {
		db.close()
	}
	db.exec_param2("insert into users (creation_time, user_id, display_name) values (current_timestamp, $1, $2)",
		 user.user_id, user.display_name ) or { }
	db.exec_param2("update users set token = $2 where user_id = $1 and token is null", user.user_id, token) or { }
}

pub fn (mut s PostgresStorage) resolve_user(token string) ?User {
	mut db := setup() ?
	defer {
		db.close()
	}
	rows := db.exec_param("select user_id, display_name from users where token = $1", token) ?
	if rows.len > 0  {
		return User{rows[0].vals[0], rows[0].vals[1]}
	} else {
		return error("not found")
	}
}

pub fn (mut s PostgresStorage) read_user(user_id string) ?User {
	mut db := setup() ?
	defer {
		db.close()
	}
	rows := db.exec_param("select user_id, display_name from users where user_id = $1", user_id) ?
	if rows.len > 0  {
		return User{rows[0].vals[0], rows[0].vals[1]}
	} else {
		return error("not found")
	}
}

pub fn (mut s PostgresStorage) reset_token(user_id string) ? {
	mut db := setup() ?
	defer {
		db.close()
	}
	db.exec_param("update users set token = null where user_id = $1", user_id) ?
}

pub fn (mut s PostgresStorage) add_event(event Event) ? {
	mut db := setup() ?
	defer {
		db.close()
	}
	db.exec_param("insert into events (creation_time, json) values (current_timestamp, $1)", json.encode(event)) ?
}

pub fn (mut s PostgresStorage) read_events() ?[]Event {
	mut db := setup() ?
	defer {
		db.close()
	}
	results := db.exec(
		"select * from
			(select json, insert_order from events order by insert_order desc limit 200)
			as events order by insert_order asc;") ?
	return results.map(fn (row pg.Row) Event { return json.decode(Event, row.vals[0]) })
}
