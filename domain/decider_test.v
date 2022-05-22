import domain { user_state, Event, BidEvent, CancelEvent, ReservationState }
import time { Time, new_time }

fn make_time(day int, hour int) Time {
	return new_time(Time{ day: day, month: 1, year: 2000, hour: hour - 1 })
}

fn test_empty() {
	events := []Event{}
	assert user_state("john", events, make_time(1, 8)).reservation_state == ReservationState.confirmable
	assert user_state("john", events, make_time(1, 15)).reservation_state == ReservationState.confirmable
	assert user_state("john", events, make_time(1, 21)).reservation_state == ReservationState.confirmable
}

fn test_confirmed_open_bid() {
	mut events := []Event{}
	events << BidEvent{ timestamp: make_time(1, 15), user_id: "john" }
	assert user_state("john", events, make_time(1, 16)).reservation_state == ReservationState.confirmed
	assert user_state("paul", events, make_time(1, 16)).reservation_state == ReservationState.refused
	assert user_state("john", events, make_time(1, 21)).reservation_state == ReservationState.confirmed
	assert user_state("paul", events, make_time(1, 21)).reservation_state == ReservationState.refused
}

fn test_smaller_rank_similar_to_newcomer() {
	mut events := []Event{}
	events << BidEvent{ timestamp: make_time(1, 15), user_id: "john" }
	events << BidEvent{ timestamp: make_time(2, 15), user_id: "john" }
	assert user_state("john", events, make_time(2, 16)).reservation_state == ReservationState.confirmed
	assert user_state("paul", events, make_time(2, 16)).reservation_state == ReservationState.refused
	events << BidEvent{ timestamp: make_time(2, 17), user_id: "paul" }
	assert user_state("john", events, make_time(2, 18)).reservation_state == ReservationState.refused
	assert user_state("paul", events, make_time(2, 18)).reservation_state == ReservationState.confirmed
	assert user_state("john", events, make_time(2, 21)).reservation_state == ReservationState.refused
	assert user_state("paul", events, make_time(2, 21)).reservation_state == ReservationState.confirmed
}

fn test_smaller_rank_priority() {
	mut events := []Event{}
	events << BidEvent{ timestamp: make_time(1, 15), user_id: "john" }
	events << BidEvent{ timestamp: make_time(2, 15), user_id: "john" }
	events << BidEvent{ timestamp: make_time(3, 15), user_id: "paul" }
	assert user_state("john", events, make_time(4, 16)).reservation_state == ReservationState.placeable
	assert user_state("paul", events, make_time(4, 16)).reservation_state == ReservationState.confirmable
	events << BidEvent{ timestamp: make_time(4, 17), user_id: "john" }
	assert user_state("john", events, make_time(4, 17)).reservation_state == ReservationState.placed
	assert user_state("paul", events, make_time(4, 17)).reservation_state == ReservationState.confirmable
	events << BidEvent{ timestamp: make_time(4, 18), user_id: "paul" }
	assert user_state("john", events, make_time(4, 19)).reservation_state == ReservationState.refused
	assert user_state("paul", events, make_time(4, 19)).reservation_state == ReservationState.confirmed
	assert user_state("john", events, make_time(4, 21)).reservation_state == ReservationState.refused
	assert user_state("paul", events, make_time(4, 21)).reservation_state == ReservationState.confirmed
}

