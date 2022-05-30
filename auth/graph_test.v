import auth

import os
import io
import crypto.sha256

fn test_user_profile() {
	if os.exists("token.txt") {
		mut f := os.open("token.txt") or { panic(err) }
		defer { f.close() }
		mut r := io.new_buffered_reader(reader: f)
		token := r.read_line() or { panic(err) }
		user := auth.fetch_profile(token) or { panic(err) }
		assert user.user_id.starts_with("laurent.bovet")
		assert user.display_name == "Laurent Bovet"
	}
}