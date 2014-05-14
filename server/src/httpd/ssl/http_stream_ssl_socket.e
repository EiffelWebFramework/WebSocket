note
	description: "[
			Summary description for {HTTP_STREAM_SSL_SOCKET}
			that can be used for http or https connection.
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	HTTP_STREAM_SSL_SOCKET

inherit
	HTTP_STREAM_SOCKET
		redefine
			make_from_separate,
			send_message,
			port,
			is_bound,
			ready_for_writing,
			ready_for_reading,
			accepted
		end

create
	make_ssl_server_by_address_and_port, make_ssl_server_by_port, 
	make_server_by_address_and_port, make_server_by_port, make_from_separate

create {HTTP_STREAM_SOCKET}
	make

feature {NONE} -- Initialization

	make_ssl_server_by_address_and_port (an_address: INET_ADDRESS; a_port: INTEGER; a_ssl_protocol: NATURAL; a_crt: STRING; a_key: STRING)
		local
			l_socket: SSL_TCP_STREAM_SOCKET
		do
			create l_socket.make_server_by_address_and_port (an_address, a_port)
			l_socket.set_tls_protocol (a_ssl_protocol)
			socket := l_socket
			set_certificates (a_crt, a_key)
		end

	make_ssl_server_by_port (a_port: INTEGER; a_ssl_protocol: NATURAL; a_crt: STRING; a_key: STRING)
		local
			l_socket: SSL_TCP_STREAM_SOCKET
		do
			create  l_socket.make_server_by_port (a_port)
			l_socket.set_tls_protocol (a_ssl_protocol)
			socket := l_socket
			set_certificates (a_crt, a_key)
		end

	make_from_separate (s: separate HTTP_STREAM_SOCKET)
		local
			l_string: STRING
		do
			create l_string.make_from_separate (s.socket.generator)
			if l_string.same_string ("TCP_STREAM_SOCKET") then
				create {TCP_STREAM_SOCKET} socket.make_from_separate (retrieve_socket (s))
			elseif attached {SSL_TCP_STREAM_SOCKET} s.socket then
				create {SSL_TCP_STREAM_SOCKET} socket.make_from_separate (retrieve_socket (s))
			else
				create {TCP_STREAM_SOCKET} socket.make_from_separate (retrieve_socket (s))
					-- maybe a NULL_STREAM_SOCKET should be better.
			end
		end

feature -- Output

	send_message (a_msg: STRING)
		do
			if attached socket as l_socket then
				if attached {SSL_TCP_STREAM_SOCKET} l_socket as l_ssl_socket then
					l_ssl_socket.send_message (a_msg)
				elseif attached {TCP_STREAM_SOCKET} socket as l_normal_socket then
					l_normal_socket.send_message (a_msg)
				else
					l_socket.put_string (a_msg)
				end
			end
		end

feature -- Status Report

	port: INTEGER
		do
			if attached {SSL_TCP_STREAM_SOCKET} socket as l_ssl_socket then
				Result := l_ssl_socket.port
			elseif attached {TCP_STREAM_SOCKET} socket then
				Result := Precursor
			end
		end

	is_bound: BOOLEAN
		do
			if attached {SSL_TCP_STREAM_SOCKET} socket as l_ssl_socket then
				Result := l_ssl_socket.is_bound
			elseif attached {TCP_STREAM_SOCKET} socket then
				Result := Precursor
			end
		end

	ready_for_writing: BOOLEAN
		do
			if attached {SSL_TCP_STREAM_SOCKET} socket as l_ssl_socket then
				Result := l_ssl_socket.ready_for_writing
			elseif attached {TCP_STREAM_SOCKET} socket then
				Result := Precursor

			end
		end

	ready_for_reading: BOOLEAN
		do
			if attached {TCP_STREAM_SOCKET} socket as l_socket then
				Result := l_socket.ready_for_reading
			elseif attached {SSL_TCP_STREAM_SOCKET} socket as l_ssl_socket then
				Result := l_ssl_socket.ready_for_reading
			end
		end

	accepted: detachable HTTP_STREAM_SOCKET
		do
			if attached {SSL_TCP_STREAM_SOCKET} socket as l_ssl_socket then
				if attached l_ssl_socket.accepted as l_accepted then
					create Result.make (l_accepted)
				end
			elseif attached {TCP_STREAM_SOCKET} socket then
				Result := Precursor
			end
		end

feature {HTTP_STREAM_SOCKET} -- Implementation

	set_certificates (a_crt: STRING; a_key: STRING)
		local
			a_file_name: FILE_NAME
		do
			if attached {SSL_NETWORK_STREAM_SOCKET} socket as l_socket then
				create a_file_name.make_from_string (a_crt)
				l_socket.set_certificate_file_name (a_file_name)
				create a_file_name.make_from_string (a_key)
				l_socket.set_key_file_name (a_file_name)
			end
		end

end
