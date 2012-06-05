class Definer

	def initialize
	
	end
	
	def Do(opts)
	
		defStr = ""
		
		opts.each_pair do |k, v|
		
			defStr << %Q{/D "#{k}#{(v)?('='):('')}#{v}" }
		
		end
	
		SetVar(:defines, defStr)
		
		true
	
	end

end
