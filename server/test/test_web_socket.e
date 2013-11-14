note
	description: "[
		Eiffel tests that can be executed by testing tool.
	]"
	author: "EiffelStudio test wizard"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_WEB_SOCKET

inherit

	EQA_TEST_SET
		redefine
			on_prepare,
			on_clean
		select
			default_create
		end

	INET_ADDRESS_FACTORY
		rename
			default_create as default_create_iaf
		end

	INET_PROPERTIES
		rename
			default_create as default_create_ip
		end

feature {NONE} -- Events

	on_prepare
			-- <Precursor>
		do
		end

	on_clean
			-- <Precursor>
		do
		end

feature -- Test Reading the Client's Opening Handshake

	test_web_socket_connection
		local
			msg: STRING
			address: detachable INET_ADDRESS
		do
			address := create_from_name ("localhost")
			create ws_conn.make_client_by_address_and_port (address, 9090)
			ws_conn.set_connect_timeout (1000)
				-- Connect to the Server
			ws_conn.connect
			assert ("Connected", ws_conn.is_connected)
		end

	test_web_socket_good_header
			-- Valid handshake
		note
			EIS: "Reading the Client's Opening Handshake", "src=http://tools.ietf.org/html/rfc6455#section-4.2.1", "protocol=uri"
		local
			msg: STRING
			l_int: INTEGER
		do
			create ws_conn.make_client_by_port (9090, "127.0.0.1")
				-- Connect to the Server
			ws_conn.connect
			assert ("Connected", ws_conn.is_connected)
			client_handshake_ok.append (crlf)
			client_handshake_ok.append (crlf)
			send_message (client_handshake_ok)
			ws_conn.read_stream (1024 * 16)
			assert ("Data Received", ws_conn.last_string /= Void)
			assert ("Data Received", ws_conn.last_string.has_substring ("HTTP/1.1 101 Switching Protocols"))
			l_int := 8
			send_message (l_int.out)
			ws_conn.read_stream (1024 * 16)
			assert ("Data Received", ws_conn.last_string /= Void)
			ws_conn.close
		end


	test_web_socket_echo
			-- Valid handshake
		note
			EIS: "Reading the Client's Opening Handshake", "src=http://tools.ietf.org/html/rfc6455#section-4.2.1", "protocol=uri"
		local
			msg: STRING
			l_int: INTEGER
			l_addres: INET_ADDRESS
		do
			create ws_conn.make_client_by_port (80, "www.websocket.org")
				-- Connect to the Server
			ws_conn.connect
			assert ("Connected", ws_conn.is_connected)
			client_handshake_ok.append (crlf)
			client_handshake_ok.append (crlf)
			send_message (client_handshake_ok)
			ws_conn.read_stream (1024 * 16)
			assert ("Data Received", ws_conn.last_string /= Void)
			assert ("Data Received", ws_conn.last_string.has_substring ("HTTP/1.1 101 Switching Protocols"))
			l_int := 8
			send_message (l_int.out)
			ws_conn.read_stream (1024 * 16)
			assert ("Data Received", ws_conn.last_string /= Void)
			ws_conn.close
		end


	test_web_socket_multi_frame
			-- Multiframe
		note
			EIS: "Reading the Client's Opening Handshake", "src=http://tools.ietf.org/html/rfc6455#section-4.2.1", "protocol=uri"
		local
			msg: STRING
			l_int: INTEGER
			l_frame1: STRING
			l_frame2: STRING
		do
			create ws_conn.make_client_by_port (9090, "127.0.0.1")
				-- Connect to the Server
			ws_conn.connect
			assert ("Connected", ws_conn.is_connected)
			client_handshake_ok.append (crlf)
			client_handshake_ok.append (crlf)
			send_message (client_handshake_ok)
			ws_conn.read_stream (1024)
			assert ("Data Received", ws_conn.last_string /= Void)
			assert ("Data Received", ws_conn.last_string.has_substring ("HTTP/1.1 101 Switching Protocols"))
			l_frame1 := "Multi-frame message, first frame"
			create msg.make_empty
			msg.append_code (128)
			msg.append_code ((l_frame1.count.as_natural_32 ))
			msg.append ("1234")
			msg.append (masked ("1234",l_frame1))
			send_message (msg)
			l_frame2 := "End frame"
			create msg.make_empty
			msg.append_code (129)
			msg.append_code ((l_frame2.count.as_natural_32 ))
			msg.append ("1243")
			msg.append (masked ("1243",l_frame2))
			send_message (msg)
			ws_conn.read_stream (1024 * 16)
			assert ("Data Received", ws_conn.last_string /= Void)
			l_int := 136
			send_message (l_int.out)
			ws_conn.close
		end

	test_web_socket_wrong_method
			-- Send a POST method instead a GET
		note
			EIS: "Reading the Client's Opening Handshake", "src=http://tools.ietf.org/html/rfc6455#section-4.2.1", "protocol=uri"
		local
			msg: STRING
		do
			create ws_conn.make_client_by_port (9090, "127.0.0.1")
				-- Connect to the Server
			ws_conn.connect
			assert ("Connected", ws_conn.is_connected)
			client_handshake_wrong_method.append (crlf)
			client_handshake_wrong_method.append (crlf)
			send_message (client_handshake_wrong_method)
			ws_conn.read_stream (1024 * 16)
			assert ("Data Received", ws_conn.last_string /= Void)
			assert ("Data Received", ws_conn.last_string.has_substring ("HTTP/1.1 400 Bad Request"))
			ws_conn.close
		end

	test_web_socket_missing_upgrade
			-- Missing Upgrade: websocket header
		note
			EIS: "Reading the Client's Opening Handshake", "src=http://tools.ietf.org/html/rfc6455#section-4.2.1", "protocol=uri"
		local
			msg: STRING
		do
			create ws_conn.make_client_by_port (9090, "127.0.0.1")
				-- Connect to the Server
			ws_conn.connect
			assert ("Connected", ws_conn.is_connected)
			client_handshake_missing_upgrade.append (crlf)
			client_handshake_missing_upgrade.append (crlf)
			send_message (client_handshake_missing_upgrade)
			ws_conn.read_stream (1024 * 16)
			assert ("Data Received", ws_conn.last_string /= Void)
			assert ("Data Received", ws_conn.last_string.has_substring ("HTTP/1.1 400 Bad Request"))
			ws_conn.close
		end

	test_web_socket_wrong_upgrade
			-- Wrong Upgrade: wrong header
		note
			EIS: "Reading the Client's Opening Handshake", "src=http://tools.ietf.org/html/rfc6455#section-4.2.1", "protocol=uri"
		local
			msg: STRING
		do
			create ws_conn.make_client_by_port (9090, "127.0.0.1")
				-- Connect to the Server
			ws_conn.connect
			assert ("Connected", ws_conn.is_connected)
			client_handshake_wrong_upgrade.append (crlf)
			client_handshake_wrong_upgrade.append (crlf)
			send_message (client_handshake_wrong_upgrade)
			ws_conn.read_stream (1024 * 16)
			assert ("Data Received", ws_conn.last_string /= Void)
			assert ("Data Received", ws_conn.last_string.has_substring ("HTTP/1.1 400 Bad Request"))
			ws_conn.close
		end

	test_web_socket_missing_connection
			-- Missing Connection header
		note
			EIS: "Reading the Client's Opening Handshake", "src=http://tools.ietf.org/html/rfc6455#section-4.2.1", "protocol=uri"
		local
			msg: STRING
		do
			create ws_conn.make_client_by_port (9090, "127.0.0.1")
				-- Connect to the Server
			ws_conn.connect
			assert ("Connected", ws_conn.is_connected)
			client_handshake_missing_connection.append (crlf)
			client_handshake_missing_connection.append (crlf)
			send_message (client_handshake_missing_connection)
			ws_conn.read_stream (1024 * 16)
			assert ("Data Received", ws_conn.last_string /= Void)
			assert ("Data Received", ws_conn.last_string.has_substring ("HTTP/1.1 400 Bad Request"))
			ws_conn.close
		end


	test_web_socket_wrong_connection
			-- Wrong Connection header
		note
			EIS: "Reading the Client's Opening Handshake", "src=http://tools.ietf.org/html/rfc6455#section-4.2.1", "protocol=uri"
		local
			msg: STRING
		do
			create ws_conn.make_client_by_port (9090, "127.0.0.1")
				-- Connect to the Server
			ws_conn.connect
			assert ("Connected", ws_conn.is_connected)
			client_handshake_wrong_connection.append (crlf)
			client_handshake_wrong_connection.append (crlf)
			send_message (client_handshake_wrong_connection)
			ws_conn.read_stream (1024 * 16)
			assert ("Data Received", ws_conn.last_string /= Void)
			assert ("Data Received", ws_conn.last_string.has_substring ("HTTP/1.1 400 Bad Request"))
			ws_conn.close
		end

	test_web_socket_missing_version
			-- Missing version header
		note
			EIS: "Reading the Client's Opening Handshake", "src=http://tools.ietf.org/html/rfc6455#section-4.2.1", "protocol=uri"
		local
			msg: STRING
		do
			create ws_conn.make_client_by_port (9090, "127.0.0.1")
				-- Connect to the Server
			ws_conn.connect
			assert ("Connected", ws_conn.is_connected)
			client_handshake_missing_version.append (crlf)
			client_handshake_missing_version.append (crlf)
			send_message (client_handshake_missing_version)
			ws_conn.read_stream (1024 * 16)
			assert ("Data Received", ws_conn.last_string /= Void)
			assert ("Data Received", ws_conn.last_string.has_substring ("HTTP/1.1 400 Bad Request"))
			ws_conn.close
		end

	test_web_socket_wrong_version
			-- Wrong version header
		note
			EIS: "Reading the Client's Opening Handshake", "src=http://tools.ietf.org/html/rfc6455#section-4.2.1", "protocol=uri"
		local
			msg: STRING
		do
			create ws_conn.make_client_by_port (9090, "127.0.0.1")
				-- Connect to the Server
			ws_conn.connect
			assert ("Connected", ws_conn.is_connected)
			client_handshake_wrong_version.append (crlf)
			client_handshake_wrong_version.append (crlf)
			send_message (client_handshake_wrong_version)
			ws_conn.read_stream (1024 * 16)
			assert ("Data Received", ws_conn.last_string /= Void)
			assert ("Data Received", ws_conn.last_string.has_substring ("HTTP/1.1 400 Bad Request"))
			ws_conn.close
		end

	test_web_socket_missing_host
			-- Missgin HOST header
		note
			EIS: "Reading the Client's Opening Handshake", "src=http://tools.ietf.org/html/rfc6455#section-4.2.1", "protocol=uri"
		local
			msg: STRING
		do
			create ws_conn.make_client_by_port (9090, "127.0.0.1")
				-- Connect to the Server
			ws_conn.connect
			assert ("Connected", ws_conn.is_connected)
			client_handshake_missing_host.append (crlf)
			client_handshake_missing_host.append (crlf)
			send_message (client_handshake_missing_host)
			ws_conn.read_stream (1024 * 16)
			assert ("Data Received", ws_conn.last_string /= Void)
			assert ("Data Received", ws_conn.last_string.has_substring ("HTTP/1.1 400 Bad Request"))
			ws_conn.close
		end


