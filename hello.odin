package main

import "core:fmt"
import "core:mem/virtual"
import "core:time"


Verify_Name_Error :: enum {
	None,
	Name_To_Long,
}


Check_Name_Error :: enum {
	None,
	New_Spammer,
	Spammer,
	Unknown,
}

Add_Friend_Error :: enum {
	None,
	Not_Enough_Space,
}

Add_Spammer_Error :: enum {
	None,
	Not_Enough_Space,
}

Verify_Friend_Error :: union #shared_nil {
	Check_Name_Error,
	Add_Friend_Error,
	Add_Spammer_Error,
}


Hello_From_Error :: union #shared_nil {
	Verify_Name_Error,
	Verify_Friend_Error,
}

Storage :: struct {
	friends:  map[string]time.Time,
	spammers: map[string]int,
}

Options :: struct {
	name_len:                   int,
	friends_len:                int,
	spammers_len:               int,
	friend_until_repeat_in_sec: f64,
}


storage_init :: proc(allocator := context.allocator) -> ^Storage {
	context.allocator = allocator
	storage := new(Storage)
	storage.friends = make(map[string]time.Time)
	storage.spammers = make(map[string]int)
	return storage
}


storage_destroy :: proc(storage: ^Storage, allocator := context.allocator) {
	context.allocator = allocator
	delete_map(storage.friends)
	delete_map(storage.spammers)
	free(storage)
}

hello_from :: proc(
	storage: ^Storage,
	opts: Options,
	name: string,
	allocator := context.allocator,
) -> (
	string,
	Hello_From_Error,
) {
	context.allocator = allocator
	errVerName := verify_name(opts, name)
	if errVerName != .None {
		return "Name too long", errVerName
	}

	errVerFriend := verify_friend(storage, opts, name)
	if errVerFriend == nil {
		return fmt.tprint("Hello my friend"), errVerFriend
	} else {
		if errVerFriend == .Unknown {
			return fmt.tprint("Hello, nice to meet you", name), errVerFriend
		}

		if errVerFriend == .Spammer || errVerFriend == .New_Spammer {
			return fmt.tprint("Get away from me"), errVerFriend
		}

		#partial switch err1 in errVerFriend {
		case Add_Friend_Error:
			#partial switch err1 {
			case .Not_Enough_Space:
				fmt.println("log: not enough space in friends array")
			}

		case Add_Spammer_Error:
			#partial switch err1 {
			case .Not_Enough_Space:
				fmt.println("log: not enough space in spammer array")
			}
		}
	}

	return fmt.aprint("Something wrong happened"), errVerFriend
}

verify_name :: proc(opts: Options, name: string) -> Verify_Name_Error {
	if len(name) > opts.name_len {
		return .Name_To_Long
	}
	return .None
}


verify_friend :: proc(storage: ^Storage, opts: Options, name: string) -> Verify_Friend_Error {
	errCheck := check_name(storage, opts, name)

	err: Verify_Friend_Error
	switch errCheck {
	case .None:
		update_friend(storage, name)
		err = errCheck
	case .Unknown:
		errFriend := add_friend(storage, opts, name)
		switch errFriend {
		case .None:
			err = errCheck
		case .Not_Enough_Space:
			err = errFriend
		}
	case .New_Spammer:
		remove_friend(storage, name)
		errSpammer := add_spammer(storage, opts, name)
		switch errSpammer {
		case .None:
			err = errCheck
		case .Not_Enough_Space:
			err = errSpammer
		}
	case .Spammer:
		update_spammer(storage, name)
		err = errCheck
	}
	return err
}


check_name :: proc(storage: ^Storage, opts: Options, name: string) -> Check_Name_Error {
	friend, isFriend := storage.friends[name]
	if isFriend {
		nw := time.now()
		dur := time.diff(friend, nw)
		if time.duration_seconds(dur) <= opts.friend_until_repeat_in_sec {
			return .New_Spammer
		}
		return .None
	}

	spammer, isSpammer := storage.spammers[name]
	if isSpammer {
		return .Spammer
	}

	if !isSpammer && !isFriend {
		return .Unknown
	}

	return .None
}

add_friend :: proc(storage: ^Storage, opts: Options, name: string) -> Add_Friend_Error {
	if len(storage.friends) < opts.friends_len {
		storage.friends[name] = time.now()
		return .None
	}
	return .Not_Enough_Space
}


add_spammer :: proc(storage: ^Storage, opts: Options, name: string) -> Add_Spammer_Error {
	if len(storage.spammers) < opts.spammers_len {
		storage.spammers[name] = 1
		return .None
	}
	return .Not_Enough_Space
}

update_friend :: proc(storage: ^Storage, name: string) {
	friend, isFriend := &storage.friends[name]
	if isFriend {
		friend^ = time.now()
	}
}


update_spammer :: proc(storage: ^Storage, name: string) {
	spammer, isSpammer := &storage.spammers[name]
	if isSpammer {
		spammer^ += 1
	}
}

remove_friend :: proc(storage: ^Storage, name: string) {
	_, isFriend := storage.friends[name]
	if isFriend {
		delete_key(&storage.friends, name)
	}
}
