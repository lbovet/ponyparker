module auth

import domain { User }
import json
import net.http { new_request, Method, CommonHeader }

[unsafe]
struct Profile {
	username string
	given_name string
	surname string
}

pub fn fetch_profile(token string) ?User {
	mut request := new_request(Method.get, "https://graph.microsoft.com/v1.0/me", '') or { return error('cannot create request') }
	request.add_header(CommonHeader.authorization, "Bearer " + token)
	response := request.do() or { return error('cannot perform request') }
	if response.status_code == 200 {
		text := response.text
			.replace("userPrincipalName", "username")
			.replace("givenName", "given_name")
		profile := json.decode(Profile, text) or { return error('cannot parse') }
		if profile.username.ends_with("@post.ch") {
			return User{ user_id: profile.username, display_name: profile.given_name+" "+profile.surname }
		} else {
			return error('forbidden')
		}
	} else {
		return error('auth failed')
	}
}