note
	description : "WebSocket server prototype"
	author: "Olivier Ligot"

class
	WS_SERVER

inherit
	SHARED_BASE64

create
	make

feature {NONE} -- Initialization

	make
			-- Run application.
		local
			l_socket: NETWORK_STREAM_SOCKET
		do
			create l_socket.make_server_by_port (port)
			if not l_socket.is_bound then
				log ("Socket could not be bound on port " + port.out)
			else
				from
					l_socket.listen (100)
					log ("Server listening on port " + port.out)
				until
					False
				loop
					l_socket.accept
					if attached l_socket.accepted as l_accepted_socket then
						process_connection (l_accepted_socket)
					end
				end
				l_socket.cleanup
			end
		end

feature {NONE} -- Implementation

	port: INTEGER = 9999
			-- Port number

	Magic_guid: STRING = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

	log (a_message: READABLE_STRING_8)
			-- Log `a_message'
		do
			io.put_string (a_message)
			io.put_new_line
		end

	process_connection (a_socket: NETWORK_STREAM_SOCKET)
			-- Process incoming connection.
		local
			l_parser: HTTP_REQUEST_PARSER
			l_sha1: SHA1
			l_key, l_handshake: STRING
			l_thread: WS_THREAD
		do
			create l_parser.make
			l_parser.enable_verbose
			l_parser.parse (a_socket)
			if not l_parser.has_error and attached l_parser.header_map.item ("Sec-WebSocket-Key") as l_ws_key then
				log ("key " + l_ws_key)
				l_ws_key.append_string (Magic_guid)
				create l_sha1.make
				l_sha1.update_from_string (l_ws_key)
				l_key := Base64_encoder.encoded_string (digest (l_sha1))
				create l_handshake.make_from_string ("HTTP/1.1 101 Switching Protocols%R%N")
			    l_handshake.append_string ("Upgrade: websocket%R%N")
			    l_handshake.append_string ("Connection: Upgrade%R%N")
			    l_handshake.append_string ("Sec-WebSocket-Accept: ")
			    l_handshake.append_string (l_key)
			    l_handshake.append_string ("%R%N")
			    -- end of header empty line
			    l_handshake.append_string ("%R%N")
			    io.put_new_line
			    log (l_handshake)
			    a_socket.put_string (l_handshake)
			    create l_thread.make (a_socket)
			    l_thread.launch
			end
		end

	digest (a_sha1: SHA1): STRING
			-- Digest of `a_sha1'.
			-- Should by in SHA1 class
		local
			l_digest: SPECIAL [NATURAL_8]
			index, l_upper: INTEGER
		do
			l_digest := a_sha1.digest
			create Result.make (l_digest.count // 2)
			from
				index := l_digest.Lower
				l_upper := l_digest.upper
			until
				index > l_upper
			loop
				Result.append_character (l_digest [index].to_character_8)
				index := index + 1
			end
		end

end
