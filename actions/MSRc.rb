class MSRc

	def initialize
	
		@pathAliases = {}
		
		ParsePathAliases(ENV['home'] + '/vcbuildconf')
		
		@res_path = nil
		
		@rc_path = nil
		
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
		
			i.strip!
		
			i = @pathAliases[i] if @pathAliases[i]
		
			r << %Q{/I "#{i}" }
		
		end
		
		r
	
	end
	
	def RcString(opts)
		
		r = "rc "
		includes = nil
		
		opts.each_pair do |key, value|
		
			case key
			
				when "OUTFILE"
				
					@res_path = value
					
				when "INFILE"
				
					@rc_path = value
					
				when "INCLUDE"
				
					includes = Includes(value)
			
			end
		
		end
		
		r << %Q{/fo"#{@res_path}" #{includes} "#{@rc_path}"}
		
		r
	
	end
	
	#
	# Callbacks
	#
	
	def Do(opts)
	
		r = false
		
		StorageOpen('msrc.dat')
	
		begin
	
			str = RcString(opts)
			
			oldMtime = StorageLoad(@rc_path)
				
			newMtime = File.exists?(@rc_path)?File.mtime(@rc_path):nil
			
			if !oldMtime || (newMtime && oldMtime != newMtime)
		
				shellCmd str
				
				break if shellExitStatus > 0
				
				StorageStore(@rc_path, newMtime)
				
			else
			
				out "%s - no modifications detected.\n\n"%@rc_path
			
			end
			
			objs = [@res_path]

			preObjs = GetVar(:objects)
				
			objs = preObjs + objs if preObjs
				
			SetVar(:objects, objs)
			
			r = true
	
		end while false
		
		StorageClose('msrc.dat')
		
		r
		
	end
end
