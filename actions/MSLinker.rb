class MSLinker

	def initialize
		
		@pathAliases = {}
		
		ParsePathAliases(ENV['home'] + '/vcbuildconf')
	
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
	
	def Libdirs(rawStr)
	
		r = ""
		
		rawStr.split(";").each do |d|
		
			d.strip!
		
			d = @pathAliases[d] if @pathAliases[d]
		
			r << %Q{/LIBPATH:"#{d}" }
		
		end
		
		r	
			
	end
	
	def Libs(rawStr)
	
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
	
		r = "link "
		
		TouchDir(opts['TARGETDIR'])
		
		r << %Q{/OUT:"#{opts['TARGETDIR']}#{opts['TARGETNAME']}" }
		
		r << Keys(opts['KEYS'])
		
		r << "/SUBSYSTEM:#{opts['TARGETTYPE']} "		
		
		r << Libdirs(opts['LIBDIRS'])
		
		r << Libs(opts['LIBS'])
		
		r << Objs(objLst)
		
		r
		
	end
	
	#
	# Callbacks
	#
	
	def Do(opts)
	
		str = LinkerString(opts, GetVar(:objects))
	
		shellCmd str
		
		(shellExitStatus > 0)?(false):(true)
		
	end

end
