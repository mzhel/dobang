class CLangXXLinker

	def initialize
		
		@pathAliases = {}
		
		ParsePathAliases(ENV['HOME'] + '/gccbuildconf')
	
	end
	
	def TouchDir(name)
	
		begin
		
			Dir.mkdir(name)
		
		rescue
		
		end
		
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
	
	
	def Keys(rawStr)
	
		r = ""
		
		rawStr.split(" ").each do |k|
		
			r << "#{k} "
	
		end
		
		r
	
	end

	def LibDirs(rawStr)

		r = ""

		rawStr.split(';').each do |l|

			r << "-L#{l} "

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
	
	def StaticLibs(rawStr)
	  
	  r = ""
	  
	  rawStr.split(' ').each do |l|
	    
	    r << "#{l} "
	    
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
	
		r = "clang++ "
		
		TouchDir(opts['TARGETDIR'])
		
		r << %Q{-o "#{opts['TARGETDIR']}#{opts['TARGETNAME']}" }
		
		r << Keys(opts['KEYS']) if opts['KEYS']
				
		r << Objs(objLst)
		
		r << StaticLibs(opts['STATIC_LIBS']) if opts['STATIC_LIBS']

		r << LibDirs(opts['LIBDIRS']) if opts['LIBDIRS']

		r << Libs(opts['LIBS']) if opts['LIBS']

		r
		
	end
	
	#
	# Callbacks
	#
	
	def Do(opts)
	
		str = LinkerString(opts, GetVar(:objects))
	
		puts str
	
		out %x[#{str}]
		
		($?.exitstatus > 0)?(false):(true)
		
	end

end
