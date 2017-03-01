class MSCompiler

	def initialize
	
		@pathAliases = {}
		
		@srcLst = []
		
		@objDir = nil
		
		@asmDir = nil
		
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
		
			i.strip!
		
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
	
		r = ""
		
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
				
				when "ASMDIR"
				
					expDir = SubVar(value)
					
					@asmDir = expDir
					
					TouchDir(expDir)
					
					r << "/Fa#{expDir} "
					
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
	
		s.scan(/\.\w+$/)[0]
	
	end
	
	#
	# Callbacks from core
	#
	
	def Do(opts)
	
		r = false
		
		error = false
		
		StorageOpen('mscc.dat')
		
		begin
		
			cmdWithParams = nil
			
			asmFiles = []
	
			str = CompilerString(opts)
			
			@srcLst.each do |src|
			
				oldMtime = StorageLoad(src)
				
				newMtime = File.exists?(src)?File.mtime(src):nil
				
				if !oldMtime || (newMtime && oldMtime != newMtime)
				
					# [TRY] Adding /TC or /TP keys depending from file extension.
					
					if '.cpp' == GetExt(src)
					
						cmdWithParams = 'cl /TP ' + str
					
					elsif '.c' == GetExt(src)
					
						cmdWithParams = 'cl /TC ' + str
						
					else
					
						cmdWithParams = 'cl ' + str					
					
					end
					
					if @asmDir
					
						asm = "#{@asmDir + Ext(src, 'asm').scan(/([\w-]*\..{0,3}$)/)[0][0]}"
						
						asmFiles << asm
						
					end
			
					shellCmd cmdWithParams + src
					
					if shellExitStatus != 0
					
						error = true
						
						break
					
					end
					
					StorageStore(src, newMtime)
					
				else
				
					out "%s - no modifications detected.\n\n"%src
				
				end
			
			end
			
			break if error
			
			if asmFiles.length > 0

				preAsmFiles = GetVar(:asmFiles)
			
				asmFiles = preAsmFiles + asmFiles if preAsmFiles
			
				SetVar(:asmFiles, asmFiles)
			
			end
		
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
		
		StorageClose('mscc.dat')
		
		r
		
	end

end
