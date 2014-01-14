note
	description: "{NULL_WS_CLIENT}. Null client used for void-safety."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	NULL_WS_CLIENT

inherit

	WEB_SOCKET_SUBSCRIBER

feature -- Initialization

	make
		do
		end


	on_open (a_data: WEB_SOCKET_HANDSHAKE_DATA)
		do
		end

	on_message (a_message: STRING)
		do
		end

	on_close (a_code: INTEGER; a_reason: STRING)
		do
		end

	on_error (a_error: STRING)
		do
		end

	on_websocket_handshake (a_request: STRING)
		do
		end

	connection: TCP_STREAM_SOCKET
		do
			create Result.make_client_by_port (0, "null")
		end
end
