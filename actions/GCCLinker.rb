class GCCLinker

	def initialize
		
		@opts = {}
		
		@pathAliases = {}
		
		ParsePathAliases(ENV['home'] + '/gccbuildconf')
	
	end
	
	def TouchDir(name)
	
		begin
		
			Dir.mkdir(name)
		
		rescue
		
		end
		
	end
	
	def ParsePathAliases(path)
		
		File.open(path) do |f|
		
			f.each_line do |l|
			
				name, value = l.split('=')
				
				@pathAliases[name] = value.chop!
				

			
			end
		
		end
	
	end
	
	def Keys(rawStr)
	
		r = ""
		
		rawStr.split(" ").each do |k|
		
			r << "#{k} "
	
		end
		
		r
	
	end
	
	def Libs(rawStr)
	
		r = ""
	
		rawStr.split(' ').each do |l|
		
			r << "-l#{l} "
		
		end
		
		r
	
	end
	
	def Objs(objLst)
	
		r = ""
		
		objLst.each do |o|
		
			r << "#{SubVar(o)} "
		
		end
		
		r		
	
	end
	
	def LinkerString(opts, objLst)
	
		r = "gcc "
		
		TouchDir(@opts['TARGETDIR'])
		
		r << %Q{-o "#{opts['TARGETDIR']}#{opts['TARGETNAME']}" }
		
		r << Keys(opts['KEYS']) if opts['KEYS']
		
		r << Libs(opts['LIBS']) if opts['LIBS']
		
		r << Objs(objLst)
		
		r
		
	end
	
	#
	# Callbacks
	#
	
	def Opt(name, value)
	
		if !@opts[name]
		
			@opts[name] = value
		
		else
		
			@opts[name] << ' ' << value
		
		end
	
	end
	
	def Do
	
		str = LinkerString(@opts, GetVar(:objects))
	
		puts str
	
		out %x[#{str}]
		
		($?.exitstatus > 0)?(false):(true)
		
	end

end