note
	description: "[
			Summary description for {HTTP_STREAM_SOCKET}
			that can be used for http or https connection.
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	HTTP_STREAM_SOCKET

create
	make_server_by_address_and_port, make_server_by_port, make_from_separate

create {HTTP_STREAM_SOCKET}
	make

feature {NONE} -- Initialization

	make_server_by_address_and_port (an_address: INET_ADDRESS; a_port: INTEGER)
		do
			create {TCP_STREAM_SOCKET} socket.make_server_by_address_and_port (an_address, a_port)
		end

	make_server_by_port (a_port: INTEGER)
		do
			create {TCP_STREAM_SOCKET} socket.make_server_by_port (a_port)
		end

	make_from_separate (s: separate HTTP_STREAM_SOCKET)
		do
			create {TCP_STREAM_SOCKET} socket.make_from_separate (retrieve_socket (s))
		end

	retrieve_socket (s: separate HTTP_STREAM_SOCKET): INTEGER
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
			if attached socket as l_socket then
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

	bytes_read: INTEGER
		do
			if attached socket as l_socket then
				Result := l_socket.bytes_read
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
			if attached {TCP_STREAM_SOCKET} socket as l_socket then
				l_socket.send_message (a_msg)
			else
				socket.put_string (a_msg)
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
			if attached {TCP_STREAM_SOCKET} socket as l_socket then
				Result := l_socket.port
			end
		end

	is_blocking: BOOLEAN
		do
			Result := socket.is_blocking
		end

	is_bound: BOOLEAN
		do
			if attached {TCP_STREAM_SOCKET} socket as l_socket then
				Result := l_socket.is_bound
			end
		end

	socket_ok: BOOLEAN
		do
			Result := socket.socket_ok
		end

	is_open_read: BOOLEAN
		do
			Result := socket.is_open_read
		end

	is_open_write: BOOLEAN
		do
			Result := socket.is_open_write
		end

	is_closed: BOOLEAN
		do
			Result := socket.is_closed
		end

	is_readable: BOOLEAN
		do
			Result := socket.is_readable
		end

	cleanup
		do
			socket.cleanup
		end

	ready_for_writing: BOOLEAN
		do
			if attached {TCP_STREAM_SOCKET} socket as l_socket then
				Result := l_socket.ready_for_writing
			end
		end

	listen (a_queue: INTEGER)
		do
			if attached {TCP_STREAM_SOCKET} socket as l_socket then
				l_socket.listen (a_queue)
			end
		end

	accept
		do
			socket.accept
		end

	set_blocking
		do
			socket.set_blocking
		end

	set_non_blocking
		do
			socket.set_non_blocking
		end

	ready_for_reading: BOOLEAN
		do
			if attached {TCP_STREAM_SOCKET} socket as l_socket then
				Result := l_socket.ready_for_reading
			end
		end

	accepted: detachable HTTP_STREAM_SOCKET
		do
			if attached {TCP_STREAM_SOCKET} socket as l_socket then
				if attached l_socket.accepted as l_accepted then
					create Result.make (l_accepted)
				end
			end
		end

feature {HTTP_STREAM_SOCKET} -- Implementation

	make (a_socket: STREAM_SOCKET)
		do
			socket := a_socket
		end

	socket: STREAM_SOCKET

end
