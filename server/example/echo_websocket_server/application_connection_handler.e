note
	description: "Summary description for {HTTP_REQUEST_HANDLER}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	APPLICATION_CONNECTION_HANDLER

inherit
	WS_REQUEST_HANDLER

create
	make

feature -- Request processing

	process_http_request (a_socket: HTTP_STREAM_SOCKET)
			-- Process request ...
		do
			a_socket.put_string ("HTTP/1.1  501 Not Implemented%N")
		end

	on_open (a_socket: HTTP_STREAM_SOCKET)
		do
			if is_verbose then
				log ("Connecting")
			end
		end

note
	copyright: "2011-2014, Javier Velilla, Jocelyn Fiat and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end
