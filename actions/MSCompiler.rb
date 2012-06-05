class MSCompiler

	def initialize
	
		@pathAliases = {}
		
		@srcLst = []
		
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
		
			r << %Q{/I "#{i}" }
		
		end
		
		r
	
	end
	
	def Defines(rawStr)
	
		r = ""
		
		rawStr.split(" ").each do |d|
		
			r << %Q{/D "#{d}" }
		
		end
		
		r
	
	end
	
	def CompilerString(opts)
	
		r = "cl "
		
		expDir = nil
		
		preDefs = GetVar(:defines)
		
		r << preDefs if preDefs
		
		opts.each_pair do |key, value|
		
			case key
			
				when "DEFINE"
				
					r << Defines(value)
					
				when "INCLUDE"
				
					r << Includes(value)
				
				when "KEYS"
				
					r << Keys(value)
					
				when "OBJDIR"
				
					expDir = SubVar(value)
				
					TouchDir(expDir)
					
					@objDir = value
									
					r << "/Fo#{expDir} "
					
				when "PDBDIR"
				
					expDir = SubVar(value)
				
					TouchDir(expDir)
				
					r << "/Fd#{expDir} "
					
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
			
			@srcLst.each do |src|
				
				puts str + src
				
				out %x[#{str + src}]
				
				if $?.exitstatus != 0
				
					error = true
					
					break
				
				end
			
			end
			
			break if error			
		
			# Save built objects names to environment
			
			objs = []
			
			@srcLst.each do |s|
			
				objs << "#{(@objDir?(@objDir):('')) + Ext(s, 'obj').scan(/([\w-]*\..{0,3}$)/)[0][0]}"
			
			end
			
			preObjs = GetVar(:objects)
			
			objs = preObjs + objs if preObjs
			
			SetVar(:objects, objs)
			
			r = true
		
		end while false
		
		r
		
	end

end
