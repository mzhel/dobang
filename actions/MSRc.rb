class MSRc

	def initialize
	
		@pathAliases = {}
		
		ParsePathAliases(ENV['home'] + '/vcbuildconf')
		
		@res_path = nil
		
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
	
	def Includes(rawStr)
	
		r = ""
		
		rawStr.split(";").each do |i|
		
			i = @pathAliases[i] if @pathAliases[i]
		
			r << %Q{/I "#{i}" }
		
		end
		
		r
	
	end
	
	def RcString(opts)
		
		r = "rc "
		rc_path = nil
		includes = nil
		
		opts.each_pair do |key, value|
		
			case key
			
				when "OUTFILE"
				
					@res_path = value
					
				when "INFILE"
				
					rc_path = value
					
				when "INCLUDE"
				
					includes = Includes(value)
			
			end
		
		end
		
		r << %Q{/fo"#{@res_path}" #{includes} "#{rc_path}"}
		
		r
	
	end
	
	#
	# Callbacks
	#
	
	def Do(opts)
	
		r = false
	
		begin
	
		str = RcString(opts)
	
		shellCmd str
		
		break if shellExitStatus > 0
		
		objs = [@res_path]

		preObjs = GetVar(:objects)
			
		objs = preObjs + objs if preObjs
			
		SetVar(:objects, objs)
		
		r = true
	
		end while false
		
		r
	end
end
