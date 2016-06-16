note
	description: "Summary description for {WEB_SOCKET_REQUEST_HANDLER_FACTORY}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	WEB_SOCKET_REQUEST_HANDLER_FACTORY [G -> WEB_SOCKET_REQUEST_HANDLER create make end]

inherit
	HTTPD_REQUEST_HANDLER_FACTORY

feature -- Access

	request_settings: HTTPD_REQUEST_SETTINGS
			-- Expanded object representing settings related to HTTP request handling.

feature -- Element change

	update_with (a_cfg: separate HTTPD_CONFIGURATION)
		do
			request_settings := a_cfg.request_settings
		end

feature -- Factory

	new_handler: separate G
		do
			create Result.make (request_settings)
		end

note
	copyright: "2011-2016, Javier Velilla, Jocelyn Fiat and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
end
