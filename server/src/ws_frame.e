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

	set_is_fin (b: BOOLEAN)
		do
			is_fin := b
		end

	append_payload_data_fragment (a_data: STRING_8; a_len: NATURAL_64)
		do
			fragment_count := fragment_count + 1
			if is_text and then not is_valid_text_payload_data_fragment (a_data) then
				report_error (invalid_data, "The payload is not valid UTF-8!")
					-- the connection should then be closed!
			else
				if attached payload_data as d then
					d.append (a_data)
				else
					payload_data := a_data
				end
				payload_length := payload_length + a_len
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

	is_valid_text_payload_data_fragment (s: READABLE_STRING_8): BOOLEAN
		require
			is_text_frame: is_text
		do
			if not is_text then
				Result := True
			else
				Result := is_valid_utf_8_string_8 (s)
			end
		end

	is_valid_utf_8_string_8 (s: READABLE_STRING_8): BOOLEAN
		local
			i: like {STRING_8}.count
			n: like {STRING_8}.count
			c,w: NATURAL_32
			utf: UTF_CONVERTER
		do
--			Result := True
			Result := utf.is_valid_utf_8_string_8 (s)
				-- Following code also check that codepoint is between 0 and 0x10FFFF (as expected by spec, and tested by autobahn ws testsuite)
			from
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
					end
				else
					Result := False
				end
				Result := Result and w <= {NATURAL_32} 0x10FFFF
			end
		ensure
			Result implies (create {UTF_CONVERTER}).is_valid_utf_8_string_8 (s)
		end

end
