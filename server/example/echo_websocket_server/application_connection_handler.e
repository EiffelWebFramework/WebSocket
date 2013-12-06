note
	description: "Summary description for {HTTP_REQUEST_HANDLER}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	APPLICATION_CONNECTION_HANDLER

inherit
	HTTP_REQUEST_HANDLER

create
	make

feature -- Request processing

	on_open (a_socket: WS_STREAM_SOCKET)
		do
			log ("Connecting")
		end
note
	copyright: "2011-2013, Javier Velilla, Jocelyn Fiat and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end
