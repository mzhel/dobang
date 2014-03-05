class MSMt

	def initialize
		
	end
	
	def MtString(opts)
		
		r = "mt "
		
		r << %Q{-manifest "#{opts['MANIFEST']}"}
		
		r << %Q{ -outputresource:"#{opts['OUTRESOURCE']}"}
		
		r
	
	end
	
	#
	# Callbacks
	#
	
	def Do(opts)
	
		str = MtString(opts)
	
		out str
	
		out shellCmd str
		
		(shellExitStatus > 0)?(false):(true)
		
	end

end
