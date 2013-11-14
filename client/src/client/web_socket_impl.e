note
	description: "Summary description for {WEB_SOCKET_IMPL}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	WEB_SOCKET_IMPL

inherit

	WEB_SOCKET

create
	make,
	make_with_port,
	make_with_protocols,
	make_with_protocols_and_port


feature {NONE} -- Initialization


	make (a_subscriber: WEB_SOCKET_SUBSCRIBER; a_uri: READABLE_STRING_GENERAL)
			-- Create a websocket instante with a default port.
		do
			reset
			subscriber := a_subscriber
			uri := a_uri
			set_default_port
			create ready_state.make
		ensure
			uri_set: a_uri = uri
			port_wss: is_tunneled implies port = wss_port_default
			port_ws:  not is_tunneled implies port = ws_port_default
			ready_state_set: ready_state.state = {WEB_SOCKET_READY_STATE}.connecting
			subscriber_set: subscriber = a_subscriber
		end

	make_with_port (a_subscriber: WEB_SOCKET_SUBSCRIBER;a_uri: READABLE_STRING_GENERAL; a_port: INTEGER)
			-- Create a websocket instance with port `a_port',
		do
			make (a_subscriber, a_uri)
			port := a_port
		ensure
			uri_set: a_uri = uri
			port_set: port = a_port
			ready_state_set: ready_state.state = {WEB_SOCKET_READY_STATE}.connecting
			subscriber_set: subscriber = a_subscriber
		end

	make_with_protocols (a_subscriber: WEB_SOCKET_SUBSCRIBER; a_uri: READABLE_STRING_GENERAL; a_protocols: detachable LIST[STRING] )
			-- Create a web socket instance with a list of protocols `a_protocols' and default port.
		do
			reset
			subscriber := a_subscriber
			uri := a_uri
			protocols := a_protocols
			set_default_port
			create ready_state.make
		ensure
			uri_set: a_uri = uri
			port_wss: is_tunneled implies port = wss_port_default
			port_ws:  not is_tunneled implies port = ws_port_default
			protocols_set: protocols = a_protocols
			ready_state_set: ready_state.state = {WEB_SOCKET_READY_STATE}.connecting
			subscriber_set: subscriber = a_subscriber
		end


	make_with_protocols_and_port (a_subscriber: WEB_SOCKET_SUBSCRIBER; a_uri: READABLE_STRING_GENERAL; a_protocols: detachable LIST[STRING]; a_port: INTEGER )
			-- Create a web socket instance with a list of protocols `a_protocols' and port `a_port'.
		do
			make_with_protocols (a_subscriber,a_uri,a_protocols)
			port := a_port
		ensure
			uri_set: a_uri = uri
			protocols_set: protocols = a_protocols
			port_set: port = a_port
			ready_state_set: ready_state.state = {WEB_SOCKET_READY_STATE}.connecting
			subscriber_set: subscriber = a_subscriber
		end

	reset
		do
			has_error := False
			is_data_frame_ok := True
			close_description := [Normal_closure, "Normal close"]
			is_incomplete_data := False
		end

feature -- Access

	has_error: BOOLEAN


feature -- Handshake

	start_handshake (a_handshake: STRING)
		do
			subscriber.on_websocket_handshake (a_handshake)
		end

feature -- Access

	is_incomplete_data: BOOLEAN

	is_data_frame_ok: BOOLEAN
			-- Is the last process data framing ok?

	opcode : INTEGER
		-- opcode of the message

	close_description: TUPLE [code:INTEGER; description: STRING]

feature -- Receive

	receive
		local
			l_message: STRING
		do
			from
			until
				subscriber.connection.ready_for_reading or ready_state.is_closed
			loop
			end
				l_message := read_data_framing (subscriber.connection)
				if is_data_frame_ok then
					if opcode = text_frame then
						subscriber.on_websocket_text_message (l_message)
					elseif opcode = binary_frame then
						subscriber.on_websocket_binary_message (l_message)
					elseif opcode = ping_frame then
						subscriber.on_websocket_ping (l_message)
					elseif opcode = pong_frame then
						subscriber.on_websocket_pong (l_message)
					else
						subscriber.on_websocket_error ("Wrong Opcode")
					end
				else
					subscriber.on_websocket_close ("Invalid data frame")
				end

		end


feature -- Methods

	send (a_message: STRING)
		do
		end


	close (a_id: INTEGER)
			-- Close a websocket connection with a close id : `a_id'
		do
		end

	close_with_description (a_id: INTEGER; a_description: READABLE_STRING_GENERAL)
			-- Close a websocket connection with a close id : `a_id' and a description `a_description'
		do
		end


