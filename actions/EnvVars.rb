class EnvVars

	def initialize
		
	end

	def Do(opts)

		opts.each_pair do |name, value|

			SetVar(name, value)

		end

	end	

end
