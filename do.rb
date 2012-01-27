require 'pp'
class Do

	CONF_FILE_NAME = 'doconf'

	def initialize
	
		@actions = []
	
	end
	
	def Output(str)
	
		puts str
	
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
		
		inst.send :instance_eval, out
	
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
	
		inst.send(name,*args)
	
	end
	
	def ExecActionsForDir(actFile, callKey)
	
		act = nil
		
		key = nil
	
		File.open(actFile) do |f|
		
			f.each_line do |l|
			
				if l =~ /^\[(\w+)\]$/
				
					act = LoadAction($1)
				
				elsif l =~ /^(\w+):$/
				
				key = $1
					
				elsif l =~ /(\w+)=(\w+)/
				
					if act
					
						CallActModuleCb(act, 'SetOption', key, $1, $2)
					
					end
				
				end
			
			end
		
		end
		
		if act
		
			CallActModuleCb(act, 'Do', callKey)
		
		end
	
	end
	
	def ActionsForDir(name, key)
	
		Dir[name].each do |d|
		
			if d != '.' && d != '..'
			
				if File.directory?(d)
				
					ActionsForDir(d + '/*', key)
					
				elsif d =~ /#{CONF_FILE_NAME}$/
				
					ExecActionsForDir(d, key)
					
				end
		
			end
		
		end
	
	end
	
	def do(key)
	
		EnumActionModules(["./actions"])
		
		ActionsForDir(Dir.pwd + '/*', key)
		
	end

end

key = nil

key = ARGV[0] if ARGV[0]

Do.new.do(key)