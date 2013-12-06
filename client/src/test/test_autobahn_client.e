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
	make,
	make_with_port,
	make_with_host_port_path


feature -- Initialization


	make (a_uri: STRING)
		do
			initialize (a_uri)
			create implementation.make (create {NULL_WS_CLIENT},a_uri)
		end

	make_with_port (a_uri: STRING; a_port: INTEGER)
		do
			initialize_with_port (a_uri, a_port)
			create implementation.make (create {NULL_WS_CLIENT},a_uri)
		end

	make_with_host_port_path (a_host: STRING; a_port: INTEGER;  a_path: STRING)
		do
			initialize_with_host_port_and_path (a_host, a_port, a_path)
			create implementation.make (create {NULL_WS_CLIENT},a_host)
		end

feature -- Access

	count: INTEGER

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
			print ("Closed: "+ a_code.out + " - " + a_reason)
		end

	on_error (a_error: STRING)
		do
			print ("Error: "+ a_error)
		end


	connection: TCP_STREAM_SOCKET
		do
			Result := socket
		end


end
