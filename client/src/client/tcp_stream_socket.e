note
	description: "Summary description for {TCP_STREAM_SOCKET}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	TCP_STREAM_SOCKET

create
	make_client_by_port, make_client_by_address_and_port,
	make_ssl_client_by_port, make_ssl_client_by_address_and_port

feature {NONE} -- Initialization

	make_client_by_port (a_peer_port: INTEGER; a_peer_host: STRING)
			-- Create a client connection to `a_peer_host' on
			-- `a_peer_port'.
		do
			last_string := ""
			create {NETWORK_STREAM_SOCKET} socket.make_client_by_port (a_peer_port, a_peer_host)
			socket.set_blocking
		end


	make_client_by_address_and_port (a_peer_address: INET_ADDRESS; a_peer_port: INTEGER)
			-- Create a client connection to `a_peer_host' on
			-- `a_peer_port'.
		do
			last_string := ""
			create {NETWORK_STREAM_SOCKET} socket.make_client_by_address_and_port (a_peer_address, a_peer_port)
			socket.set_blocking
		end


	make_ssl_client_by_port (a_peer_port: INTEGER; a_peer_host: STRING)
			-- Create a client connection to `a_peer_host' on
			-- `a_peer_port'
		local
			a_file_name: FILE_NAME
		do
			last_string := ""
			create {SSL_NETWORK_STREAM_SOCKET} socket.make_client_by_port (a_peer_port, a_peer_host)

			if attached {SSL_NETWORK_STREAM_SOCKET} socket as l_ssl then
--				create a_file_name.make_from_string ("C:/OpenSSL-Win64/bin/ca.crt")
--				l_ssl.set_certificate_file_name (a_file_name)
--				create a_file_name.make_from_string ("C:/OpenSSL-Win64/bin/ca.key")
--				l_ssl.set_key_file_name (a_file_name)
				l_ssl.set_tls_protocol ({SSL_PROTOCOL}.ssl_23)
				l_ssl.set_blocking
			end
		end


	make_ssl_client_by_address_and_port (a_peer_address: INET_ADDRESS; a_peer_port: INTEGER)
			-- Create a client connection to `a_peer_host' on
			-- `a_peer_port'.
		do
			last_string := ""
			create {SSL_NETWORK_STREAM_SOCKET} socket.make_client_by_address_and_port (a_peer_address, a_peer_port)
			socket.set_blocking
		end


	socket: SOCKET
		-- Implementation

feature -- Basic operation

	connect
		do
			socket.connect
		end

	close
		do
			socket.close
		end


	send_message (a_msg: STRING)
		local
			a_package: PACKET
			a_data: MANAGED_POINTER
			c_string: C_STRING
		do
			print ("%NClient send message:" + a_msg)
			socket.put_string (a_msg)
		end

--	send_message (a_msg: STRING)
--                local
--                        a_package : PACKET
--                        a_data : MANAGED_POINTER
--                        c_string : C_STRING
--                do
--                        create c_string.make (a_msg)
--                        create a_data.make_from_pointer (c_string.item, a_msg.count + 1)
--                        create a_package.make_from_managed_pointer (a_data)
--                        socket.send (a_package, 1)
--                end

feature -- Output

	put_readable_string_8 (s: READABLE_STRING_8)
			-- Write readable string `s' to socket.
		local
			ext: C_STRING
		do
			create ext.make (s)
			socket.put_managed_pointer (ext.managed_data, 0, s.count)
		end

	put_string (a_message: STRING)
		do
			socket.put_string (a_message)
		end

feature -- Access

	last_string : STRING

	bytes_read: INTEGER
		do
			if attached socket as l_socket then
				Result := l_socket.bytes_read
			end
		end

feature -- Status report

	is_connected: BOOLEAN
		do
			if attached {NETWORK_SOCKET} socket as l_socket then
				Result := l_socket.is_connected
			end
		end

	is_blocking: BOOLEAN
		do
			if attached {TCP_STREAM_SOCKET} socket as l_socket then
				Result := l_socket.is_blocking
			elseif attached {SSL_NETWORK_STREAM_SOCKET} socket as l_ssl_socket then
				Result := l_ssl_socket.is_blocking
			elseif attached socket as l_socket then
				Result := l_socket.is_blocking
			end
		end

	is_open_read: BOOLEAN
		do
			Result := socket.is_open_read
		end

	socket_ok: BOOLEAN
		do
			Result := socket.socket_ok
		end

	exists: BOOLEAN
		do
			Result := socket.exists
		end

	ready_for_reading: BOOLEAN
			-- Is data available for reading from the socket right now?
		require
			socket_exists: exists
		do
			if attached {NETWORK_SOCKET} socket as l_socket then
				Result := l_socket.ready_for_reading
			end

		end


feature -- Input

	read_stream, readstream (nb_char: INTEGER)
			-- Read a string of at most `nb_char' characters.
			-- Make result available in `last_string'.
		do
			socket.read_stream (nb_char)
			last_string := socket.last_string
		end

	read_line_thread_aware
		do
			socket.read_line_thread_aware
			last_string := socket.last_string
		end

note
	copyright: "2011-2013, Javier Velilla, Jocelyn Fiat and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"

end