fn test_equal_rank_priority() {
	mut events := []Event{}
	events << BidEvent{ timestamp: make_time(1, 15), user_id: "john" }
	events << BidEvent{ timestamp: make_time(2, 15), user_id: "john" }
	events << BidEvent{ timestamp: make_time(3, 15), user_id: "paul" }
	events << BidEvent{ timestamp: make_time(4, 15), user_id: "paul" }
	events << BidEvent{ timestamp: make_time(5, 15), user_id: "ringo" }
	assert user_state("john", events, make_time(6, 16)).reservation_state == ReservationState.placeable
	assert user_state("paul", events, make_time(6, 16)).reservation_state == ReservationState.placeable
	assert user_state("ringo", events, make_time(6, 16)).reservation_state == ReservationState.confirmable
	events << BidEvent{ timestamp: make_time(6, 17), user_id: "john" }
	assert user_state("john", events, make_time(6, 18)).reservation_state == ReservationState.placed
	assert user_state("paul", events, make_time(6, 18)).reservation_state == ReservationState.refused
	assert user_state("ringo", events, make_time(6, 16)).reservation_state == ReservationState.confirmable
	events << BidEvent{ timestamp: make_time(6, 17), user_id: "paul" }
	assert user_state("john", events, make_time(6, 18)).reservation_state == ReservationState.placed
	assert user_state("paul", events, make_time(6, 18)).reservation_state == ReservationState.refused
	assert user_state("ringo", events, make_time(6, 18)).reservation_state == ReservationState.confirmable
	assert user_state("john", events, make_time(6, 21)).reservation_state == ReservationState.confirmed
	assert user_state("paul", events, make_time(6, 21)).reservation_state == ReservationState.refused
	assert user_state("ringo", events, make_time(6, 21)).reservation_state == ReservationState.refused
}

fn test_after_bid_time() {
	mut events := []Event{}
	events << BidEvent{ timestamp: make_time(1, 15), user_id: "john" }
	events << BidEvent{ timestamp: make_time(2, 15), user_id: "john" }
	events << BidEvent{ timestamp: make_time(3, 15), user_id: "paul" }
	assert user_state("john", events, make_time(4, 21)).reservation_state == ReservationState.confirmable
	assert user_state("paul", events, make_time(4, 21)).reservation_state == ReservationState.confirmable
	events << BidEvent{ timestamp: make_time(4, 21), user_id: "john" }
	assert user_state("john", events, make_time(4, 22)).reservation_state == ReservationState.confirmed
	assert user_state("paul", events, make_time(4, 22)).reservation_state == ReservationState.refused
}

fn test_cancel_restores_rank() {
	mut events := []Event{}
	events << BidEvent{ timestamp: make_time(1, 15), user_id: "john" }
	events << BidEvent{ timestamp: make_time(2, 15), user_id: "john" }
	events << CancelEvent{ timestamp: make_time(2, 15), user_id: "john" }
	events << BidEvent{ timestamp: make_time(3, 15), user_id: "paul" }
	assert user_state("john", events, make_time(4, 16)).reservation_state == ReservationState.confirmable
	assert user_state("paul", events, make_time(4, 16)).reservation_state == ReservationState.confirmable
	events << BidEvent{ timestamp: make_time(4, 17), user_id: "john" }
	assert user_state("john", events, make_time(4, 17)).reservation_state == ReservationState.confirmed
	assert user_state("paul", events, make_time(4, 17)).reservation_state == ReservationState.refused
}

fn test_placed_wins() {
	mut events := []Event{}
	events << BidEvent{ timestamp: make_time(1, 15), user_id: "john" }
	events << BidEvent{ timestamp: make_time(2, 15), user_id: "john" }
	events << BidEvent{ timestamp: make_time(3, 15), user_id: "paul" }
	events << BidEvent{ timestamp: make_time(4, 15), user_id: "john" }
	assert user_state("john", events, make_time(4, 16)).reservation_state == ReservationState.placed
	assert user_state("paul", events, make_time(4, 16)).reservation_state == ReservationState.confirmable
	assert user_state("john", events, make_time(4, 21)).reservation_state == ReservationState.confirmed
	assert user_state("paul", events, make_time(4, 21)).reservation_state == ReservationState.refused
}

fn test_placed_confirmed_day_after() {
	mut events := []Event{}
	events << BidEvent{ timestamp: make_time(1, 15), user_id: "john" }
	events << BidEvent{ timestamp: make_time(2, 15), user_id: "john" }
	events << BidEvent{ timestamp: make_time(3, 15), user_id: "paul" }
	events << BidEvent{ timestamp: make_time(4, 15), user_id: "john" }
	assert user_state("john", events, make_time(4, 16)).reservation_state == ReservationState.placed
	assert user_state("paul", events, make_time(4, 16)).reservation_state == ReservationState.confirmable
	assert user_state("john", events, make_time(5, 8)).reservation_state == ReservationState.confirmed
	assert user_state("paul", events, make_time(5, 8)).reservation_state == ReservationState.refused
}