feature -- Message

	send_message (a_msg: STRING)
		local
			a_package: PACKET
			a_data: MANAGED_POINTER
			c_string: C_STRING
		do
			create c_string.make (a_msg)
			create a_data.make_from_pointer (c_string.item, a_msg.count + 1)
			create a_package.make_from_managed_pointer (a_data)
			ws_conn.send (a_package, 1)
		end

	receive_data: STRING
		local
			end_of_stream: BOOLEAN
		do
			from
				ws_conn.read_stream (1024 * 16)
				Result := ""
			until
				end_of_stream
			loop
				if ws_conn.ready_for_reading then
					print ("%N" + ws_conn.last_string + "%N")
					Result.append (ws_conn.last_string)
					if ws_conn.last_string /= void and ws_conn.socket_ok then
						ws_conn.read_stream (1024 * 16)
					else
						end_of_stream := True
					end
				end
			end
		end

feature {NONE} -- implementation

	ws_conn: NETWORK_STREAM_SOCKET

	crlf: STRING = "%R%N"

	client_handshake_ok: STRING = "[
			GET /chat HTTP/1.1
			Host: server.example.com
			Upgrade: websocket
			Connection: Upgrade
			Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
			Origin: http://example.com
			Sec-WebSocket-Protocol: chat, superchat
			Sec-WebSocket-Version: 13
		]"

	client_handshake_wrong_method: STRING = "[
			POST /chat HTTP/1.1
			Host: server.example.com
			Upgrade: websocket
			Connection: Upgrade
			Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
			Origin: http://example.com
			Sec-WebSocket-Protocol: chat, superchat
			Sec-WebSocket-Version: 13
		]"

	client_handshake_missing_upgrade: STRING = "[
			GET /chat HTTP/1.1
			Host: server.example.com
			Connection: Upgrade
			Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
			Origin: http://example.com
			Sec-WebSocket-Protocol: chat, superchat
			Sec-WebSocket-Version: 13
		]"

	client_handshake_wrong_upgrade: STRING = "[
			GET /chat HTTP/1.1
			Host: server.example.com
			Upgrade: wrong
			Connection: Upgrade
			Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
			Origin: http://example.com
			Sec-WebSocket-Protocol: chat, superchat
			Sec-WebSocket-Version: 13
		]"

	client_handshake_missing_connection: STRING = "[
			GET /chat HTTP/1.1
			Host: server.example.com
			Upgrade: websocket
			Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
			Origin: http://example.com
			Sec-WebSocket-Protocol: chat, superchat
			Sec-WebSocket-Version: 13
		]"

	client_handshake_wrong_connection: STRING = "[
			GET /chat HTTP/1.1
			Host: server.example.com
			Upgrade: websocket
			Connection: wrong
			Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
			Origin: http://example.com
			Sec-WebSocket-Protocol: chat, superchat
			Sec-WebSocket-Version: 13
		]"

	client_handshake_missing_version: STRING = "[
			GET /chat HTTP/1.1
			Host: server.example.com
			Upgrade: websocket
			Connection: Upgrade
			Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
			Origin: http://example.com
			Sec-WebSocket-Protocol: chat, superchat
		]"


	client_handshake_wrong_version: STRING = "[
			GET /chat HTTP/1.1
			Host: server.example.com
			Upgrade: websocket
			Connection: Upgrade
			Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
			Origin: http://example.com
			Sec-WebSocket-Protocol: chat, superchat
			Sec-WebSocket-Version: 11
		]"

	client_handshake_missing_host: STRING = "[
			GET /chat HTTP/1.1
			Upgrade: websocket
			Connection: Upgrade
			Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
			Origin: http://example.com
			Sec-WebSocket-Protocol: chat, superchat
			Sec-WebSocket-Version: 13
		]"


	masked (a_key: STRING; a_frame: STRING): STRING
		local
			l_key: STRING
			l_frame: STRING
			i: INTEGER
			l_utf: UTF_CONVERTER
		do
			create Result.make_empty
			l_key := a_key
			l_frame := a_frame
			from
				i := 1
			until
				i > l_frame.count
			loop
				l_frame [i] := (l_frame [i].code.to_integer_8.bit_xor (l_key [((i - 1) \\ 4) + 1].code.to_integer_8)).to_character_8
				i := i + 1
			end
			Result.append (l_utf.string_32_to_utf_8_string_8 (l_frame))
		end

end
