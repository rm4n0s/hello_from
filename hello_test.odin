package main

import "core:fmt"
import "core:mem/virtual"
import "core:testing"
import "core:time"
import "trace"

@(test)
test_hello_from :: proc(_: ^testing.T) {
	arena: virtual.Arena
	arena_allocator := virtual.arena_allocator(&arena)
	context.allocator = arena_allocator
	storage := storage_init()
	defer storage_destroy(storage)

	options := Options {
		spammers_len               = 2,
		friends_len                = 2,
		name_len                   = 5,
		friend_until_repeat_in_sec = 1,
	}

	manosHello, manosErr := hello_from(storage, options, "manos")
	fmt.println(manosHello)
	fmt.println(trace.trace(manosErr))

	assert(manosHello == "Hello, nice to meet you manos")
	passedUnknownStackTrace := false
	#partial switch friendError in manosErr {
	case Verify_Friend_Error:
		#partial switch checkErr in friendError {
		case Check_Name_Error:
			#partial switch checkErr {
			case .Unknown:
				passedUnknownStackTrace = true
			}
		}
	}
	assert(passedUnknownStackTrace)

	// wait little longer than one second to test friendship
	time.sleep(time.Second)
	manosHello, manosErr = hello_from(storage, options, "manos")

	fmt.println(trace.trace(manosHello))
	assert(manosHello == "Hello my friend")
	assert(manosErr == nil)


	// break his nerves with one more hello, to become new spammer
	manosHello, manosErr = hello_from(storage, options, "manos")

	fmt.println(trace.trace(manosHello))
	assert(manosHello == "Get away from me")
	passedNewSpammerStackTrace := false
	#partial switch friendError in manosErr {
	case Verify_Friend_Error:
		#partial switch checkErr in friendError {
		case Check_Name_Error:
			#partial switch checkErr {
			case .New_Spammer:
				passedNewSpammerStackTrace = true
			}
		}
	}
	assert(passedNewSpammerStackTrace)


	// one more time as regular spammer
	manosHello, manosErr = hello_from(storage, options, "manos")

	fmt.println(trace.trace(manosErr))
	assert(manosHello == "Get away from me")
	passedSpammerStackTrace := false
	#partial switch friendError in manosErr {
	case Verify_Friend_Error:
		#partial switch checkErr in friendError {
		case Check_Name_Error:
			#partial switch checkErr {
			case .Spammer:
				passedSpammerStackTrace = true
			}
		}
	}
	assert(passedSpammerStackTrace)
}


@(test)
test_storage :: proc(_: ^testing.T) {
	arena: virtual.Arena
	arena_allocator := virtual.arena_allocator(&arena)
	context.allocator = arena_allocator
	storage := storage_init()
	defer storage_destroy(storage)


	options := Options {
		spammers_len               = 2,
		friends_len                = 3,
		name_len                   = 5,
		friend_until_repeat_in_sec = 1,
	}

	// test friend storage length
	hello_from(storage, options, "manos")
	hello_from(storage, options, "nikos")
	hello_from(storage, options, "panos")
	_, xeniaErr := hello_from(storage, options, "xenia")
	fmt.println(trace.trace(xeniaErr))
	fmt.println(storage.friends)
	passedFriendStorageStackTrace := false
	#partial switch friendError in xeniaErr {
	case Verify_Friend_Error:
		#partial switch checkErr in friendError {
		case Add_Friend_Error:
			#partial switch checkErr {
			case .Not_Enough_Space:
				passedFriendStorageStackTrace = true
			}
		}
	}
	assert(passedFriendStorageStackTrace)

	// test spammer storage length
	hello_from(storage, options, "manos")
	hello_from(storage, options, "nikos")
	_, panosErr := hello_from(storage, options, "panos")
	fmt.println(trace.trace(panosErr))
	fmt.println(storage.spammers)

	passedSpammerStorageStackTrace := false
	#partial switch friendError in panosErr {
	case Verify_Friend_Error:
		#partial switch checkErr in friendError {
		case Add_Spammer_Error:
			#partial switch checkErr {
			case .Not_Enough_Space:
				passedSpammerStorageStackTrace = true
			}
		}
	}
	assert(passedSpammerStorageStackTrace)
}


@(test)
test_name :: proc(_: ^testing.T) {
	arena: virtual.Arena
	arena_allocator := virtual.arena_allocator(&arena)
	context.allocator = arena_allocator
	storage := storage_init()
	defer storage_destroy(storage)


	options := Options {
		spammers_len               = 2,
		friends_len                = 3,
		name_len                   = 5,
		friend_until_repeat_in_sec = 1,
	}

	_, helloErr := hello_from(storage, options, "bigname")
	passedNoLongStackTrace := false
	#partial switch err in helloErr {
	case Verify_Name_Error:
		#partial switch err {
		case .Name_To_Long:
			passedNoLongStackTrace = true
		}
	}

	assert(passedNoLongStackTrace)
}

@(test)
lock_stack_traces :: proc(_: ^testing.T) {
	arena: virtual.Arena
	arena_allocator := virtual.arena_allocator(&arena)
	context.allocator = arena_allocator
	storage := storage_init()
	defer storage_destroy(storage)


	options := Options {
		spammers_len               = 2,
		friends_len                = 3,
		name_len                   = 5,
		friend_until_repeat_in_sec = 1,
	}

	// lock stack traces
	_, helloErr := hello_from(storage, options, "manos")
	switch err in helloErr {
	case Verify_Name_Error:
		switch err {
		case .Name_To_Long:
		case .None:
		}
	case Verify_Friend_Error:
		switch errFriend in err {
		case Check_Name_Error:
			switch errFriend {
			case .None:
			case .New_Spammer:
			case .Spammer:
			case .Unknown:
			}
		case Add_Friend_Error:
			switch errFriend {
			case .None:
			case .Not_Enough_Space:
			}
		case Add_Spammer_Error:
			switch errFriend {
			case .None:
			case .Not_Enough_Space:
			}
		}
	}
}
