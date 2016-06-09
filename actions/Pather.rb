class Pather

	#
	# Callbacks from core
	#
	
	def Do(opts)

		opts.each_pair do |key, value|
		
			out "Adding %s to PATH environment variable"%value
		
			ENV['PATH'] += ';' + value
		
		end
	end

end