class FasmCompiler

	def initialize
	
		@opts = {}
		
		@pathAliases = {}
		
		@srcLst = []
		
		@objLst = []
		
		@objDir = nil
		
		ParsePathAliases(ENV['home'] + '/vcbuildconf')
	
	end
	
	def ParsePathAliases(path)
		
		File.open(path) do |f|
		
			f.each_line do |l|
			
				name, value = l.split('=')
				
				@pathAliases[name] = value.chop!
			
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
		
		opts.each do |opt|
		
			case opt[0]
				
				when "OBJECTS"
				
					Objects(opt[1])
			
				when "OBJDIR"
					
					TouchDir(opt[1])
					
					@objDir = opt[1]
				
				when "SOURCES"
				
					Sources(opt[1])
			
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
	
	def Opt(name, value)
	
		key = :default
	
		@opts[key] = [] if !@opts[key]
		
		@opts[key] << [name, value]
	
	end
	
	def Do
	
		r = false
		
		error = false
	
		begin
	
			str = CompilerString(@opts[:default])
		
			@srcLst.each_index do |i|
			
				src = @srcLst[i]
				
				obj = @objLst[i]
				
				puts str + src + ' ' + @objDir + obj
				
				out %x[#{str + src + ' ' + @objDir + obj}]
				
				if $?.exitstatus != 0
				
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