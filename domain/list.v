module domain

struct List<T> {
	data []T
}

fn (a List<T>) prepend(s T) List<T> {
	mut r := []T{}
	r << [s]
	r << a.data
	return List<T> { r }
}

fn (a List<T>) append(s T) List<T> {
	mut r := []T{}
	r << a.data
	r << [s]
	return List<T> { r }
}

fn (a List<T>) contains(s T) bool {
	mut result := false
	for item in a.data {
		if item == s {
			result = true
			break
		}
	}
	return result
}

fn (a List<T>) remove(s T) List<T> {
	return List<T> { a.data.filter(it != s) }
}

fn (a List<T>) empty() bool {
	return a.data.len == 0
}

fn (a List<T>) first() T {
	return a.data.first()
}

fn (a List<T>) to_array() []T {
	return a.data.clone()
}
