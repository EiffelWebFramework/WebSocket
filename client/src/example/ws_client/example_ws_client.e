note
	description: "Summary description for {EXAMPLE_WS_CLIENT}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	EXAMPLE_WS_CLIENT

inherit

	WEB_SOCKET_CLIENT


create
	make,
	make_with_port


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

feature -- Access

	count: INTEGER

feature -- Event
	on_open (a_message: STRING)
		do
			print (a_message)
			on_text_message (a_message)
		end

	on_text_message (a_message: STRING)
		local
			l_message: STRING
		do
			if count <= 10 then
				print ("%NCount:" + count.out)
				send (a_message)
				count := count + 1
			else -- Send close initiated by the client
				close (1001)
			end
		end

	on_binary_message (a_message: STRING)
		do
			send_binary (a_message)
		end

	on_close (a_code: INTEGER; a_reason: STRING)
		do
			ready_state.set_state ({WEB_SOCKET_READY_STATE}.closed)
		end

	on_error (a_error: STRING)
		do
		end


	connection: TCP_STREAM_SOCKET
		do
			Result := socket
		end


end
