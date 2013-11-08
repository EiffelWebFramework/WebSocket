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

	on_message (conn: TCP_STREAM_SOCKET; a_message: STRING; a_opcode: INTEGER)
			-- Called when a frame from the client has been receive
		require
			conn_attached: conn /= Void
			conn_valid: conn.is_open_read and then conn.is_open_write
		local
			l_message: STRING
		do
			create l_message.make_empty
			if a_opcode = Binary_frame then
				l_message.append_code (130)
				do_send (conn, l_message, a_message)
			elseif a_opcode = Text_frame then
				l_message.append_code (129)
				do_send (conn, l_message, a_message)
			elseif a_opcode = Pong_frame then
				-- log ("Its a pong frame")
				-- at first we ingore  pong
			elseif a_opcode = Ping_frame then
				l_message.append_code (138)         -- reply a Ping with a Pong
				do_send (conn, l_message, a_message)
			end
		end

	on_open (conn: TCP_STREAM_SOCKET)
			-- Called after handshake, indicates that a complete WebSocket connection has been established.
		require
			conn_attached: conn /= Void
			conn_valid: conn.is_open_read and then conn.is_open_write
		deferred
		end

	on_close (conn: TCP_STREAM_SOCKET)
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
			Result.append_code (136)
		end

feature {NONE} -- Implementation

	do_send (conn: TCP_STREAM_SOCKET; a_header_message: STRING; a_message: STRING)
		local
			l_chunks: INTEGER
			i: INTEGER
			l_index: INTEGER
			l_chunk_size: INTEGER
		do
			if a_message.count > 65535 then
					--!Improve. this code need to be checked.
				a_header_message.append_code (127)
				a_header_message.append_code (0)
				a_header_message.append_code (0)
				a_header_message.append_code (0)
				a_header_message.append_code (0)
				a_header_message.append_code (0)
				a_header_message.append_code ((a_message.count |>> 16).to_character_8.code.as_natural_32)
				a_header_message.append_code ((a_message.count |>> 8).to_character_8.code.as_natural_32)
				a_header_message.append_code (a_message.count.to_character_8.code.as_natural_32)
			elseif a_message.count > 125 then
				a_header_message.append_code (126)
				a_header_message.append_code ((a_message.count |>> 8).as_natural_32)
				a_header_message.append_code (a_message.count.to_character_8.code.as_natural_32)
			else
				a_header_message.append_code (a_message.count.as_natural_32)
			end
			conn.put_string (a_header_message)
			l_chunk_size := 1024
			if a_message.count < l_chunk_size then
				conn.put_string (a_message)
			else
				l_chunks := a_message.count // l_chunk_size
				from
					i := 1
					l_index := 1
				until
					i > l_chunks + 1
				loop
					if conn.ready_for_writing and then i <= l_chunks then
						conn.put_string (a_message.substring (l_index, l_chunk_size * i))
						l_index := l_chunk_size * i + 1
						i := i + 1
					else
						if l_index < a_message.count then
							conn.put_string (a_message.substring (l_index, a_message.count))
						end
						i := i + 1
					end
				end
			end
		end

end
