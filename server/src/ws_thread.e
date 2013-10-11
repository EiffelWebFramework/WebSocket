note
	description: "WebSocket thread."
	author: "Olivier Ligot"

class
	WS_THREAD

inherit
	THREAD
		rename
			make as thread_make
		end

create
	make

feature {NONE} -- Initialization

	make (a_socket: NETWORK_STREAM_SOCKET)
			-- Create the thread.
		do
			thread_make
			socket := a_socket
		end

feature -- Access

	socket: NETWORK_STREAM_SOCKET
			-- Socket

feature -- Basic operations

	execute
			-- Routine executed when thread is launched.
		do
			sleep (Sleep_time)
			socket.put_string ("%/129/%/11/Hello World")
			sleep (Sleep_time)
			socket.put_string ("%/129/%/18/How are you there?")
			sleep (Sleep_time)
			socket.cleanup
		end

feature {NONE} -- Implementation

	Sleep_time: INTEGER = 1000000000
			-- Sleep time (1 second)

end
