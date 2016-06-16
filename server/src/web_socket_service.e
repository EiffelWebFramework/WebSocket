note
	description: "Summary description for {WEB_SOCKET_SERVICE}."
	date: "$Date$"
	revision: "$Revision$"

deferred class
	WEB_SOCKET_SERVICE [G -> WEB_SOCKET_REQUEST_HANDLER create make end]

feature {NONE} -- Initialization

	make_and_launch
		do
			make
			launch
		end

	make
		local
			fac: like request_handler_factory
		do
			create <NONE> fac
			request_handler_factory := fac
			create server.make (fac)
			setup (server.configuration)
		end

	setup (cfg: HTTPD_CONFIGURATION)
			-- Setup server configuration `cfg'.
		deferred
		end

feature -- Execution		

	launch
		do
			update_factory (request_handler_factory, server_configuration)
			server.launch
		end

feature {NONE} -- Access / implementation

	request_handler_factory: separate WEB_SOCKET_REQUEST_HANDLER_FACTORY [G]

	server: HTTPD_SERVER
			-- Associated httpd server.

	update_factory (fac: like request_handler_factory; a_conf: HTTPD_CONFIGURATION)
		do
			fac.update_with (a_conf)
		end

feature -- Access

	server_configuration: HTTPD_CONFIGURATION
			-- Server configuration.
		do
			Result := server.configuration
		end

invariant

end
