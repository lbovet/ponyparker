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

pub struct NoneEvent {
	BaseEvent
}

pub type Event = BidEvent | CancelEvent | NoneEvent

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