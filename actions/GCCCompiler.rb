class GCCCompiler

	def initialize
	
		@opts = {}
		
		@pathAliases = {}
		
		@srcLst = []
		
		@objDir = nil
		
		ParsePathAliases(ENV['home'] + '/gccbuildconf')
	
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
	
	def Keys(rawStr)
	
		r = ""
		
		rawStr.split(";").each do |k|
		
			r << %Q{#{k} }
		
		end
		
		r
	
	end
	
	def Includes(rawStr)
	
		r = ""
		
		rawStr.split(";").each do |i|
		
			i = @pathAliases[i] if @pathAliases[i]
		
			r << %Q{-I "#{i}" }
		
		end
		
		r
	
	end
	
	def Defines(rawStr)
	
		r = ""
		
		rawStr.split(" ").each do |d|
		
			r << %Q{-D "#{d}" }
		
		end
		
		r
	
	end
	
	def CompilerString(opts)
	
		r = "gcc -c "
		
		expDir = nil
		
		preDefs = GetVar(:defines)
		
		r << preDefs if preDefs
		
		opts.each do |opt|
		
			case opt[0]
			
				when "DEFINE"
				
					r << Defines(opt[1])
					
				when "INCLUDE"
				
					r << Includes(opt[1])
				
				when "KEYS"
				
					r << Keys(opt[1])
					
				when "OBJDIR"
				
					expDir = SubVar(opt[1])
				
					TouchDir(expDir)
					
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
			
			@srcLst.each do |src|
			  
				execStr = str + src + " -o #{(@objDir?(@objDir):('')) + Ext(src, 'o').scan(/([\w-]*\..{0,3}$)/)[0][0]}"
				
				puts execStr
				
				out %x[#{execStr}]
				
				if $?.exitstatus != 0
				
					error = true
					
					break
				
				end
			
			end
			
			break if error			
		
			# Save built objects names to environment
			
			objs = []
			
			@srcLst.each do |s|
			
				objs << "#{(@objDir?(@objDir):('')) + Ext(s, 'o').scan(/([\w-]*\..{0,3}$)/)[0][0]}"
			
			end
			
			preObjs = GetVar(:objects)
			
			objs = preObjs + objs if preObjs
			
			SetVar(:objects, objs)
			
			r = true
		
		end while false
		
		r
		
	end

end