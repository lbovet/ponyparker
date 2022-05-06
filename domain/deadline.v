module domain
import time { Time, new_time }

pub fn planning_day(t Time, switch_hour int) string {
	return t.add_seconds((24-switch_hour)*3600).ddmmy()
}

pub fn after_hour(t Time, hour int) bool {
	return !before_hour(t, hour)
}

pub fn before_hour(t Time, hour int) bool {
	local_time := t.local()
	mut reference := new_time(Time {
		day: local_time.day
		month: local_time.month
		year: local_time.year
		hour: hour
	})
	return local_time < reference
}