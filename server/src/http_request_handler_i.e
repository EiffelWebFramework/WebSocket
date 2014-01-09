note
	description: "Summary description for {HTTP_REQUEST_HANDLER_I}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

deferred class
	HTTP_REQUEST_HANDLER_I

inherit

	WEB_SOCKET_EVENT_I

	SHARED_BASE64

	HTTP_DEBUG_FACILITIES

	HTTP_CONSTANTS
		export
			{NONE} all
		end

feature {NONE} -- Initialization

	make
		do
			reset
		end

	reset
		do
			has_error := False
			version := Void
			remote_info := Void
			if attached client_socket as l_sock then
				l_sock.cleanup
			end
			client_socket := Void

				-- FIXME: optimize to just wipe_out if needed
			create method.make_empty
			create uri.make_empty
			create request_header.make_empty
			create request_header_map.make (10)
			is_handshake := False
			is_data_frame_ok := True
			close_description := [Normal_closure, "Normal close"]
			is_close := False
			is_incomplete_data := False
		end

feature -- Access

	is_verbose: BOOLEAN

	client_socket: detachable WS_STREAM_SOCKET

	request_header: STRING
			-- Header' source

	request_header_map: HASH_TABLE [STRING, STRING]
			-- Contains key:value of the header

	is_close: BOOLEAN

	has_error: BOOLEAN
			-- Error occurred during `analyze_request_message'

	close_description: TUPLE [code:INTEGER; description: STRING]

	method: STRING
			-- http verb

	uri: STRING
			--  http endpoint

	version: detachable STRING
			--  http_version
			--| unused for now

	remote_info: detachable TUPLE [addr: STRING; hostname: STRING; port: INTEGER]
			-- Information related to remote client

	is_handshake: BOOLEAN
			-- Is the handshake already done?

	is_incomplete_data: BOOLEAN

	is_data_frame_ok: BOOLEAN
			-- Is the last process data framing ok?

	is_binary: BOOLEAN
			-- Is the type of the message binary?

	opcode : INTEGER
		-- opcode of the message

feature -- Change

	set_client_socket (a_socket: separate WS_STREAM_SOCKET)
		require
			socket_attached: a_socket /= Void
			socket_valid: a_socket.is_open_read and then a_socket.is_open_write
			a_http_socket: not a_socket.is_closed
		deferred
		ensure
			attached client_socket as s implies s.descriptor = a_socket.descriptor
		end

	set_is_verbose (b: BOOLEAN)
		do
			is_verbose := b
		end


feature -- Execution

	execute
		local
			l_remote_info: detachable like remote_info
			exit: BOOLEAN
			l_client_message: STRING
			l_utf: UTF_CONVERTER
		do
			if attached client_socket as l_socket then
				debug ("dbglog")
					dbglog (generator + ".ENTER execute {" + l_socket.descriptor.out + "}")
				end

				from
				until
					 has_error or else exit
				loop
					if l_socket.ready_for_reading then
						debug ("dbglog")
							dbglog (generator + ".LOOP execute {" + l_socket.descriptor.out + "}")
						end
						create l_remote_info
						if attached l_socket.peer_address as l_addr then
							l_remote_info.addr := l_addr.host_address.host_address
							l_remote_info.hostname := l_addr.host_address.host_name
							l_remote_info.port := l_addr.port
							remote_info := l_remote_info
						end
						if not is_handshake then
							opening_handshake (l_socket)
							on_open (l_socket)
						else
							l_client_message := read_data_framing (l_socket)
							if is_binary then
								print ("%NPase 1")
								if is_data_frame_ok and then not is_close and then not is_incomplete_data then
									on_event (l_socket, l_client_message, opcode)
								else
									on_event (l_socket, l_client_message, opcode)
									exit := True
								end
							elseif l_utf.is_valid_utf_8_string_8 (l_client_message) then
								print ("%NPase 2")
								if is_data_frame_ok and then not is_close and then not is_incomplete_data then
									on_event (l_socket, l_client_message, opcode)
								else
									on_event (l_socket, l_client_message, opcode)
									exit := True
								end
							else
								print ("%NPase 3")
								on_event (l_socket, l_client_message, opcode)
								if is_close then
									exit := True
								end
							end
						end
					else
						log (generator + ".WAITING execute {" + l_socket.descriptor.out + "}")
					end
				end
			else
				check
					has_client_socket: False
				end
			end
			release
		rescue
			release
		end

	release
		do
			reset
		end

feature -- WebSockets

	read_data_framing (a_socket: WS_STREAM_SOCKET): STRING
			-- TODO Binary messages
			-- Handle error responses in a better way.
			-- IDEA:
			-- class FRAME
			-- 		is_fin: BOOLEAN
			--		opcode: WEB_SOCKET_STATUS_CODE (TEXT, BINARY, CLOSE, CONTINUE,PING, PONG)
			--		data/payload
			--      status_code: #see Status Codes http://tools.ietf.org/html/rfc6455#section-7.3
			--		has_error
			--
			--	See Base Framing Protocol: http://tools.ietf.org/html/rfc6455#section-5.2
			--      0                   1                   2                   3
			--      0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
			--     +-+-+-+-+-------+-+-------------+-------------------------------+
			--     |F|R|R|R| opcode|M| Payload len |    Extended payload length    |
			--     |I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
			--     |N|V|V|V|       |S|             |   (if payload len==126/127)   |
			--     | |1|2|3|       |K|             |                               |
			--     +-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
			--     |     Extended payload length continued, if payload len == 127  |
			--     + - - - - - - - - - - - - - - - +-------------------------------+
			--     |                               |Masking-key, if MASK set to 1  |
			--     +-------------------------------+-------------------------------+
			--     | Masking-key (continued)       |          Payload Data         |
			--     +-------------------------------- - - - - - - - - - - - - - - - +
			--     :                     Payload Data continued ...                :
			--     + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
			--     |                     Payload Data continued ...                |
			--     +---------------------------------------------------------------+			
		note
			EIS: "name=Unnamed", "protocol=URI", "src=http://www.yourwebsite.com"
		local
			l_opcode: INTEGER
			l_len: INTEGER
			l_payload_len: NATURAL_64
			l_utf: UTF_CONVERTER
			l_key: detachable STRING
			i: INTEGER
			l_frame: STRING
			l_rsv: BOOLEAN
			l_fin: BOOLEAN
			l_encoded: BOOLEAN
			l_remaining: BOOLEAN
			l_chunk_size: INTEGER
			l_byte: NATURAL_8
			s: STRING
		do
			create Result.make_empty
			from
			until
				l_fin or not is_data_frame_ok or is_incomplete_data
			loop
					-- multi-frames or continue is only valid for Binary or Text
				a_socket.read_stream (1)
				s := a_socket.last_string
				if s.is_empty then
					is_incomplete_data := True
					debug ("ws")
						print ("[ERROR] incomplete_data!%N")
					end
				else
					l_opcode := s[1].code
					debug ("ws")
						print (to_byte (l_opcode).out)
					end
					l_fin := l_opcode & (0b10000000) /= 0
					l_rsv := l_opcode & (0b01110000) = 0
					l_opcode := l_opcode & 0b00001111
					opcode := l_opcode
					log ("Standard Action:" + l_opcode.out)
					is_binary := l_opcode = binary_frame -- 2
					is_close := l_opcode = connection_close_frame -- 8
					inspect l_opcode
					when
						Continuation_frame, -- 0
						Text_frame, -- 1
						Binary_frame, -- 2
						Connection_close_frame, -- 8
						Ping_frame, -- 9
						Pong_frame -- 10
					then
							--| Known opcode
					else
						is_data_frame_ok := False
						close_description := [Protocol_error, "Unknown opcode"]
					end

						-- fin validation
					if is_data_frame_ok and not l_fin then
							-- Control frames (see Section 5.5) MAY be injected in the middle of
							-- a fragmented message.  Control frames themselves MUST NOT be fragmented.
							-- if the l_opcode is a control frame then there is an error!!!
							-- PING, PONG, CLOSE
						if l_opcode = Connection_close_frame or l_opcode = Ping_frame or l_opcode = Pong_frame then
							is_data_frame_ok := False
							close_description := [protocol_error, "Control frames themselves MUST NOT be fragmented."]
						end
					end

						-- rsv validation
					if is_data_frame_ok and not l_rsv then
						is_data_frame_ok := False
							-- RSV1, RSV2, RSV3:  1 bit each

							-- MUST be 0 unless an extension is negotiated that defines meanings
							-- for non-zero values.  If a nonzero value is received and none of
							-- the negotiated extensions defines the meaning of such a nonzero
							-- value, the receiving endpoint MUST _Fail the WebSocket
							-- Connection_

							-- FIXME: add support for extension ?
						is_data_frame_ok := False
						close_description := [protocol_error, "RSV values MUST be 0 unless an extension is negotiated that defines meanings for non-zero values"]
					end

						-- At the moment only TEXT, (pending Binary)
					if is_data_frame_ok then
						check
							known_opcode:  l_opcode = Continuation_frame -- 0
										or l_opcode = Text_frame -- 1
										or l_opcode = Binary_frame  -- 2
										or l_opcode = Connection_close_frame -- 8
										or l_opcode = Ping_frame -- 9
										or l_opcode = Pong_frame -- 10
						end

						if l_opcode = Text_frame or l_opcode = Binary_frame then
							a_socket.read_stream (1)
							s := a_socket.last_string
							if s.is_empty then
								is_incomplete_data := True
							else
								l_len := s[1].code
								debug ("ws")
									print (to_byte (l_len).out)
								end

								l_encoded :=  l_len & (0b10000000) /= 0 -- MASK
								l_len := l_len & 0b01111111 -- 7bits

--								a_socket.read_stream (1)
--								s := a_socket.last_string
--								if s.is_empty then
--									is_incomplete_data := True
--								else
--									l_byte := s[1].code.as_natural_8

								if l_len = 127 then  -- TODO proof of concept read 8 bytes.
										-- the following 8 bytes interpreted as a 64-bit unsigned integer (the
      									-- most significant bit MUST be 0) are the payload length.
      									-- Multibyte length quantities are expressed in network byte order.
									a_socket.read_stream (8) -- 64 bits
									s := a_socket.last_string
									if s.count < 8 then
										is_incomplete_data := True
									else
										l_payload_len := s[8].natural_32_code.to_natural_64
										l_payload_len := l_payload_len | (s[7].natural_32_code.to_natural_64 |<< 8)
										l_payload_len := l_payload_len | (s[6].natural_32_code.to_natural_64 |<< 16)
										l_payload_len := l_payload_len | (s[5].natural_32_code.to_natural_64 |<< 24)
										l_payload_len := l_payload_len | (s[4].natural_32_code.to_natural_64 |<< 32)
										l_payload_len := l_payload_len | (s[3].natural_32_code.to_natural_64 |<< 40)
										l_payload_len := l_payload_len | (s[2].natural_32_code.to_natural_64 |<< 48)
										l_payload_len := l_payload_len | (s[1].natural_32_code.to_natural_64 |<< 56)

										l_len := (s[6].code |<< 16) | (s[7].code |<< 8) | (s[8].code)
										if l_opcode = connection_close_frame or l_opcode = ping_frame or l_opcode = pong_frame then
											is_data_frame_ok := False
										end
									end
								elseif l_len = 126 then
									a_socket.read_stream (2) -- 16 bits
									s := a_socket.last_string
									if s.count < 2 then
										is_incomplete_data := True
									else
										l_payload_len := s[2].natural_32_code.to_natural_64
										l_payload_len := l_payload_len | (s[1].natural_32_code.to_natural_64 |<< 8)
										if l_opcode = connection_close_frame or l_opcode = ping_frame or l_opcode = pong_frame then
											is_data_frame_ok := False
										end
									end
								else
									l_payload_len := l_len.to_natural_64
								end

								if is_data_frame_ok and not is_incomplete_data then
									if l_encoded then
										a_socket.read_stream (4)
										l_key := a_socket.last_string
										is_incomplete_data := l_key.count < 4
									end
									if not is_incomplete_data then
										l_chunk_size := 1_024
										if l_payload_len > {INTEGER_32}.max_value.to_natural_64 then
												-- Issue .. to big to store in STRING
											is_data_frame_ok := False -- FIXME !!!
										else
											l_len := l_payload_len.as_integer_32
										end
										if l_len < l_chunk_size then
											l_chunk_size := l_len
										end

										from
										until
											l_remaining or l_len = 0 or not is_data_frame_ok
										loop
											a_socket.read_stream (l_chunk_size)
											l_frame := a_socket.last_string
												--  Masking
												--  http://tools.ietf.org/html/rfc6455#section-5.3

											if l_encoded and l_key /= Void then
												l_frame := unmask (l_frame, l_key)
											else
												check client_frame_should_always_be_encoded: False end
											end

											Result.append (l_frame)
											l_remaining := l_len <= Result.count
										end
										log (l_payload_len.out + " received <===============")
										log (Result)
									end
								end
							end
						end
					end
				end
			end
		end

	opening_handshake (a_socket: WS_STREAM_SOCKET)
			-- The opening handshake is intended to be compatible with HTTP-based
			-- server-side software and intermediaries, so that a single port can be
			-- used by both HTTP clients alking to that server and WebSocket
			-- clients talking to that server.  To this end, the WebSocket client's
			-- handshake is an HTTP Upgrade request:

			--    GET /chat HTTP/1.1
			--    Host: server.example.com
			--    Upgrade: websocket
			--    Connection: Upgrade
			--    Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
			--    Origin: http://example.com
			--    Sec-WebSocket-Protocol: chat, superchat
			--    Sec-WebSocket-Version: 13
		local
			l_sha1: SHA1
			l_key : STRING
			l_handshake: STRING
		do
			analyze_request_message (a_socket)
				-- Reading client's opening GT

				-- TODO extract to a validator handshake or something like that.
			log ("Receive <====================")
			log (request_header)
			if method.same_string ("GET") then --item MUST be GET
				if attached request_header_map.item (Sec_WebSocket_Key) as l_ws_key and then -- Sec-websocket-key must be present
					attached request_header_map.item ("Upgrade") as l_upgrade_key and then -- Upgrade header must be present with value websocket
					l_upgrade_key.is_case_insensitive_equal ("websocket") and then attached request_header_map.item ("Connection") as l_connection_key and then -- Connection header must be present with value Upgrade
					l_connection_key.has_substring ("Upgrade") and then attached request_header_map.item ("Sec-WebSocket-Version") as l_version_key and then -- Version header must be present with value 13
					l_version_key.is_case_insensitive_equal ("13") and then attached request_header_map.item ("Host") -- Host header must be present
				then
					log ("key " + l_ws_key)
						-- Sending the server's opening handshake
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
					log ("================> Send")
					log (l_handshake)
					a_socket.put_string (l_handshake)
					is_handshake := True -- the connection is in OPEN State.
				end
			end
			if not is_handshake then
				log ("Error!!!")
					-- If we cannot complete the handshake, then the server MUST stop processing the client's handshake and return an HTTP response with an
					-- appropriate error code (such as 400 Bad Request).
				has_error := True
				a_socket.put_string ("HTTP/1.1 400 Bad Request")
					-- For now a simple Bad Request!!!.
			end
		end



feature -- Parsing

	analyze_request_message (a_socket: WS_STREAM_SOCKET)
			-- Analyze message extracted from `a_socket' as HTTP request
		require
			input_readable: a_socket /= Void and then a_socket.is_open_read
		local
			end_of_stream: BOOLEAN
			pos, n: INTEGER
			line: detachable STRING
			k, val: STRING
			txt: STRING
			l_is_verbose: BOOLEAN
		do
			create txt.make (64)
			request_header := txt
			if a_socket.is_readable and then attached next_line (a_socket) as l_request_line and then not l_request_line.is_empty then
				txt.append (l_request_line)
				txt.append_character ('%N')
				analyze_request_line (l_request_line)
			else
				has_error := True
			end
			l_is_verbose := is_verbose
			if not has_error or l_is_verbose then
					-- if `is_verbose' we can try to print the request, even if it is a bad HTTP request
				from
					line := next_line (a_socket)
				until
					line = Void or end_of_stream
				loop
					n := line.count
					if l_is_verbose then
						log (line)
					end
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
						request_header_map.put (val, k)
					end
					txt.append (line)
					txt.append_character ('%N')
					if line.is_empty or else line [1] = '%R' then
						end_of_stream := True
					else
						line := next_line (a_socket)
					end
				end
			end
		end

	analyze_request_line (line: STRING)
			-- Analyze `line' as a HTTP request line
		require
			valid_line: line /= Void and then not line.is_empty
		local
			pos, next_pos: INTEGER
		do
			if is_verbose then
				log ("%N## Parse HTTP request line ##")
				log (line)
			end
			pos := line.index_of (' ', 1)
			method := line.substring (1, pos - 1)
			next_pos := line.index_of (' ', pos + 1)
			uri := line.substring (pos + 1, next_pos - 1)
			version := line.substring (next_pos + 1, line.count)
			has_error := method.is_empty
		end

	next_line (a_socket: WS_STREAM_SOCKET): detachable STRING
			-- Next line fetched from `a_socket' is available.
		require
			is_readable: a_socket.is_open_read
		do
			if a_socket.socket_ok  then
				a_socket.read_line_thread_aware
				Result := a_socket.last_string
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

feature -- Masking Data Client - Server

	unmask (a_frame: READABLE_STRING_8; a_key: READABLE_STRING_8): STRING
			--	 To convert masked data into unmasked data, or vice versa, the following
			--   algorithm is applied.  The same algorithm applies regardless of the
			--   direction of the translation, e.g., the same steps are applied to
			--   mask the data as to unmask the data.

			--   Octet i of the transformed data ("transformed-octet-i") is the XOR of
			--   octet i of the original data ("original-octet-i") with octet at index
			--   i modulo 4 of the masking key ("masking-key-octet-j"):

			--     j                   = i MOD 4
			--     transformed-octet-i = original-octet-i XOR masking-key-octet-j

			--   The payload length, indicated in the framing as frame-payload-length,
			--   does NOT include the length of the masking key.  It is the length of
			--   the "Payload data", e.g., the number of bytes following the masking
			--   key.
		note
			EIS: "name=Masking","src=http://tools.ietf.org/html/rfc6455#section-5.3", "protocol=uri"
		local
			l_frame: STRING
			i: INTEGER
		do
			l_frame := a_frame.twin
			from
				i := 1
			until
				i > l_frame.count
			loop
				l_frame [i] := (l_frame [i].code.to_integer_8.bit_xor (a_key [((i - 1) \\ 4) + 1].code.to_integer_8)).to_character_8
				i := i + 1
			end
			Result := l_frame
		end

feature -- Output

	logger: detachable separate HTTP_SERVER_LOGGER

	set_logger (a_logger: like logger)
		do
			logger := a_logger
		end

	log (m: STRING)
		do
			if attached logger as l_logger then
				separate_log (m, l_logger)
			else
				io.put_string (m + "%N")
			end
		end

	separate_log (m: STRING; a_logger: separate HTTP_SERVER_LOGGER)
		do
			a_logger.log (m)
		end

feature {NONE} -- Debug		

	to_byte (a_integer: INTEGER): ARRAY [INTEGER]
		require
			valid: a_integer >= 0 and then a_integer <= 255
		local
			l_val: INTEGER
			l_index: INTEGER
		do
			create Result.make_filled (0, 1, 8)
			from
				l_val := a_integer
				l_index := 8
			until
				l_val < 2
			loop
				Result.put (l_val \\ 2, l_index)
				l_val := l_val // 2
				l_index := l_index - 1
			end
			Result.put (l_val, l_index)
		end

invariant
	request_header_attached: request_header /= Void

note
	copyright: "2011-2013, Javier Velilla, Jocelyn Fiat and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"

end
