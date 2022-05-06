module domain

pub enum ReservationState {
	confirmable
	placeable
	placed
	confirmed
	refused
}

pub struct UserState {
	pub :
		relative_rank int
		reservation_state ReservationState
		winner string
}
