note
	description: "Summary description for {TEST_AUTOBAHN_CLIENT}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_AUTOBAHN_CLIENT

inherit

	WEB_SOCKET_CLIENT

create
	make, make_with_port, make_with_host_port_path

feature -- Initialization

	make (a_uri: STRING)
		do
			initialize (a_uri, Void)
			create implementation.make (create {WEB_SOCKET_NULL_CLIENT}, a_uri)
		end

	make_with_port (a_uri: STRING; a_port: INTEGER)
		do
			initialize_with_port (a_uri, a_port, Void)
			create implementation.make (create {WEB_SOCKET_NULL_CLIENT}, a_uri)
		end

	make_with_host_port_path (a_host: STRING; a_port: INTEGER; a_path: STRING)
		do
			initialize_with_host_port_and_path (a_host, a_port, a_path)
			create implementation.make (create {WEB_SOCKET_NULL_CLIENT}, a_host)
		end

feature -- Access

	count: INTEGER

	is_closed: BOOLEAN

feature -- Event

	on_open (a_message: STRING)
		do
		end

	on_text_message (a_message: STRING)
		local
			l_message: STRING
		do
			send (a_message)
		end

	on_binary_message (a_message: STRING)
		do
			send_binary (a_message)
		end

	on_close (a_code: INTEGER; a_reason: STRING)
		do
			ready_state.set_state ({WEB_SOCKET_READY_STATE}.closed)
			print ("Closed: " + a_code.out + " - " + a_reason)
			is_closed := True
		end

	on_error (a_error: STRING)
		do
			print ("Error: " + a_error)
		end

	connection: like new_socket
		do
			Result := socket
		end

end
