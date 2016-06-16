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
				create {HTTPD_STREAM_SSL_SOCKET} Result.make_ssl_client_by_port (a_port, a_host, {SSL_PROTOCOL}.ssl_23, "FIXME", "FIXME")
			else
				create {HTTPD_STREAM_SOCKET} Result.make_client_by_port (a_port, a_host)
			end
		end

end
