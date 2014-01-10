note
	description: "Summary description for {WS_ERROR_FRAME}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	WS_ERROR_FRAME

create
	make

feature {NONE} -- Initialization

	make (a_code: INTEGER; a_desc: like description)
		do
			code := a_code
			description := a_desc
		end

feature -- Access

	code: INTEGER

	description: READABLE_STRING_8


end
