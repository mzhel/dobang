require "fileutils"

class Deployer

	include FileUtils

	def initialize
	
	end
	
	def Do(opts)
	
			opts.each_pair do |file, destLst|
			
				destLst.split(",").each do |dest|
			
					out "Deploying %s to %s"%[file, dest]
				
					begin
					
						cp(file, dest, :preserve=>true)
						
						out "OK"
						
					rescue
					
						out "FAILED"
						
					end
				
				end
			
			end
			
			true
	
	end

end
