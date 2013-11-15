note
	description: "[
		API to perform actions like opening and closing the connection, sending and receiving messages, and listening
		for events triggered by the server
	]"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	WEB_SOCKET_CLIENT

inherit

	WEB_SOCKET_SUBSCRIBER
		redefine
			on_websocket_error,
			on_websocket_text_message,
			on_websocket_binary_message,
			on_websocket_close,
			on_websocket_open

		end

	WEB_SOCKET

	THREAD
		rename
			make as thread_make
		end

feature -- Initialization

	initialize (a_uri: READABLE_STRING_GENERAL)
			-- Initialize websocket client
		require
			is_valid_uri: is_valid_uri (a_uri)
		do
			thread_make
			uri := a_uri
			set_default_port
			create ready_state.make
			create socket.make_client_by_port (port, host)
			create server_handshake.make
		end

	initialize_with_port (a_uri: READABLE_STRING_GENERAL; a_port: INTEGER)
			-- Initialize websocket client
		require
			is_valid_uri: is_valid_uri (a_uri)
		do
			thread_make
			uri := a_uri
			port := a_port
			create ready_state.make
			create socket.make_client_by_port (port, host)
			create server_handshake.make
		end

feature -- Access

	socket: TCP_STREAM_SOCKET
			-- Socket

	has_error: BOOLEAN
		do
			Result := implementation.has_error
		end

	is_server_hanshake_accpeted : BOOLEAN

	is_valid_uri (a_uri: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_uri' a valid URI?
		local
			l_uri: URI
		do
			create l_uri.make_from_string (a_uri.as_string_8)
			Result := l_uri.is_valid
		end

	server_handshake: WEB_SOCKET_HANDSHAKE_DATA
			-- Handshake data received from the server

feature -- Events API

	on_open (a_message: STRING)
		deferred
		end

	on_text_message (a_message: STRING)
		deferred
		end

	on_binary_message (a_message: STRING)
		deferred
		end

	on_close (a_code: INTEGER; a_reason: STRING)
		deferred
		end

	on_error (a_error: STRING)
		deferred
		end

feature -- Subscriber Events

	on_websocket_handshake (a_request: STRING)
			-- Send handshake message
		do
			socket.send_message (a_request)
		end


	on_websocket_text_message (a_message: STRING)
		do
			on_text_message (a_message)
		end

	on_websocket_binary_message(a_message: STRING)
		do
			on_binary_message (a_message)
		end

	on_websocket_open (a_message: STRING)
		do
			on_open (a_message)
		end


	on_websocket_close (a_message: STRING)
		do
			on_close (1,a_message) -- TODO fix
		end

	on_websocket_error (a_error: STRING)
		do
			on_error (a_error)
		end



feature -- Execute

	execute
		require else
			is_socket_valid: socket.exists
		do
			set_implementation
			socket.connect
			check
				socket_connected: socket.is_connected
			end
			send_handshake
			receive_handshake
			if is_server_hanshake_accpeted then
				ready_state.set_state ({WEB_SOCKET_READY_STATE}.open)
				on_websocket_open ("Open Connection")
				from

				until
					ready_state.is_closed or has_error
				loop
					receive
				end
			else
				on_websocket_error ("Server Handshake not accepted")
				--log(Not connected)
				socket.close
			end
		rescue
			socket.close
		end


feature -- Methods

	send (a_message: STRING)
		local
			l_message: STRING
		do
			create l_message.make_empty
			l_message.append_code (129)
			do_send (l_message, a_message)
		end

	send_binary (a_message : STRING)
		local
			l_message: STRING
		do
			create l_message.make_empty
			l_message.append_code (130)
			do_send (l_message, a_message)
		end

	close (a_id: INTEGER)
			-- Close a websocket connection with a close id : `a_id'
		local
			l_message: STRING
		do
			create l_message.make_empty
			l_message.append_code (136)
			socket.put_string (l_message)
			ready_state.set_state ({WEB_SOCKET_READY_STATE}.closed)
			socket.close
		end

	close_with_description (a_id: INTEGER; a_description: READABLE_STRING_GENERAL)
			-- Close a websocket connection with a close id : `a_id' and a description `a_description'
		do
		end

feature {NONE} -- Implementation

	set_implementation
		do
			create implementation.make_with_port (Current, host, port)
		end

	send_handshake
		local
			l_uri: URI
			l_data: WEB_SOCKET_HANDSHAKE_DATA
			l_handshake: STRING
			l_random: SALT_XOR_SHIFT_64_GENERATOR
		do
			create l_uri.make_from_string (uri.as_string_8)
			create l_handshake.make_empty
			if l_uri.path.is_empty then
				l_handshake.append ("GET / HTTP/1.1")
				l_handshake.append (crlf)
			else
				l_handshake.append ("GET "+ l_uri.path+ " HTTP/1.1")
				l_handshake.append (crlf)
			end

			if attached l_uri.host as l_host then
				l_handshake.replace_substring_all ("$host", l_host)
				l_handshake.append ("Host: "+ l_host)
				l_handshake.append (crlf)
			end

			l_handshake.append_string ("Upgrade: websocket")
			l_handshake.append (crlf)
			l_handshake.append_string ("Connection: Upgrade")
			l_handshake.append (crlf)
			l_handshake.append_string ("Sec-WebSocket-Key: ")
			create l_random.make (16)
			l_handshake.append_string (base64_encode_array (l_random.new_sequence))
			l_handshake.append (crlf)
			l_handshake.append_string ("Sec-WebSocket-Version: 13")
			l_handshake.append (crlf)
			l_handshake.append (crlf)
			implementation.start_handshake (l_handshake)
		end

	receive_handshake
		do
			analyze_request_message
			if server_handshake.request_header.has_substring ("HTTP/1.1 101 Switching Protocols") and then attached server_handshake.request_header_map.item ("Upgrade") as l_upgrade_key and then -- Upgrade header must be present with value websocket
				l_upgrade_key.is_case_insensitive_equal ("websocket") and then attached server_handshake.request_header_map.item ("Connection") as l_connection_key and then -- Connection header must be present with value Upgrade
				l_connection_key.has_substring ("Upgrade")
			then
				is_server_hanshake_accpeted := True
			end
		end

	receive
		do
			implementation.receive
		end

	set_default_port
		do
			if is_tunneled then
				port := wss_port_default
			else
				port := ws_port_default
			end
		end

	client_handshake_required_template: STRING = "[
			GET $resource HTTP/1.1
			Host: $host
			Upgrade: websocket
			Connection: Upgrade
			Sec-WebSocket-Key: $key
			Sec-WebSocket-Version: 13
		]"

	base64_encode_array (a_sequence: ARRAY [NATURAL_8]): STRING_8
			-- Encode a byte array `a_sequence' into Base64 notation.
		local
			l_result: STRING
			l_base_64: BASE64
		do
			create l_result.make_empty
			across
				a_sequence as i
			loop
				l_result.append_character (i.item.to_character_8)
			end
			create l_base_64
			Result := l_base_64.encoded_string (l_result)
		end

	host: STRING
		local
			l_uri: URI
		do
			create Result.make_empty
			create l_uri.make_from_string (uri.as_string_8)
			if attached l_uri.host as l_host then
				Result := l_host
			end
		end

feature -- Parse Request line

	analyze_request_message
			-- Analyze message extracted from `socket' as HTTP request
		require
			input_readable: socket /= Void and then socket.is_open_read
		local
			end_of_stream: BOOLEAN
			pos, n: INTEGER
			line: detachable STRING
			k, val: STRING
			txt: STRING
			l_is_verbose: BOOLEAN
		do
			create txt.make (64)
			server_handshake.set_request_header (txt)
			if attached next_line as l_request_line and then not l_request_line.is_empty then
				txt.append (l_request_line)
				txt.append_character ('%N')
			else
				server_handshake.mark_error
			end
				--			l_is_verbose := is_verbose
			if not server_handshake.has_error then -- or l_is_verbose then
					-- if `is_verbose' we can try to print the request, even if it is a bad HTTP request
				from
					line := next_line
				until
					line = Void or end_of_stream
				loop
					n := line.count
						--					if l_is_verbose then
						--						log (line)
						--					end
					pos := line.index_of (':', 1)
					if pos > 0 then
						k := line.substring (1, pos - 1)
						if line [pos + 1].is_space then
							pos := pos + 1
						end
						if line [n] = '%R' then
							n := n - 1
						end
						val := line.substring (pos + 1, n)
						server_handshake.put_header (k, val)
					end
					txt.append (line)
					txt.append_character ('%N')
					if line.is_empty or else line [1] = '%R' then
						end_of_stream := True
					else
						line := next_line
					end
				end
			end
		end

	next_line: detachable STRING
			-- Next line fetched from `socket' is available.
		require
			is_readable: socket.is_open_read
		do
			if socket.socket_ok and then socket.ready_for_reading then
				socket.read_line_thread_aware
				Result := socket.last_string
			end
		end