feature {NONE} -- Implementation

	set_default_port
		do
			if is_tunneled then
				port := wss_port_default
			else
				port := ws_port_default
			end
		end

	subscriber: WEB_SOCKET_SUBSCRIBER


	read_data_framing (a_socket: TCP_STREAM_SOCKET): STRING
			-- TODO Binary messages
			-- Handle error responses in a better way.
			-- IDEA:
			-- class FRAME
			-- 		is_fin: BOOLEAN
			--		opcode: WEB_SOCKET_STATUS_CODE (TEXT, BINARY, CLOSE, CONTINUE,PING, PONG)
			--		data/payload
			--      status_code: #see Status Codes http://tools.ietf.org/html/rfc6455#section-7.3
			--		has_error
		note
			EIS: "name=Data Frame", "src=http://tools.ietf.org/html/rfc6455#section-5", "protocol=uri"
			EIS: "name=Masking","src=http://tools.ietf.org/html/rfc6455#section-5.3", "protocol=uri"
		local
			l_opcode: INTEGER
			l_len: INTEGER
			l_encoded: BOOLEAN
			l_utf: UTF_CONVERTER
			l_key: STRING
			i: INTEGER
			l_frame: STRING
			l_rsv: BOOLEAN
			l_fin: BOOLEAN
			l_remaining: BOOLEAN
			l_chunk_size: INTEGER
		do
			create Result.make_empty
			from
			until
				l_fin or not is_data_frame_ok or is_incomplete_data
			loop
					-- multi-frames or continue is only valid for Binary or Text
				a_socket.read_stream (1)
				is_incomplete_data := a_socket.last_string.is_empty
				l_opcode := a_socket.last_string.at (1).code

				debug
					print (to_byte (l_opcode).out)
				end
				l_fin := l_opcode & (0b10000000) /= 0
				l_rsv := l_opcode & (0b01110000) = 0
				l_opcode := l_opcode & 0xF
				opcode := l_opcode
--				log ("Standard Action:" + l_opcode.out)
				if not ( l_opcode = 0 or else l_opcode = 1 or else l_opcode = 2 or else l_opcode = 8 or else l_opcode = 9 or else l_opcode = 10) then
					is_data_frame_ok := False
					close_description := [Protocol_error, "Unkown opcode"]
				end
					-- fin validation
				if not l_fin and then is_data_frame_ok then
						-- Control frames (see Section 5.5) MAY be injected in the middle of
						--a fragmented message.  Control frames themselves MUST NOT be fragmented.
						-- if the l_opcode is a control frame then there is an error!!!
						-- PING, PONG, CLOSE
					if l_opcode = 8 or else l_opcode = 9 or l_opcode = 10 then
						is_data_frame_ok := False
						ready_state.set_state ({WEB_SOCKET_READY_STATE}.closed)
						close_description := [protocol_error, "Control frames themselves MUST NOT be fragmented."]
					end
				end

					-- rsv validation
				if not l_rsv and then is_data_frame_ok then
					is_data_frame_ok := False
						-- RSV1, RSV2, RSV3:  1 bit each

						-- MUST be 0 unless an extension is negotiated that defines meanings
						-- for non-zero values.  If a nonzero value is received and none of
						-- the negotiated extensions defines the meaning of such a nonzero
						-- value, the receiving endpoint MUST _Fail the WebSocket
						-- Connection_
						is_data_frame_ok := False
						close_description := [protocol_error, "RSV values MUST be 0 unless an extension is negotiated that defines meanings for non-zero values"]
				end

					-- At the moment only TEXT, (pending Binary)
				if (l_opcode = 1  or l_opcode = 2 or l_opcode = 0) and then is_data_frame_ok then -- Binary, Text
					l_chunk_size := 1024
					a_socket.read_stream (1)
					l_len := a_socket.last_string.at (1).code
					is_incomplete_data := l_len < 2

					debug
						print (to_byte (l_len).out)
					end
					l_encoded := l_len >= 128
					if l_encoded then
						l_len := l_len - 128
					end
					if l_len = 127 then  -- TODO proof of concept read 8 bytes.
						a_socket.read_stream (8)
						l_len := (a_socket.last_string[6].code |<< 16).bit_or(a_socket.last_string[7].code |<< 8).bit_or(a_socket.last_string[8].code)
					elseif l_len = 126 then
						a_socket.read_stream (2)
						l_len := (a_socket.last_string[1].code |<< 8).bit_or(a_socket.last_string[2].code)
					end

					if l_len < 1024 then
						l_chunk_size := l_len
					end

						from
						until
							l_remaining
						loop
							if a_socket.ready_for_reading then
								a_socket.read_stream (l_chunk_size)
								l_frame := a_socket.last_string
									--  Masking
									--  http://tools.ietf.org/html/rfc6455#section-5.3
								if l_opcode = 1 then
									Result.append (l_utf.string_32_to_utf_8_string_8 (l_frame))
								else
									Result.append (l_frame)
								end
								l_remaining := l_len <= Result.count
							end
						end

						debug
--							log ("Received <===============")
--							log (Result)
						end

				end
			end
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

feature -- Masking
	unmmask (a_frame: READABLE_STRING_8; a_key: READABLE_STRING_8): STRING
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
			EIS: "name=Masking","src=S", "protocol=uri"
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
end
