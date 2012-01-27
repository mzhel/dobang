class Do

	def initialize
	
		@actions = []
	
	end
	
	def ClassObjByName(className)
	
		r = nil
		
		if className.instance_of? String
		
			ObjectSpace.each_object(Class) do |classObj|
			
				if classObj.to_s == className
				
					r = classObj
					
					break;
					
				end
				
			end
			
		end
		
		r
	end
	
	def GetClassNameFromFile(filePath)
	
		r = nil
		
		if filePath.instance_of? String
		
			File.open(filePath) do |f|
			
				f.each_line do |l|
				
					if l=~/class ([A-Za-z0-9]+)/
					
						r = $1
						
						break
						
					end
					
				end
				
			end
		
		end
		r
	end
	
	def LoadCmdHandlers2(path)
		
		# Create class instance for each handler in directory.
		
		Dir["#{path}/*.rb"].each do |f|
		
		
			# [TODO] wrap require into exception handler.
			
			require(f)
			
			clsInst = ClassObjByName(GetClassNameFromFile(f))
			
			runtimeInst = clsInst.send(:new, nil)
			
			if runtimeInst != nil

				@actions << runtimeInst
				
			end
			
		end
	end
	
	def LoadActions(pathArr)
		
		begin
			
			break if !pathArr.kind_of? Array
			
			pathArr.each do |path|
			
				LoadCmdHandlers2(path)
				
			end
		
		end while false
		
	end
	
	def CallCmdHandler(cmdStr)
	
		r = nil
	
		cmd, *args = cmdStr.split("|")
		
		cmd = 'cmd_' + cmd
		
		@cmdHandlers.each do |ch|
		
			if ch.respond_to? cmd
			
				argsCount = ch.method(cmd).arity
				
				r = ch.send(cmd, *args) if argsCount == args.length
				
			end
			
		end
		
		r
		
	end
	
	def do
	
		LoadActions(["./actions"])
		
	end

end