feature -- {WEB_SOCKET_CLIENT}

	do_send (a_header_message: STRING; a_message: STRING)
		local
			l_chunks: INTEGER
			i: INTEGER
			l_index: INTEGER
			l_chunk_size: INTEGER
			l_key: STRING
			l_message: STRING
		do
			if (a_message.count + 128) > 65535 then
					--!Improve. this code need to be checked.
				a_header_message.append_code (127)
				a_header_message.append_code (0)
				a_header_message.append_code (0)
				a_header_message.append_code (0)
				a_header_message.append_code (0)
				a_header_message.append_code (0)
				a_header_message.append_code (((a_message.count + 128) |>> 16).to_character_8.code.as_natural_32)
				a_header_message.append_code (((a_message.count + 128) |>> 8).to_character_8.code.as_natural_32)
				a_header_message.append_code ((a_message.count + 128).to_character_8.code.as_natural_32)
			elseif a_message.count > 125 then
				a_header_message.append_code (126)
				a_header_message.append_code (((a_message.count + 128) |>> 8).as_natural_32)
				a_header_message.append_code ((a_message.count+128).to_character_8.code.as_natural_32)
			else
				a_header_message.append_code ((a_message.count + 128).as_natural_32)
			end

			l_key := new_key
			a_header_message.append (l_key.substring(1,4))

			l_message := implementation.unmmask (a_message, l_key.substring(1,4))
			a_header_message.append (l_message)
			socket.send_message (a_header_message)
		end


	new_key : STRING
		local
			l_random: SALT_XOR_SHIFT_64_GENERATOR
		do
			create Result.make_empty
			create l_random.make (4)
			across l_random.new_sequence as i loop
				Result.append_integer (i.item)
			end
		end

	implementation: WEB_SOCKET_IMPL
			-- Web Socket implementation

	crlf: STRING = "%R%N"

end
