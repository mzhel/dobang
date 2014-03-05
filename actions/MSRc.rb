class MSRc

	def initialize
		
	end
	
	def RcString(opts)
		
		r = "rc "
		
		r << %Q{/fo"#{opts['OUTFILE']}" "#{opts['INFILE']}"}
		
		r
	
	end
	
	#
	# Callbacks
	#
	
	def Do(opts)
	
		str = RcString(opts)
	
		out str
	
		out shellCmd
		
		(shellExitStatus > 0)?(false):(true)
		
	end
end
