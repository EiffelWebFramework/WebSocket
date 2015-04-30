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
			listen,
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

	make_from_separate (s: separate HTTP_STREAM_SSL_SOCKET)
		local
			l_ssl_socket: SSL_TCP_STREAM_SOCKET
			l_context: SSL_CONTEXT
		do
			create l_ssl_socket.make_from_separate (retrieve_socket (s))
			l_ssl_socket.set_tls_protocol (tls_protocol (s))
			create l_context.make_from_context_pointer (tls_context (s), ssl_structure (s))
			l_ssl_socket.set_context (l_context)
			socket := l_ssl_socket
		end

feature

	listen (a_queue: INTEGER)
		do
			if attached {SSL_TCP_STREAM_SOCKET} socket as l_socket then
				l_socket.listen (a_queue)
			end
		end

	tls_context(s: separate HTTP_STREAM_SSL_SOCKET): POINTER
			-- Get tls context pointer.
		do
			if attached {separate SSL_TCP_STREAM_SOCKET} retrieve_ssl_stream_socket(s) as l_ssl_socket then
				if attached {separate SSL_CONTEXT } retrieve_ssl_context (l_ssl_socket) as l_ssl_context then
					if attached {separate SSL} retrieve_ssl (l_ssl_context) as l_ssl then
						Result := retrieve_ssl_ctx (l_ssl)
					end
				end
			end
		end

	ssl_structure (s: separate HTTP_STREAM_SSL_SOCKET): POINTER
			-- Get ssl structure pointer.
		do
			if attached {separate SSL_TCP_STREAM_SOCKET} retrieve_ssl_stream_socket(s) as l_ssl_socket then
				if attached {separate SSL_CONTEXT } retrieve_ssl_context (l_ssl_socket) as l_ssl_context then
					if attached {separate SSL} retrieve_ssl (l_ssl_context) as l_ssl then
						Result := retrieve_ssl_ptr (l_ssl)
					end
				end
			end
		end

	retrieve_ssl_context (s: separate SSL_TCP_STREAM_SOCKET): detachable separate SSL_CONTEXT
			-- Get ssl context.
		do
			Result := s.retrieve_context
		end

	retrieve_ssl (s: separate SSL_CONTEXT): detachable separate SSL
		do
			Result := s.last_ssl
		end

	retrieve_ssl_ctx (s: separate SSL): POINTER
		do
			Result := s.context_pointer
		end

	retrieve_ssl_ptr (s: separate SSL): POINTER
		do
			Result := s.ptr
		end

	tls_protocol(s: separate HTTP_STREAM_SSL_SOCKET): NATURAL_32
		do
			if attached {separate SSL_TCP_STREAM_SOCKET} retrieve_ssl_stream_socket(s) as l_ssl_socket then
				Result := retrieve_tls_protocol (l_ssl_socket)
			end
		end

	retrieve_tls_protocol (s: separate SSL_TCP_STREAM_SOCKET): NATURAL_32
		do
			Result := s.tls_protocol
		end

	ssl_crt(s: separate HTTP_STREAM_SSL_SOCKET): detachable separate PATH
		do
			if attached {separate SSL_TCP_STREAM_SOCKET} retrieve_ssl_stream_socket(s) as l_ssl_socket then
				Result := retrieve_ssl_crt (l_ssl_socket)
			end
		end

	retrieve_ssl_crt (s: separate SSL_TCP_STREAM_SOCKET): detachable separate PATH
		do
			Result := s.certificate_file_path
		end

	ssl_key(s: separate HTTP_STREAM_SSL_SOCKET): detachable separate PATH
		do
			if attached {separate SSL_TCP_STREAM_SOCKET} retrieve_ssl_stream_socket(s) as l_ssl_socket then
				Result := retrieve_ssl_key (l_ssl_socket)
			end
		end

	retrieve_ssl_key (s: separate SSL_TCP_STREAM_SOCKET): detachable separate PATH
		do
			Result := s.key_file_path
		end

	retrieve_ssl_stream_socket (s: separate HTTP_STREAM_SSL_SOCKET): detachable separate SSL_TCP_STREAM_SOCKET
		do
			if attached {separate SSL_TCP_STREAM_SOCKET} s.socket as l_ssl_socket then
				Result := l_ssl_socket
			end
		end

feature -- Output

	send_message (a_msg: STRING)
		do
			if attached socket as l_socket then
				if attached {SSL_TCP_STREAM_SOCKET} l_socket as l_ssl_socket then
					l_ssl_socket.send_message (a_msg)
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
			end
		end

	is_bound: BOOLEAN
		do
			if attached {SSL_TCP_STREAM_SOCKET} socket as l_ssl_socket then
				Result := l_ssl_socket.is_bound
			end
		end

	ready_for_writing: BOOLEAN
		do
			if attached {SSL_TCP_STREAM_SOCKET} socket as l_ssl_socket then
				Result := l_ssl_socket.ready_for_writing
			end
		end

	ready_for_reading: BOOLEAN
		do
			if attached {SSL_TCP_STREAM_SOCKET} socket as l_ssl_socket then
				Result := l_ssl_socket.ready_for_reading
			end
		end

	accepted: detachable HTTP_STREAM_SSL_SOCKET
		do
			if attached socket.accepted as l_accepted then
				create Result.make (l_accepted)
			end
		end

feature {HTTP_STREAM_SOCKET} -- Implementation

	set_certificates (a_crt: STRING; a_key: STRING)
			-- Set SSL certificates with `a_crt' and `a_key'.
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
