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
	
		puts str
	
		out %x[#{str}]
		
		($?.exitstatus > 0)?(false):(true)
		
	end
end
