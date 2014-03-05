class Archiver

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

	def Objs(objLst)
	
		r = ""
		
		objLst.each do |o|
		
			r << "#{SubVar(o)} "
		
		end
		
		r		
	
	end

	def ArchiverString(opts, objLst)
	
		r = "ar -cvq "
		
		TouchDir(opts['TARGETDIR'])
		
		r << %Q{"#{opts['TARGETDIR']}#{opts['TARGETNAME']}" }
		
		r << Objs(objLst)
		
		r
		
	end
	
	#
	# Callbacks
	#
	
	def Do(opts)
	
		str = ArchiverString(opts, GetVar(:objects))
	
		out str
	
		out shellCmd str
		
		(shellExitStatus > 0)?(false):(true)
		
	end

end
