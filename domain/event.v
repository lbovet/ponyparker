module domain

import time { Time }

struct BaseEvent {
	timestamp Time
	user_id string
}

pub struct BidEvent {
	BaseEvent
}

pub struct CancelEvent {
	BaseEvent
}

pub type Event = BidEvent | CancelEvent

pub fn (event BaseEvent) within_bid_time(start int, end int) bool {
	return
		after_hour(event.timestamp, start) &&
		before_hour(event.timestamp, end)
}

fn group_by_day(events []Event, switch_hour int) [][]Event  {
	mut last_key := ''
	mut result := [][]Event{}
	mut current := []Event{}
	for e in events {
		key := planning_day(e.BaseEvent.timestamp, switch_hour)
		if key != last_key {
			current = []Event{}
			current << e
			result << current
		} else {
			result.last() << e
		}
		last_key = key
	}
	return result
}