class Pather

	#
	# Callbacks from core
	#
	
	def initialize
	
		@pathAliases = {}
		
		ParsePathAliases(ENV['home'] + '/pather_aliases')
	
	end
	
	def ParsePathAliases(path)

		if File.exist? path
		
			File.open(path) do |f|
		
				f.each_line do |l|
			
					name, value = l.split('=')
				
					@pathAliases[name] = value.chop!
				
				end
		
			end

		end
	
	end
	
	def Do(opts)

		opts.each_pair do |key, value|
		
			value = @pathAliases[value] if @pathAliases[value]
		
			out "Adding %s to PATH environment variable"%value
		
			ENV['PATH'] += ';' + value
		
		end
	end

end