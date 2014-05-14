note
	description: "Summary description for {HTTP_CONNECTION_HANDLER}."
	date: "$Date$"
	revision: "$Revision$"

class
	HTTP_CONNECTION_HANDLER

inherit
	HTTP_CONNECTION_HANDLER_I
		redefine
			initialize
		end

create
	make

feature {NONE} -- Initialization

	initialize
		local
			n: INTEGER
			p: like pool
		do
			n := max_concurrent_connections (server)
			create p.make (n)
			initialize_pool (p, n)
			pool := p
		end

	initialize_pool (p: like pool; n: INTEGER)
 		do
			p.set_count (n)
 		end

feature -- Access

	is_shutdown_requested: BOOLEAN

	max_concurrent_connections (a_server: like server): INTEGER
		do
			Result := a_server.configuration.max_concurrent_connections
		end

feature {HTTP_SERVER} -- Execution

	shutdown
		do
			if not is_shutdown_requested then
				is_shutdown_requested := True
				pool_gracefull_stop (pool)
			end
		end

	pool_gracefull_stop (p: like pool)
		do
			p.gracefull_stop
		end

	process_incoming_connection (a_socket: HTTP_STREAM_SOCKET)
		do
			debug ("dbglog")
				dbglog (generator + ".before process_incoming_connection {"+ a_socket.descriptor.out +"} -- SCOOP WAIT!")
			end
			process_connection (a_socket, pool) -- Wait on not pool.is_full or is_stop_requested
			debug ("dbglog")
				dbglog (generator + ".after process_incoming_connection {"+ a_socket.descriptor.out +"}")
			end
		end

	process_connection (a_socket: HTTP_STREAM_SOCKET; a_pool: like pool)
			-- Process incoming connection
			-- note that the precondition matters for scoop synchronization.
		require
			concurrency: not a_pool.is_full or is_shutdown_requested or a_pool.stop_requested
		do
			debug ("dbglog")
				dbglog (generator + ".ENTER process_connection {"+ a_socket.descriptor.out +"}")
			end
			if is_shutdown_requested then
				a_socket.cleanup
			elseif attached a_pool.separate_item (factory) as h then
				process_connection_handler (h, a_socket)
			else
				check is_not_full: False end
				a_socket.cleanup
			end
			debug ("dbglog")
				dbglog (generator + ".LEAVE process_connection {"+ a_socket.descriptor.out +"}")
			end
		end

	process_connection_handler (hdl: separate HTTP_REQUEST_HANDLER; a_socket: HTTP_STREAM_SOCKET)
		require
			not hdl.has_error
		do
				--| FIXME jfiat [2011/11/03] : should use a Pool of Threads/Handler to process this connection
				--| also handle permanent connection...?

			debug ("dbglog")
				dbglog (generator + ".ENTER process_connection_handler {"+ a_socket.descriptor.out +"}")
			end
			hdl.set_client_socket (a_socket)
			if not hdl.has_error then
--				hdl.set_logger (server)
				hdl.execute
			else
				log ("Internal error (set_client_socket failed)")
			end
			debug ("dbglog")
				dbglog (generator + ".LEAVE process_connection_handler {"+ a_socket.descriptor.out +"}")
			end
		rescue
			log ("Releasing handler after exception!")
			hdl.release
			a_socket.cleanup
		end

feature {HTTP_SERVER} -- Status report

	wait_for_completion
			-- Wait until Current is ready for shutdown
		do
			wait_for_pool_completion (pool)
		end

	wait_for_pool_completion (p: like pool)
		require
			p.is_empty
		do
			p.terminate
		end

feature {NONE} -- Access

	pool: separate CONCURRENT_POOL [HTTP_REQUEST_HANDLER]
			-- Pool of separate connection handlers.

	retrieve_keep_alive (a_server: like server): INTEGER
			-- Keep alive timeout
		do
			Result := a_server.configuration.keep_alive_timeout
		end
invariant
	pool_attached: pool /= Void

note
	copyright: "2011-2013, Javier Velilla, Jocelyn Fiat and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end
