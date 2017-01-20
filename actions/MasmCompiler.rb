class MasmCompiler

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
	
	def CompilerString(opts)
	
		r = ""
		
		expDir = nil
		
		opts.each_pair do |key, value|
		
			case key
			
				when "INCLUDE"
				
					r << Includes(value)
				
				when "KEYS"
				
					r << Keys(value)
					
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
	
		s.scan(/\.\w+$/)[0]
	
	end
	
	#
	# Callbacks from core
	#
	
	def Do(opts)
	
		r = false
		
		error = false
		
		StorageOpen('msac.dat')
		
		objs = []
		
		begin
		
			cmdWithParams = nil
			
			str = CompilerString(opts)
			
			preAsmFiles = GetVar(:asmFiles)
			
			if preAsmFiles
			
				preAsmFiles.each do |asmFile|
				
					@srcLst << asmFile
				
				end
			
			end
			
			@srcLst.each do |src|
			
				oldMtime = StorageLoad(src)
				
				newMtime = File.exists?(src)?File.mtime(src):nil
				
				obj = "#{(@objDir?(@objDir):('')) + Ext(src, 'obj').scan(/([\w-]*\..{0,3}$)/)[0][0]}"
			
				if !oldMtime || (newMtime && oldMtime != newMtime)
			
					cmdWithParams = "ml.exe /Fo #{obj} " + str
					
					shellCmd cmdWithParams + src
					
					if shellExitStatus != 0
					
						error = true
						
						break
					
					end
					
					StorageStore(src, newMtime)
				
				else
			
					out "%s - no modifications detected.\n\n"%src
			
				end
				
				objs << obj
			
			end
			
			break if error
			
			preObjs = GetVar(:objects)
			
			if preObjs
			
				objsToStore = []
			
				objs.each do |obj|
			
					objsToStore << obj if !preObjs.include? obj
			
				end
				
				objs = preObjs + objsToStore
				
			end
			
			SetVar(:objects, objs)
			
			r = true
		
		end while false
		
		StorageClose('msac.dat')
		
		r
	
	end

end