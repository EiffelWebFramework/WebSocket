note
	description: "Summary description for {WS_STREAM_SOCKET}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	WS_STREAM_SOCKET

create
	make_ssl_server_by_address_and_port, make_ssl_server_by_port,
	make_server_by_address_and_port, make_server_by_port, make_from_separate

create {WS_STREAM_SOCKET}
	make

feature {NONE} -- Initialization

	make_ssl_server_by_address_and_port (an_address: INET_ADDRESS; a_port: INTEGER; a_ssl_protocol: NATURAL; a_crt: STRING; a_key: STRING)
		do
			create {SSL_TCP_STREAM_SOCKET} socket.make_server_by_address_and_port (an_address, a_port)
			if attached {SSL_TCP_STREAM_SOCKET} socket as l_socket then
				l_socket.set_tls_protocol (a_ssl_protocol)
			end
			set_certificates (a_crt, a_key)
		end

	make_ssl_server_by_port (a_port: INTEGER; a_ssl_protocol: NATURAL; a_crt: STRING; a_key: STRING)
		do
			create {SSL_TCP_STREAM_SOCKET} socket.make_server_by_port (a_port)
			if attached {SSL_TCP_STREAM_SOCKET} socket as l_socket then
				l_socket.set_tls_protocol (a_ssl_protocol)
			end
			set_certificates (a_crt, a_key)
		end


	make_server_by_address_and_port (an_address: INET_ADDRESS; a_port: INTEGER)
		do
			create {TCP_STREAM_SOCKET} socket.make_server_by_address_and_port (an_address, a_port)

		end

	make_server_by_port (a_port: INTEGER)
		do
			create {TCP_STREAM_SOCKET} socket.make_server_by_port (a_port)
		end

	make_from_separate (s: separate WS_STREAM_SOCKET)
		local
			l_string: STRING

		do
			create l_string.make_from_separate (s.socket.generator)
			if l_string.same_string ("TCP_STREAM_SOCKET") then
				create {TCP_STREAM_SOCKET} socket.make_from_separate (retrieve_socket (s))
			elseif l_string.same_string ("SSL_TCP_STREAM_SOCKET") then
				create {SSL_TCP_STREAM_SOCKET} socket.make_from_separate (retrieve_socket (s))
			else
				create {TCP_STREAM_SOCKET} socket.make_from_separate (retrieve_socket (s))
					-- maybe a NULL_STREAM_SOCKET should be better.
			end
		end

	retrieve_socket (s: separate WS_STREAM_SOCKET): INTEGER
		do
			Result := s.socket.descriptor
		end

feature -- Access


	last_string: STRING
		do
			if attached socket as l_socket then
				Result := l_socket.last_string
			else
				Result := ""
			end

		end


	peer_address: detachable NETWORK_SOCKET_ADDRESS
			-- Peer address of socket
		do
			if attached socket as l_socket  then
				if attached {NETWORK_SOCKET_ADDRESS} l_socket.peer_address as l_peer_address then
					Result := l_peer_address
				end

			end
		end


feature -- Input

	read_line_thread_aware
		do
			if attached socket as l_socket then
				l_socket.read_line_thread_aware
			end
		end

	read_stream (nb: INTEGER)
		do
			if attached socket as l_socket then
				l_socket.read_stream (nb)
			end
		end

feature -- Output

	put_string (s: STRING)
		do
			if attached socket as l_socket then
				l_socket.put_string (s)
			end
		end

	send_message (a_msg: STRING)
		do
			if attached {SSL_TCP_STREAM_SOCKET} socket as l_ssl_socket then
				l_ssl_socket.send_message (a_msg)
			elseif attached {TCP_STREAM_SOCKET} socket as l_socket then
				l_socket.send_message (a_msg)
			end
		end

feature -- Status Report

	descriptor: INTEGER
		do
			if attached socket as l_socket then
				Result := l_socket.descriptor
			end
		end

	port: INTEGER
		do
			if attached {SSL_TCP_STREAM_SOCKET} socket as l_ssl_socket then
				Result := l_ssl_socket.port
			elseif attached {TCP_STREAM_SOCKET} socket as l_socket then
				Result := l_socket.port
			end
		end

	is_bound: BOOLEAN
		do
			if attached {TCP_STREAM_SOCKET} socket as l_socket then
					Result := l_socket.is_bound
			elseif attached {SSL_TCP_STREAM_SOCKET} socket as l_ssl_socket then
					Result := l_ssl_socket.is_bound
			end
		end

	socket_ok: BOOLEAN
		do
			if attached socket as l_socket then
				Result := l_socket.socket_ok
			end
		end

	is_open_read: BOOLEAN
		do
			if attached socket as l_socket then
				Result := l_socket.is_open_read
			end
		end

	is_open_write: BOOLEAN
		do
			if attached socket as l_socket then
				Result := l_socket.is_open_write
			end

		end

	is_closed: BOOLEAN
		do
			if attached socket as l_socket then
				Result := l_socket.is_closed
			end
		end

	is_readable: BOOLEAN
		do
			if attached socket as l_socket then
				Result := l_socket.is_readable
			end
		end

	cleanup
		do
			if attached socket as l_socket then
				l_socket.cleanup
			end
		end

	ready_for_writing: BOOLEAN
		do
			if attached {TCP_STREAM_SOCKET} socket as l_socket then
					Result := l_socket.ready_for_writing
			elseif attached {SSL_TCP_STREAM_SOCKET} socket as l_ssl_socket then
					Result := l_ssl_socket.ready_for_writing
			end

		end

	listen (a_queue: INTEGER)
		do
			if attached {TCP_STREAM_SOCKET} socket as l_socket then
				l_socket.listen (a_queue)
			elseif attached {SSL_TCP_STREAM_SOCKET} socket as l_ssl_socket then
				l_ssl_socket.listen (a_queue)
			end
		end

	accept
		do
			if attached {TCP_STREAM_SOCKET} socket as l_socket then
				l_socket.accept
			elseif attached {SSL_TCP_STREAM_SOCKET} socket as l_ssl_socket then
				l_ssl_socket.accept
			end
		end

	set_blocking
		do
			if attached {TCP_STREAM_SOCKET} socket as l_socket then
				l_socket.set_blocking
			elseif attached {SSL_TCP_STREAM_SOCKET} socket as l_ssl_socket then
				l_ssl_socket.set_blocking
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

	accepted : detachable WS_STREAM_SOCKET
		do
			if attached {TCP_STREAM_SOCKET} socket as l_socket then
				if attached l_socket.accepted as l_accepted then
					create Result.make (l_accepted)
				end
			elseif attached {SSL_TCP_STREAM_SOCKET} socket as l_ssl_socket then
				if attached l_ssl_socket.accepted as l_accepted then
					create Result.make (l_accepted)
				end
			end
		end


feature {NONE, WS_STREAM_SOCKET} -- Implementation

	make (a_socket: STREAM_SOCKET)
		do
			socket := a_socket
		end



 	socket: SOCKET

	set_certificates (a_crt: STRING; a_key: STRING)
		local
			a_file_name: FILE_NAME
		do
			if attached {SSL_NETWORK_STREAM_SOCKET}socket as l_socket then
				create a_file_name.make_from_string (a_crt)
				l_socket.set_certificate_file_name (a_file_name)
				create a_file_name.make_from_string (a_key)
				l_socket.set_key_file_name (a_file_name)
			end
		end

end
