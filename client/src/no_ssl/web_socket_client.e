note
	description: "[
		API to perform actions like opening and closing the connection, sending and receiving messages, and listening
		for events triggered by the server
	]"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	WEB_SOCKET_CLIENT

inherit
	WEB_SOCKET_CLIENT_I

feature -- Initialization

	new_socket (a_port: INTEGER; a_host: STRING): HTTPD_STREAM_SOCKET
		do
			if is_tunneled then
				check ssl_supported: False end
			end
			create {HTTPD_STREAM_SOCKET} Result.make_client_by_port (a_port, a_host)
		end

end
