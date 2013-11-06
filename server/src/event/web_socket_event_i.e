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

	on_message (conn: TCP_STREAM_SOCKET; a_message: STRING; a_binary: BOOLEAN)
			-- Called when a frame from the client has been receive
		require
			conn_attached: conn /= Void
			conn_valid: conn.is_open_read and then conn.is_open_write
		local
			l_message: STRING
			l_chunks: INTEGER
			i : INTEGER
			l_index: INTEGER
			l_chunk_size: INTEGER
			env: EXECUTION_ENVIRONMENT
		do
			create env
			create l_message.make_empty
			if a_binary then
				l_message.append_code (130)
			else
				l_message.append_code (129)
			end
			if a_message.count > 65535 then
					--!Improve. this code need to be checked.
				l_message.append_code (127)
				l_message.append_code (0)
				l_message.append_code (0)
				l_message.append_code (0)
				l_message.append_code (0)
				l_message.append_code (0)
				l_message.append_code ((a_message.count |>> 16).to_character_8.code.as_natural_32)
				l_message.append_code ((a_message.count |>> 8).to_character_8.code.as_natural_32)
				l_message.append_code (a_message.count.to_character_8.code.as_natural_32)
			elseif a_message.count > 125 then
				l_message.append_code (126)
				l_message.append_code ((a_message.count |>> 8).as_natural_32)
				l_message.append_code (a_message.count.to_character_8.code.as_natural_32)
			else
				l_message.append_code (a_message.count.as_natural_32)
			end
--			l_message.append (a_message) -- Todo send the message as chunks
		
		    conn.put_string (l_message)
			l_chunk_size := 1024
			if a_message.count < l_chunk_size  then
				conn.put_string (a_message)
			else
				l_chunks := a_message.count // l_chunk_size
				from
					i := 1
					l_index:= 1
				until
					i > l_chunks + 1
				loop
					if conn.ready_for_writing and then i <= l_chunks then
						conn.put_string (a_message.substring (l_index, l_chunk_size*i))
						l_index := l_chunk_size*i + 1
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

end
