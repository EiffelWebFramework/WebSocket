note
	description: "[
			Summary description for {WS_FRAME}.
					See Base Framing Protocol: http://tools.ietf.org/html/rfc6455#section-5.2
				      0                   1                   2                   3
				      0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
				     +-+-+-+-+-------+-+-------------+-------------------------------+
				     |F|R|R|R| opcode|M| Payload len |    Extended payload length    |
				     |I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
				     |N|V|V|V|       |S|             |   (if payload len==126/127)   |
				     | |1|2|3|       |K|             |                               |
				     +-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
				     |     Extended payload length continued, if payload len == 127  |
				     + - - - - - - - - - - - - - - - +-------------------------------+
				     |                               |Masking-key, if MASK set to 1  |
				     +-------------------------------+-------------------------------+
				     | Masking-key (continued)       |          Payload Data         |
				     +-------------------------------- - - - - - - - - - - - - - - - +
				     :                     Payload Data continued ...                :
				     + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
				     |                     Payload Data continued ...                |
				     +---------------------------------------------------------------+
			]"
	date: "$Date$"
	revision: "$Revision$"

class
	WS_FRAME

inherit
	ANY

	WEB_SOCKET_CONSTANTS

create
	make,
	make_as_injected_control

feature {NONE} -- Initialization

	make (a_opcode: INTEGER; flag_is_fin: BOOLEAN)
			-- Create current frame with opcode `a_opcode'
			-- and `a_fin' to indicate if this is the final fragment.
		do
			is_incomplete := False
			opcode := a_opcode
			is_fin := flag_is_fin

			inspect opcode
			when
				Continuation_frame, -- 0
				Text_frame, -- 1
				Binary_frame -- 2
			then
					--| Supported opcode
			when
				Connection_close_frame, -- 8
				Ping_frame, -- 9
				Pong_frame -- 10
			then
					--| Supported control opcode
					-- All control frames MUST have a payload length of 125 bytes or less
   					-- and MUST NOT be fragmented.
				if flag_is_fin then
						-- So far it is valid.
				else
					report_error (Protocol_error, "Control frames MUST NOT be fragmented.")
				end
			else
				report_error (Protocol_error, "Unknown opcode")
			end
		end

	make_as_injected_control (a_opcode: INTEGER; a_parent: WS_FRAME)
		require
			parent_is_not_control_frame: not a_parent.is_control
			a_opcode_is_control_frame: is_control_frame (a_opcode)
		do
			make (a_opcode, True)
			parent := a_parent
			a_parent.add_injected_control_frame (Current)
		end

feature -- Access

	opcode: INTEGER
  			--  CONTINUOUS, TEXT, BINARY, PING, PONG, CLOSING

	is_fin: BOOLEAN
  			-- is the final fragment in a message?

  	fragment_count: INTEGER

	payload_length: NATURAL_64
	payload_data: detachable STRING_8
 			-- Maybe we need a buffer here.

	error: detachable WS_ERROR_FRAME
			-- Describe the type of error

