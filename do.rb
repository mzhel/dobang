require 'pp'
class Do

	CONF_FILE_NAME = 'dofile'
	
	SETOPT_CB_NAME	= 'Opt'

	def initialize
	
		@actions = []
		
		@actModEnv = {}
	
	end
	
	def Output(str)
	
		puts str
	
	end
	
	def SetModEnvVar(k, v)
	
		@actModEnv[k] = v
	
	end
	
	def GetModEnvVar(k)
	
		@actModEnv[k]
	
	end
	
	def ClassObjByName(className)
	
		r = nil
		
		if className.instance_of? String
		
			ObjectSpace.each_object(Class) do |classObj|
			
				if classObj.to_s == className
				
					r = classObj
					
					break;
					
				end
				
			end
			
		end
		
		r
	end
	
	def GetClassNameFromFile(filePath)
	
		r = nil
		
		if filePath.instance_of? String
		
			File.open(filePath) do |f|
			
				f.each_line do |l|
				
					if l=~/class ([A-Za-z0-9]+)/
					
						r = $1
						
						break
						
					end
					
				end
				
			end
		
		end
		
		r
		
	end
	
	def SetModuleVar (inst, var, value)
	
		inst.instance_variable_set(var, value)
		
	end
	
	def SetModuleEnv(inst)
	
		SetModuleVar(inst, :@core, self);
		
		out = "def out(str);@core.Output(str);end"
		
		setVar = "def SetVar(k, v);@core.SetModEnvVar(k, v);end"
		
		getVar = "def GetVar(k);@core.GetModEnvVar(k);end"
		
		inst.send :instance_eval, out
		
		inst.send :instance_eval, setVar
		
		inst.send :instance_eval, getVar
		
	end
	
	def LoadActionModule(name)
	
		r = nil
	
		# [TODO] wrap require into exception handler.
			
		require(name)
			
		clsInst = ClassObjByName(GetClassNameFromFile(name))
			
		r = clsInst.send(:new)
			
		if r != nil

			SetModuleEnv(r)
				
		end
		
		r
	
	end
	
	def EnumActionModulesForDir(path)
	
		Dir["#{path}/*.rb"].each do |fname|
		
			actCls = GetClassNameFromFile(fname)
			
			if actCls
			
				@actions << {:fname=> fname, :name => actCls};
			
			end
		
		end
	
	end
	
	def EnumActionModules(pathArr)
	
		begin
			
			break if !pathArr.kind_of? Array
			
			pathArr.each do |path|
			
				EnumActionModulesForDir(path)
				
			end
		
		end while false
	
	end
	
	def LoadAction(name)
	
		r = nil;
		
		act = nil
	
		@actions.each do |a|
		
			if a[:name] == name
			
				act = LoadActionModule(a[:fname])
				
				if act
				
					a[:inst] = act
					
					r = act
					
					break
				
				end
			
			end
		
		end
		
		r
	
	end
	
	def CallActModuleCb(inst, name, *args)
	
		inst.send(name,*args) if inst.respond_to?(name)
	
	end
	
	def ExecActionsForDir(actFile, callSeq, callKeyLst)
	
		callKey = false
	
		execRes = false
	
		fullLine = false
		
		actLst = []
		
		seqLst = []
	
		act = nil
		
		key = :default
		
		line = ""
		
		keys = []
	
		File.open(actFile) do |f|
		
			f.each_line do |l|
			
				fullLine = false
			
				if l =~ /(.*)\\$/
				
					line << $1
				
				else
				
					line << l
					
					fullLine = true
				
				end
				
				next if !fullLine
				
				if line =~ /^\[(\w+)\]$/
				
					actLst << act if act
					
					key = :default
				
					act = {:name => $1, :opts => {}}
				
				elsif line =~ /^(\w+):$/
				
					key = $1
					
				elsif line =~ /([\w.\/]+)=(.*)/
				
					if act
					
						act[:opts][key] = [] if !act[:opts][key]
						
						act[:opts][key] << [$1, $2]
					
					end
					
				elsif line =~ /(\w+) >> \[([A-Za-z, ]+)\]/
				
					seq = $2.split(',')
					
					seqLst << [$1, seq]
				
				end
				
				line = ''
			
			end
			
			actLst << act if act
		
		end
		
		begin
		
			error = false
		
			seq = seqLst.find {|s| callSeq == s[0]}
		
			if !seq
				
				Output "Sequence %s not found in config file."%callSeq
				
				break
				
			end
			
			seq[1].each do |actName|
			
				act = LoadAction(actName)
				
				if !act
				
					Output "Failed to load action module %s."%actName
					
					error = true
					
					break
				
				end
				
				# Check if there is config for loaded action.
				
				actData = actLst.find {|a| a[:name] == actName}
				
				if actData
				
					callKeyLst.each do |callKey|
					
						# If options in default key section and in called key section
						# have same names we need to default key option data to
						# called key option data.
						
						if actData[:opts][callKey] && actData[:opts][:default] && callKey != :default
						
							actData[:opts][callKey].each do |o|
							
								doubleOpt = actData[:opts][:default].find {|co| co[0] == o[0]}
								
								if doubleOpt
								
									o[1] << ' ' << doubleOpt[1]
								
									actData[:opts][:default].delete(doubleOpt)
								
								end
							
							end
						
						end

					end
					
					callKeyLst.each do |callKey|
					
						if actData[:opts][callKey]
					
							actData[:opts][callKey].each do |o|
							
								CallActModuleCb(act, SETOPT_CB_NAME, o[0], o[1])
								
							end
						
						end
					
					end
					
				end
				
				r = CallActModuleCb(act, 'Do')
				
				if !r
				
					Output "Module %s reported error, exiting."%actName
					
					error = true
					
					break
				
				end
			
			end
			
			break if error
			
			execRes = true
		
		end while false
		
		execRes
		
	end
	
	def ActionsForDir(name, seq, keyLst)
	
		r = false
	
		Dir[name].each do |d|
		
			if d != '.' && d != '..'
			
				if File.directory?(d)
				
					ActionsForDir(d + '/*', seq, keyLst)
					
				elsif d =~ /#{CONF_FILE_NAME}$/
				
					r = ExecActionsForDir(d, seq, keyLst)
					
					break if !r
					
				end
		
			end
		
		end
		
		r
	
	end
	
	def Do(seq, keyLst)
	
		EnumActionModules([ENV['DO_HOME'] + '/actions', "./actions"])
		
		ActionsForDir(Dir.pwd + '/*', seq, keyLst)
		
	end

end

keyLst = [:default]

seq = nil

ARGV.each_index do |i|

	if i == 0
	
		seq = ARGV[i]
	
	else
	
		keyLst << ARGV[i]
	
	end

end

exit if (!seq)

exit(Do.new.Do(seq, keyLst))