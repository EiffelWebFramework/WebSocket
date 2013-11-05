note
	description: "Summary description for {WEB_SOCKET_EVENT_I}."
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
			l_string: STRING
		do
			create l_message.make_empty
			if a_binary then
				l_message.append_code (130)
			else
				l_message.append_code (129)
			end

			if a_message.count > 65535 then
				l_message.append_code (127)
				l_message.append_code ((a_message.count |>> 16).as_natural_32)
				l_message.append_code ((a_message.count |>> 8).as_natural_32)
				l_message.append_code (a_message.count.to_character_8.code.as_natural_32)
			elseif a_message.count > 125  then
				l_message.append_code (126)
				l_message.append_code ((a_message.count |>> 8).as_natural_32)
				l_message.append_code (a_message.count.to_character_8.code.as_natural_32)
			else
				l_message.append_code (a_message.count.as_natural_32)
			end
			l_message.append (a_message)
			conn.send_message (l_message)
		end

	on_open (conn: TCP_STREAM_SOCKET)
			-- Called after handshake, indicates that a complete WebSocket connection has been established.
		require
			conn_attached: conn /= Void
			conn_valid: conn.is_open_read and then conn.is_open_write
		deferred
		end

	on_close (conn: TCP_STREAM_SOCKET; a_message: STRING)
			-- Called after the WebSocket connection is closed.
		require
			conn_attached: conn /= Void
			conn_valid: conn.is_open_read and then conn.is_open_write
		do
			conn.send_message (close_message)
		ensure
			ws_conn_closed: conn.is_closed
		end

	close_message: STRING
		do
			create Result.make_empty
			Result.append_code (136)
		end

end