feature -- Access: injected control frames

 	injected_control_frames: detachable LIST [WS_FRAME]

 	parent: detachable WS_FRAME
 			-- If Current is injected, `parent' is the related fragmented frame

	is_injected_control: BOOLEAN
		do
			Result := parent /= Void
		ensure
			Result implies (is_control_frame (opcode))
		end

feature -- Operation

	update_fin (a_flag_is_fin: BOOLEAN)
		do
			is_fin := a_flag_is_fin
		end

	validate
			-- Check current frame
		do
			if is_valid then
				if is_text and is_fin then
						-- Check the whole message is a valid UTF-8 string
					if attached payload_data as d then
						if not is_valid_utf_8_string (d) then
							report_error (invalid_data, "The text message is not a valid UTF-8 text!")
						end
					else
							-- empty payload??
					end
				end
			end
		end

feature {WS_FRAME} -- Change: injected control frames 			

	add_injected_control_frame (f: WS_FRAME)
		require
			Current_is_not_control: not is_control
			f_is_control_frame: f.is_control
			parented_to_current: f.parent = Current
		local
			lst: like injected_control_frames
		do
			lst := injected_control_frames
			if lst = Void then
				create {ARRAYED_LIST [WS_FRAME]} lst.make (1)
				injected_control_frames := lst
			end
			lst.force (f)
		ensure
			parented_to_current: f.parent = Current
		end

	remove_injected_control_frame (f: WS_FRAME)
		require
			Current_is_not_control: not is_control
			f_is_control_frame: f.is_control
			parented_to_current: f.parent = Current
		local
			lst: like injected_control_frames
		do
			lst := injected_control_frames
			if lst /= Void then
				lst.prune (f)
				if lst.is_empty then
					injected_control_frames := Void
				end
			end
		end

feature -- Query

	is_binary: BOOLEAN
		do
			Result := opcode = binary_frame
		end

	is_text: BOOLEAN
		do
			Result := opcode = text_frame
		end

	is_continuation: BOOLEAN
		do
			Result := opcode = continuation_frame
		end

	is_connection_close: BOOLEAN
		do
			Result := opcode = connection_close_frame
		end

	is_control: BOOLEAN
		do
			inspect opcode
			when connection_close_frame, Ping_frame, Pong_frame then
				Result := True
			else
			end
		end

	is_ping: BOOLEAN
		do
			Result := opcode = ping_frame
		end

	is_pong: BOOLEAN
		do
			Result := opcode = pong_frame
		end

feature -- Status report

	is_valid: BOOLEAN
		do
			Result := not has_error
		end

	is_incomplete: BOOLEAN

	has_error: BOOLEAN
		do
			Result := error /= Void
		end

feature -- Change

	append_payload_data_fragment (a_data: STRING_8; a_len: NATURAL_64)
		do
			fragment_count := fragment_count + 1
			if attached payload_data as l_payload_data then
				l_payload_data.append (a_data)
			else
				payload_data := a_data
			end
			payload_length := payload_length + a_len

			if is_text then
				if not is_valid_text_payload_stream then
					report_error (invalid_data, "This is not a valid UTF-8 stream!")
						-- is_valid implies the connection will be closed!
				end
			end
		end

	report_error (a_code: INTEGER; a_description: READABLE_STRING_8)
		require
			not has_error
		do
			create error.make (a_code, a_description)
		ensure
			has_error: has_error
			is_not_valid: not is_valid
		end

feature {NONE} -- Helper

	last_utf_8_stream_validation_position: INTEGER
			-- In relation with `is_valid_utf_8 (.., a_is_stream=True)'

	is_valid_text_payload_stream: BOOLEAN
		require
			is_text_frame: is_text
		do
			if attached payload_data as s then
				Result := is_valid_utf_8 (s, True)
			end
		end

	is_valid_utf_8_string (s: READABLE_STRING_8): BOOLEAN
		do
			Result := (create {UTF_CONVERTER}).is_valid_utf_8_string_8 (s) and is_valid_utf_8 (s, False)
		end

	is_valid_utf_8 (s: READABLE_STRING_8; a_is_stream: BOOLEAN): BOOLEAN
			-- Not that
		require
			is_text_frame: is_text
		local
			i: like {STRING_8}.count
			n: like {STRING_8}.count
			c,w: NATURAL_32
			l_is_incomplete_stream: BOOLEAN
		do
			Result := True
--				Result := (create {UTF_CONVERTER}).is_valid_utf_8_string_8 (s)
				-- Following code also check that codepoint is between 0 and 0x10FFFF (as expected by spec, and tested by autobahn ws testsuite)
			from
				if a_is_stream then
					i := last_utf_8_stream_validation_position -- to avoid recomputing from the beginning each time.
				else
					i := 0
				end
				n := s.count
			until
				i >= n or not Result
			loop
				i := i + 1
				c := s.code (i)
				if c <= 0x7F then
						-- 0xxxxxxx
					w := c
				elseif c <= 0xDF then
						-- 110xxxxx 10xxxxxx
					i := i + 1
					if i <= n then
						w := (
							((c & 0x1F) |<< 6) |
							(s.code (i) & 0x3F)
						)
					else
						l_is_incomplete_stream := True
					end
				elseif c <= 0xEF then
						-- 1110xxxx 10xxxxxx 10xxxxxx
					i := i + 2
					if i <= n then
						w := (
							((c & 0xF) |<< 12) |
							((s.code (i - 1) & 0x3F) |<< 6) |
							(s.code (i) & 0x3F)
						)
					else
						l_is_incomplete_stream := True
					end
				elseif c <= 0xF7 then
						-- 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
					i := i + 3
					if i <= n then
						w := (
							((c & 0x7) |<< 18) |
							((s.code (i - 2) & 0x3F) |<< 12) |
							((s.code (i - 1) & 0x3F) |<< 6) |
							(s.code (i) & 0x3F)
						)
					else
						l_is_incomplete_stream := True
					end
				else
					Result := False
				end
				if Result then
					if l_is_incomplete_stream then
						Result := a_is_stream
					else
						if w > 0x10FFFF then
							Result := False
						elseif 0xD800 <= w and w <= 0xDFFF then
							Result := False
						end
					end
				end
				if Result and a_is_stream and not l_is_incomplete_stream then
					last_utf_8_stream_validation_position := i
				end
			end
		end

end