fn test_cancel_placed() {
	mut events := []Event{}
	events << BidEvent{ timestamp: make_time(1, 15), user_id: "john" }
	events << BidEvent{ timestamp: make_time(2, 15), user_id: "john" }
	events << BidEvent{ timestamp: make_time(3, 15), user_id: "paul" }
	events << BidEvent{ timestamp: make_time(4, 15), user_id: "john" }
	assert user_state("john", events, make_time(4, 16)).reservation_state == ReservationState.placed
	assert user_state("paul", events, make_time(4, 16)).reservation_state == ReservationState.confirmable
	events << CancelEvent{ timestamp: make_time(4, 16), user_id: "john" }
	assert user_state("john", events, make_time(4, 17)).reservation_state == ReservationState.placeable
	assert user_state("paul", events, make_time(4, 17)).reservation_state == ReservationState.confirmable
	events << BidEvent{ timestamp: make_time(4, 18), user_id: "paul" }
	assert user_state("paul", events, make_time(4, 19)).reservation_state == ReservationState.confirmed
	assert user_state("john", events, make_time(4, 19)).reservation_state == ReservationState.refused
}

fn test_cancel_confirmed() {
	mut events := []Event{}
	events << BidEvent{ timestamp: make_time(1, 15), user_id: "john" }
	events << BidEvent{ timestamp: make_time(2, 15), user_id: "john" }
	events << BidEvent{ timestamp: make_time(3, 15), user_id: "paul" }
	events << BidEvent{ timestamp: make_time(4, 15), user_id: "john" }
	assert user_state("john", events, make_time(4, 16)).reservation_state == ReservationState.placed
	assert user_state("paul", events, make_time(4, 16)).reservation_state == ReservationState.confirmable
	events << BidEvent{ timestamp: make_time(4, 17), user_id: "paul" }
	assert user_state("paul", events, make_time(4, 18)).reservation_state == ReservationState.confirmed
	assert user_state("john", events, make_time(4, 18)).reservation_state == ReservationState.refused
	events << CancelEvent{ timestamp: make_time(4, 19), user_id: "paul" }
	assert user_state("john", events, make_time(4, 19)).reservation_state == ReservationState.placed
	assert user_state("paul", events, make_time(4, 19)).reservation_state == ReservationState.confirmable
	assert user_state("john", events, make_time(4, 21)).reservation_state == ReservationState.confirmed
	assert user_state("paul", events, make_time(4, 21)).reservation_state == ReservationState.refused
}

fn test_no_cancel_after_bid_time() {
	mut events := []Event{}
	events << BidEvent{ timestamp: make_time(1, 15), user_id: "john" }
	events << BidEvent{ timestamp: make_time(2, 15), user_id: "john" }
	events << BidEvent{ timestamp: make_time(3, 15), user_id: "paul" }
	events << BidEvent{ timestamp: make_time(4, 15), user_id: "john" }
	assert user_state("john", events, make_time(4, 16)).reservation_state == ReservationState.placed
	assert user_state("paul", events, make_time(4, 16)).reservation_state == ReservationState.confirmable
	events << BidEvent{ timestamp: make_time(4, 17), user_id: "paul" }
	assert user_state("paul", events, make_time(4, 18)).reservation_state == ReservationState.confirmed
	assert user_state("john", events, make_time(4, 18)).reservation_state == ReservationState.refused
	events << CancelEvent{ timestamp: make_time(4, 21), user_id: "paul" }
	assert user_state("paul", events, make_time(4, 22)).reservation_state == ReservationState.confirmed
	assert user_state("john", events, make_time(4, 22)).reservation_state == ReservationState.refused
}

fn test_cancel_after_bid_time_keeps_rank() {
	mut events := []Event{}
	events << BidEvent{ timestamp: make_time(1, 15), user_id: "john" }
	events << BidEvent{ timestamp: make_time(2, 15), user_id: "john" }
	events << CancelEvent{ timestamp: make_time(2, 22), user_id: "john" }
	events << BidEvent{ timestamp: make_time(3, 15), user_id: "paul" }
	assert user_state("john", events, make_time(4, 16)).reservation_state == ReservationState.placeable
	assert user_state("paul", events, make_time(4, 16)).reservation_state == ReservationState.confirmable
}