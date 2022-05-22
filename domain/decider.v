module domain

import time { Time, now }
import arrays

const (
	day_switch_hour = 14
	bid_deadline = 20
)

pub fn user_state(user_id string, events []Event, query_time Time) UserState {
	mut user_ranks := map[string]int{}
	mut reservation_state := ReservationState.confirmable
	mut rank := 0
	mut winner := ''
	for day in group_by_day(events, day_switch_hour) {
		mut candidates := compute_candidates(day, user_ranks)
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

fn compute_candidates(day_events []Event, user_ranks map[string]int) List<string> {
	return arrays.fold(day_events, List<string>{},
		fn [user_ranks] (candidates List<string>, event Event) List<string> {
			user_id := event.user_id
			return match event {
				BidEvent {
					if !candidates.empty() &&
						user_ranks[user_id] < user_ranks[candidates.first()] &&
						within_time_span(event.timestamp, day_switch_hour, bid_deadline)
					{
						candidates.prepend(user_id)
					} else {
						candidates.append(user_id)
					}
				}
				CancelEvent {
					if within_time_span(event.timestamp, day_switch_hour, bid_deadline) {
						candidates.remove(user_id)
					} else {
						candidates
					}
				}
			}
		})
}