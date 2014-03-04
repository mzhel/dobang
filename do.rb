require 'pp'

class Storage

	def initialize

		@storage_name = nil
		
		@storage = []

	end

	def Open(name)

		@storage_name = name

		$/ = "---_---"

		if File.exists?(name)

			File.open(name, "rb").each do |o|

				@storage << Marshal::load(o)

			end


		else

			@storage[0] = {}

		end
		
		# Restore to original default vaule.
		
		$/ = "\n"

	end

	def Close(name)

		File.open(name, "wb") do |f|

			@storage.each do |s|

				f.print(Marshal::dump(s))

				f.print "---_---"

			end

		end

	end

	def Store(name, value)

		@storage[0][name] = value

	end

	def Load(name)

		@storage[0][name]

	end

end

class Do

	CONF_FILE_NAME = 'dofile'
	
	def initialize
	
		@actions = []
		
		@actModEnv = {}
		
		@buildErr = false
	
	end
	
	def Output(str)
	
		puts str
	
	end

  def ShellCmd(str)

	  %x[#{str}]

  end

  def PrintSequences(seqLst, aliasLst)

    # seqLst - list of defined execution sequences
    #
    # seqLst => [
    #             [sequence_name, [module1, module2, ...]],
    #             ...
    #           ]

    # aliasLst - list of defined aliases for execution
    # sequences with keys
    #
    # aliasLst => [
    #              [alias_name, [sequence_name, key1, key2, ...]],
    #              ...
    #             ]
    #

    puts "  Sequences:\n\n"

    seqLst.each do |seq|

      print "\t" + seq[0] + " >> "

      puts "[" + (seq[1].inject('') {|r, k| r + k.to_s + ' '}).chop + "]"

    end

    puts "\n  Aliases:\n\n"

    aliasLst.each do |als|

      print "\t" + als[0] + " == "

      puts "[" + (als[1].inject('') {|r, k| r + k.to_s + ' '}).chop + "]"

    end

    puts

  end
	
	def SetModEnvVar(k, v)
	
		@actModEnv[k] = v
	
	end
	
	def GetModEnvVar(k)
	
		@actModEnv[k]
	
	end

  def GetFileContents(fname)

    contents = ""

    line = ""

		File.open(fname) do |f|
		
			f.each_line do |l|
			
				fullLine = false
				
				next if l =~ /^#/
			
				if l =~ /(.*)\\$/
				
					line << $1

				else
				
					line << l
					
					fullLine = true
				
				end
				
				next if !fullLine

        contents << line

        line = ""

      end

    end if File.exist?(fname)

    contents

  end
	
	def SubstModEnvVar(str)
	
		str.sub(/\$ROOTDOFILEDIR/, GetModEnvVar(:rootdofiledir))
	
	end

	def SubstEnvVarsInStr(str)

    md = /@([0-9A-Za-z_\.\\\/-]+)@/.match(str)

    md.captures.each do |c|

      str.gsub!('@' + c.to_s + '@', GetFileContents(c))

    end if md

		@actModEnv.each_pair do |name, value|

			str = str.gsub('$' + name.to_s + '$', value)	if name.kind_of? String

		end

		str

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

		SetModuleVar(inst, :@storage, Storage.new)
		
		out = "def out(str);@core.Output(str);end"

    shellCmd = "def shellCmd(str);@core.ShellCmd(str);end"
		
		setVar = "def SetVar(k, v);@core.SetModEnvVar(k, v);end"
		
		getVar = "def GetVar(k);@core.GetModEnvVar(k);end"
		
		subVar = "def SubVar(s);@core.SubstModEnvVar(s);end"

		storageOpen = "def StorageOpen(name);@storage.Open(name);end"

		storageClose = "def StorageClose(name);@storage.Close(name);end"

		storageStore = "def StorageStore(name, value);@storage.Store(name, value);end"

		storageLoad = "def StorageLoad(name);@storage.Load(name);end"
		
		inst.send :instance_eval, out

		inst.send :instance_eval, shellCmd

		inst.send :instance_eval, out
		
		inst.send :instance_eval, setVar
		
		inst.send :instance_eval, getVar
		
		inst.send :instance_eval, subVar

		inst.send :instance_eval, storageOpen
		
		inst.send :instance_eval, storageClose

		inst.send :instance_eval, storageStore

		inst.send :instance_eval, storageLoad
		
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
	
		inst.send(name, *args) if inst.respond_to?(name)
	
	end
	
	def ExecActionsForDir(actFile, callSeq, callKeyLst, lvl)
	
		skip = false
	
		callKey = false
	
		execRes = false
	
		fullLine = false
		
		cfgAct = nil
		
		cfgDfltKey = nil

    aliasAct = nil

    aliasDfltKey = nil
		
		actLst = []
		
		seqLst = []

		aliasLst = []
	
		act = nil
		
		line = ""
		
		active_keys = []

    print_sequences = false

    if !File.exists?(actFile)

      puts "%s file is not found in the current directory."%actFile

      return execRes

    end

    if callSeq != nil

		  print "  - Called sequence => %s\n\n"%callSeq

		  print "  - Keys => %s\n\n"%(callKeyLst.inject('') {|r, k| r + k.to_s + ' '}).chop if callKeyLst != nil
    else

      print_sequences = true

    end

		File.open(actFile) do |f|
		
			f.each_line do |l|
			
				fullLine = false
				
				next if l =~ /^#/
			
				if l =~ /(.*)\\$/
				
					line << $1

				else
				
					line << l
					
					fullLine = true
				
				end
				
				next if !fullLine
				
				if line =~ /^\[(\w+)\]$/
				
					actLst << act if act
				
					active_keys.clear	

					active_keys[0] = :default

					act = {:name => $1, :opts => {}}
				
				elsif line =~ /^(\w+):$/

					active_keys.clear
				
					active_keys[0] = $1

				elsif line =~ /^(\w+)\s&\s(\w+):/

					active_keys.clear

					active_keys[0] = $1

					active_keys[1] = $2
					
				elsif line =~ /([\w.\/]+)=(.*)/

					if act

						active_keys.each do |key|
					
							act[:opts][key] = [] if !act[:opts][key]
						
							act[:opts][key] << [$1, $2]

						end
					
					end
					
				elsif line =~ /(\w+) >> \[([A-Za-z0-9, ]+)\]/
				
					seq = $2.split(',')
					
					seqLst << [$1, seq]

				elsif line =~ /(\w+) == \[([A-Za-z0-9, ]+)\]/

					aliasData = $2.split(' ')

					aliasLst << [$1, aliasData]
				
				end
				
				line = ''
			
			end
			
			actLst << act if act
		
		end

    # seqLst - list of defined execution sequences
    #
    # seqLst => [
    #             [sequence_name, [module1, module2, ...]],
    #             ...
    #           ]

    # aliasLst - list of defined aliases for execution
    # sequences with keys
    #
    # aliasLst => [
    #              [alias_name, [sequence_name, key1, key2, ...]],
    #              ...
    #             ]
    #
    
    # Check for Alias action section.
    
    aliasAct = actLst.find do |a|

      a[:name] == "Alias"

    end

		aliasDfltKey = aliasAct[:opts][:default] if aliasAct

    if aliasDfltKey

      aliasDfltKey.each do |a|

        if a[0] && a[1]

          SetModEnvVar(a[0], a[1])

        end

      end

    end

		# Check for DoConfig action section.
		
		cfgAct = actLst.find do |a|
		
			a[:name] == 'DoConfig'
		
		end
	
		cfgDfltKey = cfgAct[:opts][:default] if cfgAct
		
		# Skip execution if config section says it's root config file
		# and this is not first directory level.
		
		if cfgDfltKey
		
			cfgDfltKey.each do |a|
			
				if a[0] == 'ROOTFILE' && lvl != 0
				
					skip = true
				
				end
			
			end
		
		end
		
		begin
		
      if print_sequences

        PrintSequences(seqLst, aliasLst)

        execRes = true

        break

      end

			if skip
			
				execRes = true
				
				break
			
			end
		
			error = false

			# First check alias list.

			seq = aliasLst.find {|a| callSeq == a[0]}

			if seq

				print "  - Alias substitution for sequence: %s => %s\n\n"%[
								       	      callSeq,
				       				       	      (
									       seq[1].inject('') do |r, s| 
									       	r + s + ' '
									       end
									       ).chop
								       	      ]

				callSeq = seq[1][0]

				callKeyLst = callKeyLst + seq[1][1..-1]

			end	

			seq = seqLst.find {|s| callSeq == s[0]}
		
			if !seq
				
				Output "Sequence %s not found in config file."%callSeq
				
				break
				
			end

			print "  - Executing sequence \"%s\" with keys \"%s\"\n\n"%[
									       	    callSeq,
									       	    (
										    callKeyLst.inject('') do |r, k|
											r + k.to_s + ' '
										    end
										     ).chop
									       	    ]

			# Run all actions of called sequence.
			
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

					# Get action parameters for each called key.
				
					callKeyLst.each do |callKey|
					
						# If options in default key section and in called key section
						# have same names we need to add default key option data to
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

					
					# Get action parameters for each called key 
					# and store them into hash.
					# Hash layout:
					#
					# {
					# 	"param_name" => "param_value",
					# 	...
					# }
					
					paramsForMod = {}

					callKeyLst.each do |callKey|
					
						if actData[:opts][callKey]
					
							actData[:opts][callKey].each do |o|

								# If parameter with given name
								# already exist, we concatenate
								# new value to already existing.
								
								# Substitute possible global variables
								# in value string.

								val = SubstEnvVarsInStr(o[1])

								if !paramsForMod[o[0]]

									paramsForMod[o[0]] = val

								else

									paramsForMod[o[0]] << ' ' << val
									
								end
							
							end
						
						end
					
					end
					
				end

        puts "\n[" + actName + "]\n\n"
				
				r = CallActModuleCb(act, 'Do', paramsForMod)
				
				if !r
				
					Output "Module %s reported error, exiting."%actName
					
					# Set global error flag.
					
					@buildErr = true
					
					error = true
					
					break
				
				end
			
			end
			
			break if error
			
			execRes = true
		
		end while false
		
		execRes
		
	end
	
	def ActionsForDir(name, seq, keyLst, lvl, rootDir, recourse)
	
		r = true
		
		cfgFiles = []

    if recourse
		
  		Dir[name].each do |d|
		
	  		if d != '.' && d != '..'
			
		  		# Check subdirectories for config files first.
			
			  	if File.directory?(d)
				
				  	Dir.chdir(d) do |path|
					
					  	r = ActionsForDir(d + '/*', seq, keyLst, lvl + 1, rootDir + '/..', recourse)
						
						  break if !r
					
					  end
				
				  elsif d =~ /#{CONF_FILE_NAME}$/
				
					  cfgFiles << d
					
				  end
				
			  end
		
		  end

    else

      cfgFiles << CONF_FILE_NAME

    end
		
		# Exec current directory config after all subdirectories was handled.
		
		if !@buildErr
		
			cfgFiles.each do |cfgFile|
			
				Output "\r\n* [%s]\r\n\r\n"%cfgFile
				
				SetModEnvVar(:rootdofiledir, rootDir)
			
				r = ExecActionsForDir(cfgFile, seq, keyLst, lvl)
				
				break if !r
			
			end
		
		end
		
		r
	
	end
	
	def Do(seq, keyLst, recourse)
	
		EnumActionModules([ENV['DO_HOME'] + '/actions', "./actions"])
		
		ActionsForDir(Dir.pwd + '/*', seq, keyLst, 0, '.', recourse)
		
	end

end

keyLst = [:default]

seq = nil

recourse = false

print_info = false

i = 0

ARGV.each do |arg|

  if arg == '-R'

    recurse = true

    next

  elsif arg == '-i'

    print_info = true

  end

	if i == 0
	
		seq = arg
	
	else
	
		keyLst << arg
	
	end

  i = i + 1

end

if print_info

  seq = nil

else

  seq = 'default' if (!seq)

end

exit(Do.new.Do(seq, keyLst, recourse))
