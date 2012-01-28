require "fileutils"

class Deployer

	include FileUtils

	def initialize
	
		@opts = {}
	
	end
	
	def Opt(key, value)
	
		@opts[key] = value
	
	end
	
	def Do
	
			@opts.each_pair do |file, dest|
			
				out "Deploying %s to %s"%[file, dest]
			
				begin
				
					cp(file, dest, :preserve=>true)
					
					out "OK"
					
				rescue
				
					out "FAILED"
					
				end
			
			end
			
			true
	
	end

end