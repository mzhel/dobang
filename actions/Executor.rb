class Executor

	def Do(opts)
	
		exec = []
	
		opts.each_pair do |k, v|
		
			exec[k.to_i] = v

		end
		
		r = true
		
		exec.each do |str|
		
			shellCmd str
			
			if shellExitStatus != 0
			
				r = false
				
				break
			
			end
		
		end
		
	end

end