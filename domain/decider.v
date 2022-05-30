module domain

import time { Time, now }
import arrays

const (
	day_switch_hour = 14
	bid_deadline = 20
)

struct Summary {
	candidates List<string>
	late_cancellers List<string>
}

pub fn user_state(user_id string, events []Event, query_time Time) UserState {
	mut user_ranks := map[string]int{}
	mut reservation_state := ReservationState.confirmable
	mut rank := 0
	mut winner := ''
	for day in group_by_day(events, day_switch_hour) {
		mut summary := compute_summary(day, user_ranks)
		mut candidates := summary.candidates
		mut late_cancellers := summary.late_cancellers
		rank = relative_rank(user_id, user_ranks)
		if !candidates.empty() {
			if planning_day(day[0].BaseEvent.timestamp, day_switch_hour) == planning_day(query_time, day_switch_hour) {
				if user_id == candidates.first() {
					if rank == 0 {
						reservation_state = ReservationState.confirmed
						winner = candidates.first()
					} else {
						if within_time_span(query_time, day_switch_hour, bid_deadline) {
							reservation_state = ReservationState.placed
						} else {
							reservation_state = ReservationState.confirmed
							winner = candidates.first()
						}
					}
				} else {
					if within_time_span(query_time, day_switch_hour, bid_deadline) {
						if rank < relative_rank(candidates.first(), user_ranks) {
							if rank == 0 {
								reservation_state = ReservationState.confirmable
							} else {
								reservation_state = ReservationState.placeable
							}
						} else {
							reservation_state = ReservationState.refused
							winner = candidates.first()
						}
					} else {
						reservation_state = ReservationState.refused
						winner = candidates.first()
					}
				}
			} else {
				increase_rank(candidates.first(), mut user_ranks)
				rank = relative_rank(user_id, user_ranks)
				if rank == 0 || !within_time_span(query_time, day_switch_hour, bid_deadline) {
					reservation_state = ReservationState.confirmable
				} else {
					reservation_state = ReservationState.placeable
				}
			}
		} else {
			if planning_day(day[0].BaseEvent.timestamp, day_switch_hour) != planning_day(query_time, day_switch_hour) {
				for late_canceller in late_cancellers.to_array() {
					increase_rank(late_canceller, mut user_ranks)
				}
				rank = relative_rank(user_id, user_ranks)
				if rank == 0 || !within_time_span(query_time, day_switch_hour, bid_deadline) {
					reservation_state = ReservationState.confirmable
				} else {
					reservation_state = ReservationState.placeable
				}
			}
		}
	}
	return UserState{ relative_rank: rank, reservation_state: reservation_state, winner: winner}
}

fn relative_rank(user_id string, user_ranks map[string]int) int {
	if user_ranks[user_id] == 0 {
		return 0
	} else {
		m := arrays.reduce(user_ranks.keys().map(user_ranks[it]), fn (a int, b int) int { return if a < b { a } else { b } }) or { 0 }
		return user_ranks[user_id] - m
	}
}

fn increase_rank(user_id string, mut user_ranks map[string]int) {
	user_ranks[user_id] += 1
}

fn compute_summary(day_events []Event, user_ranks map[string]int) Summary {
	return arrays.fold(day_events, Summary{List<string>{}, List<string>{}},
		fn [user_ranks] (summary Summary, event Event) Summary {
			user_id := event.user_id
			return match event {
				BidEvent {
					if !summary.candidates.empty() &&
						user_ranks[user_id] < user_ranks[summary.candidates.first()] &&
						within_time_span(event.timestamp, day_switch_hour, bid_deadline)
					{
						Summary{summary.candidates.prepend(user_id), summary.late_cancellers}
					} else {
						Summary{summary.candidates.append(user_id), summary.late_cancellers}
					}
				}
				CancelEvent {
					if within_time_span(event.timestamp, day_switch_hour, bid_deadline) {
						Summary{summary.candidates.remove(user_id), summary.late_cancellers}
					} else {
						if !summary.candidates.empty() && summary.candidates.first() == user_id {
							Summary{List<string>{}, summary.late_cancellers.append(user_id)}
						} else {
							if !summary.late_cancellers.contains(user_id) {
								Summary{summary.candidates, summary.late_cancellers.append(user_id)}
							} else {
								Summary{summary.candidates, summary.late_cancellers}
							}
						}
					}
				}
				else {
					Summary{summary.candidates, summary.late_cancellers}
				}
			}
		})
}