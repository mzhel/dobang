class Cleaner

	def initialize

	end

	def Do(opts)

		opts['DIRS'].split(';').each do |dir|

			opts['EXTS'].split(';').each do |mask|

        if shellCmdsToFile

          shellCmd "rm -v " + dir + mask 

        else

				  Dir[dir + mask].each do |f|

					  out "Deleting %s."%f

					  File.delete(f)

				  end

        end

			end

		end

		true

	end

end
