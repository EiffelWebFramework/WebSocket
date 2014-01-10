note
	description: "[
		API to perform actions like opening and closing the connection, sending and receiving messages, and listening
		for events.
	]"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	WEB_SOCKET_EVENT_I

inherit

	WEB_SOCKET_CONSTANTS

	REFACTORING_HELPER

feature -- Web Socket Interface

	on_event (conn: WS_STREAM_SOCKET; a_message: detachable READABLE_STRING_8; a_opcode: INTEGER)
			-- Called when a frame from the client has been receive
		require
			conn_attached: conn /= Void
			conn_valid: conn.is_open_read and then conn.is_open_write
		local
			l_message: READABLE_STRING_8
		do
			debug ("ws")
				print ("%Non_event (conn, a_message, " + opcode_name (a_opcode) + ")%N")
			end
			if a_message = Void then
				create {STRING} l_message.make_empty
			else
				l_message := a_message
			end

			if a_opcode = Binary_frame then
				do_send (conn, Binary_frame, l_message)
			elseif a_opcode = Text_frame then
				do_send (conn, Text_frame, l_message)
			elseif a_opcode = Pong_frame then
					-- log ("Its a pong frame")
					-- at first we ignore  pong
					-- FIXME: provide better explanation
			elseif a_opcode = Ping_frame then
				do_send (conn, Pong_frame, l_message)
			elseif a_opcode = Connection_close_frame then
				do_send (conn, connection_close_frame, "")
			end
		end

	on_open (conn: WS_STREAM_SOCKET)
			-- Called after handshake, indicates that a complete WebSocket connection has been established.
		require
			conn_attached: conn /= Void
			conn_valid: conn.is_open_read and then conn.is_open_write
		deferred
		end

	on_close (conn: WS_STREAM_SOCKET)
			-- Called after the WebSocket connection is closed.
		require
			conn_attached: conn /= Void
			conn_valid: conn.is_open_read and then conn.is_open_write
		do
			conn.send_message (close_message)
		end

	close_message: STRING
		do
			create Result.make_empty
			Result.append_code (129)
			Result.append_code (2)
		end

feature {NONE} -- Implementation

	do_send (conn: WS_STREAM_SOCKET; a_opcode:INTEGER; a_message: READABLE_STRING_8)
		local
			i: INTEGER
			l_chunk_size: INTEGER
			l_chunk: READABLE_STRING_8
			l_header_message: STRING
			l_message_count: INTEGER
			n: NATURAL_64
		do
			create l_header_message.make_empty
			l_header_message.append_code ((0x80 | a_opcode).to_natural_32)
			l_message_count := a_message.count
			n := l_message_count.to_natural_64
			if l_message_count >= 0xffff then
					--! Improve. this code needs to be checked.
				l_header_message.append_code ((0 | 127).to_natural_32)
				l_header_message.append_character ((n |>> 56).to_character_8)
				l_header_message.append_character ((n |>> 48).to_character_8)
				l_header_message.append_character ((n |>> 40).to_character_8)
				l_header_message.append_character ((n |>> 32).to_character_8)
				l_header_message.append_character ((n |>> 24).to_character_8)
				l_header_message.append_character ((n |>> 16).to_character_8)
				l_header_message.append_character ((n |>> 8).to_character_8)
				l_header_message.append_character ( n.to_character_8)
			elseif l_message_count > 125 then
				l_header_message.append_code ((0 | 126).to_natural_32)
				l_header_message.append_code ((n |>> 8).as_natural_32)
				l_header_message.append_character (n.to_character_8)
			else
				l_header_message.append_code (n.as_natural_32)
			end
--			l_header_message.append (a_message)
			conn.put_string (l_header_message)
--			conn.put_string (a_message)

			l_chunk_size := 16_384 -- 16K
			if l_message_count < l_chunk_size then
				conn.put_string (a_message)
			else
				from
					i := 0
				until
					l_chunk_size = 0
				loop
					print ("Sending chunk " + (i + 1).out + " -> " + (i + l_chunk_size).out +" / " + l_message_count.out + "%N")
					l_chunk := a_message.substring (i + 1, l_message_count.min (i + l_chunk_size))

--					if conn.ready_for_writing then
						conn.put_string (l_chunk)
--					else
--						l_chunk_size := 0
--					end						
					if l_chunk.count < l_chunk_size then
						l_chunk_size := 0
					end
					i := i + l_chunk_size
				end
				print ("Sending chunk done%N")
			end
		rescue
			io.put_string ("Press [ENTER] to continue")
			io.read_line
		end

end
