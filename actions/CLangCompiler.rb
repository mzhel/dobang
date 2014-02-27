class CLangCompiler

	def initialize
	
		@pathAliases = {}
		
		@srcLst = []
		
		@objDir = nil

    @xxKeys = ""
		
		ParsePathAliases(ENV['HOME'] + '/gccbuildconf')
	
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

	def KeysXX(rawStr)
	
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
		
			r << %Q{-I "#{i.gsub(/^\s+/, "")}" }
		
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
	
		r = "clang -c "
		
		expDir = nil
		
		preDefs = GetVar(:defines)

    @xxKeys = ""
		
		r << preDefs if preDefs
		
		opts.each_pair do |key, value|
		
			case key
			
				when "DEFINE"
				
					r << Defines(value)
					
				when "INCLUDE"
				
					r << Includes(value)
				
				when "KEYS"
				
					r << Keys(value)
				
        when "KEYSXX"
				
					@xxKeys << KeysXX(value)

				when "OBJDIR"
				
					expDir = SubVar(value)
				
					TouchDir(expDir)
					
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

  def GetExt(s)

    r = ""

    md = /\.(\w+)$/.match(s)

    if md

      r = md[1]

    end

    r

  end
	
	#
	# Callbacks from core
	#
	
	def Do(opts)
	
		r = false
		
		error = false

    StorageOpen("clangc.dat")
		
		begin
	
			str = CompilerString(opts)
			
			@srcLst.each do |src|

        oldMtime = StorageLoad(src)

        newMtime = File.exists?(src)?File.mtime(src):nil

        if !oldMtime || (newMtime && oldMtime != newMtime)

				  execStr = str + ((GetExt(src) == "cpp")?@xxKeys:"") + src + " -o #{(@objDir?(@objDir):('')) + Ext(src, 'o').scan(/([\w-]*\..{0,3}$)/)[0][0]}"

          puts execStr
				
	  			out %x[#{execStr}]
				
		  		if $?.exitstatus != 0
				
			  		error = true
					
				  	break
				
				  end

          StorageStore(src, newMtime)

        else

					#out "%s - no modifications detected.\n\n"%src

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

    StorageClose("clangc.dat")
		
		r
		
	end

end
