module domain
import time { Time, new_time }

pub fn planning_day(t Time, switch_hour int) string {
	return t.add_seconds((24-switch_hour)*3600).ddmmy()
}

pub fn after_hour(t Time, hour int) bool {
	return !before_hour(t, hour)
}

pub fn before_hour(t Time, hour int) bool {
	mut reference := new_time(Time {
		day: t.day
		month: t.month
		year: t.year
		hour: hour
	})
	return t < reference
}

pub fn within_time_span(timestamp Time, start int, end int) bool {
	return
		after_hour(timestamp, start) &&
		before_hour(timestamp, end)
}