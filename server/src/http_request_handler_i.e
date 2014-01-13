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
			close_description := [Normal_closure, "Normal close"]
		end

feature -- Access

	is_verbose: BOOLEAN

	client_socket: detachable WS_STREAM_SOCKET

	request_header: STRING
			-- Header' source

	request_header_map: HASH_TABLE [STRING, STRING]
			-- Contains key:value of the header

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
			l_frame: detachable WS_FRAME
			l_client_message: detachable READABLE_STRING_8
			l_utf: UTF_CONVERTER
		do
			if attached client_socket as l_socket then
				debug ("dbglog")
					dbglog (generator + ".ENTER execute {" + l_socket.descriptor.out + "}")
				end

					-- Set socket mode as "blocking", this simplifies the code
					-- and in protocol based communication, the number of bytes to read
					-- is always known.
				l_socket.set_blocking

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
							l_frame := next_frame (l_socket)

							if l_frame /= Void and then l_frame.is_valid then
								if attached l_frame.injected_control_frames as l_injections then
										-- Process injected control frames now.
										-- FIXME
									across
										l_injections as ic
									loop
										if ic.item.is_connection_close then
												-- FIXME: we should probably send this event .. after the `l_frame.parent' frame event.
											on_event (l_socket, ic.item.payload_data, ic.item.opcode)
		                      				exit := True
		                      			elseif ic.item.is_ping then
		                      					-- FIXME reply only to the most recent ping ...
		                      				on_event (l_socket, ic.item.payload_data, ic.item.opcode)
		                      			else
		                      				on_event (l_socket, ic.item.payload_data, ic.item.opcode)
										end
									end
								end

								l_client_message := l_frame.payload_data
								if l_client_message = Void then
									l_client_message := ""
								end

								debug ("ws")
									print("%NExecute: %N")
									print (" [opcode: "+ opcode_name (l_frame.opcode) +"]%N")
									if l_frame.is_text then
										print (" [client message: %""+ l_client_message +"%"]%N")
									elseif l_frame.is_binary then
										print (" [client binary message length: %""+ l_client_message.count.out +"%"]%N")
									end
									print (" [is_control: " + l_frame.is_control.out + "]%N")
									print (" [is_binary: " + l_frame.is_binary.out + "]%N")
									print (" [is_text: " + l_frame.is_text.out + "]%N")
								end

								if l_frame.is_connection_close then
									on_event (l_socket, l_client_message, l_frame.opcode)
                      				exit := True
								elseif l_frame.is_binary then
 									on_event (l_socket, l_client_message, l_frame.opcode)
 								elseif l_frame.is_text then
	 								check is_valid_utf_8: l_utf.is_valid_utf_8_string_8 (l_client_message) end
	 								on_event (l_socket, l_client_message, l_frame.opcode)
	 							else
	 								on_event (l_socket, l_client_message, l_frame.opcode)
	 							end
 							else
								debug ("ws")
									print("%NExecute: %N")
									print (" [ERROR: invalid frame]%N")
									if l_frame /= Void and then attached l_frame.error as err then
										print (" [Code: "+ err.code.out +"]%N")
										print (" [Description: "+ err.description +"]%N")
									end
								end
								on_event (l_socket, "", connection_close_frame)
 								exit := True
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

	next_frame (a_socket: WS_STREAM_SOCKET): detachable WS_FRAME
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
			EIS: "name=WebSocket RFC", "protocol=URI", "src=http://tools.ietf.org/html/rfc6455#section-5.2"
		require
			a_socket_in_blocking_mode: a_socket.is_blocking
		local
			l_opcode: INTEGER
			l_len: INTEGER
			l_remaining_len: INTEGER
			l_payload_len: NATURAL_64
--			l_utf: UTF_CONVERTER
			l_masking_key: detachable READABLE_STRING_8
--			i: INTEGER
			l_chunk: STRING
			l_rsv: BOOLEAN
			l_fin: BOOLEAN
			l_has_mask: BOOLEAN
			l_chunk_size: INTEGER
			l_byte: INTEGER
			s: STRING
			is_data_frame_ok: BOOLEAN -- Is the last process data framing ok?

--			is_close: BOOLEAN
--			is_incomplete_data: BOOLEAN
--			is_binary: BOOLEAN
--					-- Is the type of the message binary?				
			retried: BOOLEAN
		do
			if not retried then
				debug ("ws")
					print ("next_frame:%N")
				end

				from
					is_data_frame_ok := True
				until
					l_fin or not is_data_frame_ok
				loop
						-- multi-frames or continue is only valid for Binary or Text
					a_socket.read_stream (1)
					s := a_socket.last_string
					if s.is_empty then
						is_data_frame_ok := False
						debug ("ws")
							print ("[ERROR] incomplete_data!%N")
						end
					else
						l_byte := s[1].code
						debug ("ws")
							print ("   fin,rsv(3),opcode(4)=")
							print (to_byte_representation (l_byte))
							print ("%N")
						end
						l_fin := l_byte & (0b10000000) /= 0
						l_rsv := l_byte & (0b01110000) = 0
						l_opcode := l_byte & 0b00001111

						if Result /= Void then
							if l_opcode = Result.opcode then
								check
										-- should not occur in multi-fragment frame!
									should_not_occur: False
								end
								Result.report_error (protocol_error, "Unexpected frame")
							elseif l_opcode = continuation_frame then
									-- Expected
							elseif is_control_frame (l_opcode) then
									-- Control frames (see Section 5.5) MAY be injected in the middle of
									-- a fragmented message.  Control frames themselves MUST NOT be fragmented.
									-- if the l_opcode is a control frame then there is an error!!!
									-- CLOSE, PING, PONG
								create Result.make_as_injected_control (l_opcode, Result)
							else
								check
										-- should not occur in multi-fragment frame!
									should_not_occur: False
								end
								Result.report_error (protocol_error, "Unexpected frame")
							end
						else
							create Result.make (l_opcode, l_fin)
						end

						log ("%NStandard Action:" + opcode_name (l_opcode))

						if Result.is_valid then
								--| valid frame/fragment

								-- rsv validation
							if not l_rsv then
									-- RSV1, RSV2, RSV3:  1 bit each

									-- MUST be 0 unless an extension is negotiated that defines meanings
									-- for non-zero values.  If a nonzero value is received and none of
									-- the negotiated extensions defines the meaning of such a nonzero
									-- value, the receiving endpoint MUST _Fail the WebSocket
									-- Connection_

									-- FIXME: add support for extension ?
								Result.report_error (protocol_error, "RSV values MUST be 0 unless an extension is negotiated that defines meanings for non-zero values")
							end
						end

							-- At the moment only TEXT, (pending Binary)
						if Result.is_valid then
							if Result.is_text or Result.is_binary or Result.is_control then
										-- Reading next byte (mask+payload_len)
								a_socket.read_stream (1)
								s := a_socket.last_string
								if s.is_empty then
									Result.report_error (invalid_data, "Incomplete data for mask and payload len")
								else
									l_byte := s[1].code
									debug ("ws")
										print ("   mask,payload_len(7)=")
										print (to_byte_representation (l_byte))
										io.put_new_line
									end
									l_has_mask :=  l_byte & (0b10000000) /= 0 -- MASK
									l_len := l_byte & 0b01111111 -- 7bits

									debug ("ws")
										print ("   payload_len=" + l_len.out)
										io.put_new_line
									end

									if Result.is_control and then l_len > 125 then
											-- All control frames MUST have a payload length of 125 bytes or less
	   										-- and MUST NOT be fragmented.
										Result.report_error (protocol_error, "Control frame MUST have a payload length of 125 bytes or less")
									elseif l_len = 127 then  -- TODO proof of concept read 8 bytes.
											-- the following 8 bytes interpreted as a 64-bit unsigned integer
											-- (the most significant bit MUST be 0) are the payload length.
	      									-- Multibyte length quantities are expressed in network byte order.
	      								s := next_bytes (a_socket, 8) -- 64 bits
										debug ("ws")
											print ("   extended payload length=" + string_to_byte_representation (s))
											io.put_new_line
										end
										if s.count < 8 then
											Result.report_error (Invalid_data, "Incomplete data for 64 bit Extended payload length")
										else
											l_payload_len := s[8].natural_32_code.to_natural_64
											l_payload_len := l_payload_len | (s[7].natural_32_code.to_natural_64 |<< 8)
											l_payload_len := l_payload_len | (s[6].natural_32_code.to_natural_64 |<< 16)
											l_payload_len := l_payload_len | (s[5].natural_32_code.to_natural_64 |<< 24)
											l_payload_len := l_payload_len | (s[4].natural_32_code.to_natural_64 |<< 32)
											l_payload_len := l_payload_len | (s[3].natural_32_code.to_natural_64 |<< 40)
											l_payload_len := l_payload_len | (s[2].natural_32_code.to_natural_64 |<< 48)
											l_payload_len := l_payload_len | (s[1].natural_32_code.to_natural_64 |<< 56)
										end
									elseif l_len = 126 then
										s := next_bytes (a_socket, 2) -- 16 bits
										debug ("ws")
											print ("   extended payload length bits=" + string_to_byte_representation (s))
											io.put_new_line
										end
										if s.count < 2 then
											Result.report_error (Invalid_data, "Incomplete data for 16 bit Extended payload length")
										else
											l_payload_len := s[2].natural_32_code.to_natural_64
											l_payload_len := l_payload_len | (s[1].natural_32_code.to_natural_64 |<< 8)
										end
									else
										l_payload_len := l_len.to_natural_64
									end
									debug ("ws")
										print ("   Full payload length=" + l_payload_len.out)
										io.put_new_line
									end

									if Result.is_valid then
										if l_has_mask then
											l_masking_key := next_bytes (a_socket, 4) -- 32 bits
											debug ("ws")
												print ("   Masking key bits=" + string_to_byte_representation (l_masking_key))
												io.put_new_line
											end
											if l_masking_key.count < 4 then
												debug ("ws")
													print ("masking-key read stream -> "+ a_socket.bytes_read.out + " bits%N")
												end
												Result.report_error (Invalid_data, "Incomplete data for Masking-key")
												l_masking_key := Void
											end
										else
											Result.report_error (protocol_error, "All frames sent from client to server are masked!")
										end
										if Result.is_valid then
											l_chunk_size := 0x4000 -- 16 K
											if l_payload_len > {INTEGER_32}.max_value.to_natural_64 then
													-- Issue .. to big to store in STRING
													-- FIXME !!!
												Result.report_error (Message_too_large, "Can not handle payload data (len=" + l_payload_len.out + ")")
											else
												l_len := l_payload_len.to_integer_32
											end

											from
												create s.make (l_len)
												l_remaining_len := l_len
											until
												s.count >= l_len or l_len = 0 or not Result.is_valid
											loop
												if l_remaining_len < l_chunk_size then
													l_chunk_size := l_remaining_len
												end
												a_socket.read_stream (l_chunk_size)
												debug ("ws")
													print ("read chunk size=" + l_chunk_size.out + " s.count="+ s.count.out +" l_len="+l_len.out+" -> " + a_socket.bytes_read.out + "bytes%N")
												end
												if a_socket.bytes_read > 0 then
													l_remaining_len := l_remaining_len - a_socket.bytes_read

													l_chunk := a_socket.last_string
													if l_masking_key /= Void then
															--  Masking
															--  http://tools.ietf.org/html/rfc6455#section-5.3
														append_chunk_unmasked (l_chunk, s.count + 1, l_masking_key, s)
													else
														s.append (l_chunk)
														check client_frame_should_always_be_encoded: False end
													end
												else
													Result.report_error (internal_error, "Issue reading payload data...")
												end
											end
											log ("%N" + s.count.out + " out of " + l_len.out + " received <===============")

											debug ("ws")
												print (" -> ")
												if s.count > 50 then
													print (string_to_byte_hexa_representation (s.head (50) + ".."))
												else
													print (string_to_byte_hexa_representation (s))
												end
												print ("%N")
												if Result.is_text then
													print (" -> ")
													if s.count > 50 then
														print (s.head (50) + "..")
													else
														print (s)
													end
													print ("%N")
												end
											end
											Result.append_payload_data_fragment (s, l_payload_len)
										end
									end
								end
							end
						end
					end
					if Result /= Void then
						if Result.is_injected_control then
							if attached Result.parent as l_parent then
								if not Result.is_valid then
									l_parent.report_error (protocol_error, "Invalid injected frame")
								end
								if Result.is_connection_close then
										-- Return this and process the connection close right away!
								else
									Result := l_parent
								end
								l_fin := l_parent.is_fin
								check
									 	-- This is a control frame but occurs in fragmented frame.
									inside_fragmented_frame: not l_fin
								end
							else
								check has_parent: False end
								l_fin := False -- This is a control frame but occurs in fragmented frame.
							end
						end
						if not Result.is_valid then
							is_data_frame_ok := False
						end
					else
						is_data_frame_ok := False
					end
				end
			end
		rescue
			retried := True
			if Result /= Void then
				Result.report_error (internal_error, "Internal error")
			end
			retry
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
			log ("%NReceive <====================")
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
					log ("%N================> Send")
					log (l_handshake)
					a_socket.put_string (l_handshake)
					is_handshake := True -- the connection is in OPEN State.
				end
			end
			if not is_handshake then
				log ("Error (opening_handshake)!!!")
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

feature {NONE} -- Socket helpers

	next_bytes (a_socket: WS_STREAM_SOCKET; nb: INTEGER): STRING
		require
			nb > 0
		local
			n,l_bytes_read: INTEGER
		do
			create Result.make (nb)
			from
				n := nb
			until
				n = 0
			loop
				a_socket.read_stream (nb)
				l_bytes_read := a_socket.bytes_read
				if l_bytes_read > 0 then
					Result.append (a_socket.last_string)
					n := n - l_bytes_read
				else
					n := 0
				end
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
			i,n: INTEGER
		do
			create Result.make (a_frame.count)
			from
				i := 1
				n := a_frame.count
			until
				i > n
			loop
				Result.append_code (a_frame.code (i).bit_xor (a_key [((i - 1) \\ 4) + 1].natural_32_code))
				i := i + 1
			end
		end

	append_chunk_unmasked (a_chunk: READABLE_STRING_8; a_pos: INTEGER; a_key: READABLE_STRING_8; a_target: STRING)
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
			i,n: INTEGER
		do
--			debug ("ws")
--				print ("append_chunk_unmasked (%"" + string_to_byte_representation (a_chunk) + "%",%N%Ta_pos=" + a_pos.out+ ", a_key, a_target #.count=" + a_target.count.out + ")%N")
--			end
			from
				i := 1
				n := a_chunk.count
			until
				i > n
			loop
				a_target.append_code (a_chunk.code (i).bit_xor (a_key [((i + (a_pos - 1) - 1) \\ 4) + 1].natural_32_code))
				i := i + 1
			end
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
				debug ("ws")
					io.put_string (m + "%N")
				end
			end
		end

	separate_log (m: STRING; a_logger: separate HTTP_SERVER_LOGGER)
		do
			a_logger.log (m)
		end

feature {NONE} -- Debug		

	to_byte_representation (a_integer: INTEGER): STRING
		require
			valid: a_integer >= 0 and then a_integer <= 255
		local
			l_val: INTEGER
		do
			create Result.make (8)
			from
				l_val := a_integer
			until
				l_val < 2
			loop
				Result.prepend_integer (l_val \\ 2)
				l_val := l_val // 2
			end
			Result.prepend_integer (l_val)
		end

	string_to_byte_representation (s: STRING): STRING
		require
			valid: s.count > 0
		local
			i, n: INTEGER
		do
			n := s.count
			create Result.make (8 * n)
			if n > 0 then
				from
					i := 1
				until
					i > n
				loop
					if not Result.is_empty then
						Result.append_character (':')
					end
					Result.append (to_byte_representation (s[i].code))
					i := i + 1
				end
			end
		end

	string_to_byte_hexa_representation (s: STRING): STRING
		local
			i, n: INTEGER
			c: INTEGER
		do
			n := s.count
			create Result.make (8 * n)
			if n > 0 then
				from
					i := 1
				until
					i > n
				loop
					if not Result.is_empty then
						Result.append_character (':')
					end
					c := s[i].code
					check c <= 0xFF end
					Result.append_character (((c |>> 4) & 0xF).to_hex_character)
					Result.append_character (((c) & 0xF).to_hex_character)
					i := i + 1
				end
			end
		end

invariant
	request_header_attached: request_header /= Void

note
	copyright: "2011-2013, Javier Velilla, Jocelyn Fiat and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"

end
