class Environment

	def Do(opts)
		
		opts.each_pair do |key, value|
		
			out "%s = %s"%[key, value]
		
			ENV[key] = value
		
		end
	
	end

end