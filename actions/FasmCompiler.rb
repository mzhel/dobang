class FasmCompiler

	def initialize
	
		@pathAliases = {}
		
		@srcLst = []
		
		@objLst = []
		
		@objDir = nil
		
		ParsePathAliases(ENV['home'] + '/vcbuildconf')
	
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

	def TouchDir(name)
	
		begin
		
			Dir.mkdir(name)
		
		rescue
		
		end
		
	end
	
	def Sources(rawStr)
	
		r = ""
		
		rawStr.split(" ").each do |s|
		
			r << %Q{#{s} }
			
			@srcLst << s
			
		end
		
		r
	
	end
	
	def Objects(rawStr)
	
		r = ""
		
		rawStr.split(" ").each do |s|
		
			r << %Q{#{s} }
			
			@objLst << s
			
		end
		
		r
	
	end
	
	def CompilerString(opts)
	
		r = "fasm "
		
		preDefs = GetVar(:defines)
		
		r << preDefs if preDefs
		
		opts.each_pair do |key, value|
		
			case key
				
				when "OBJECTS"
				
					Objects(value)
			
				when "OBJDIR"
					
					TouchDir(value)
					
					@objDir = value
				
				when "SOURCES"
				
					Sources(value)
			
			end
		
		end
		
		r
	
	end
	
	def Ext(s, e)
	
		s.gsub(/\.\w+$/, '.' + e)
	
	end
	
	#
	# Callbacks from core
	#
	
	def Do(opts)
	
		r = false
		
		error = false
	
		begin
	
			str = CompilerString(opts)
		
			@srcLst.each_index do |i|
			
				src = @srcLst[i]
				
				obj = @objLst[i]
				
				out  str + src + ' ' + @objDir + obj
				
				out shellCmd str + src + ' ' + @objDir + obj
				
				if shellExitStatus != 0
				
					error = true
					
					break
				
				end
			
			end
			
			break if error			
		
			# Save built objects names to environment
			
			objs = []
			
			@srcLst.each_index do |i|
			
				s = @srcLst[i]
				
				o = @objLst[i]
			
				objs << "#{(@objDir?(@objDir):('')) + o}"
			
			end
			
			preObjs = GetVar(:objects)
			
			objs = preObjs + objs if preObjs
			
			SetVar(:objects, objs)
			
			r = true
		
		end while false
		
		r
		
	end

end
