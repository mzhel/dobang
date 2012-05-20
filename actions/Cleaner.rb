class Cleaner

	def initialize

		@opts = {}

	end

	def Opt(key, value)

		@opts[key] = value

	end

	def Do

		@opts['DIRS'].split(';').each do |dir|

			@opts['EXTS'].split(';').each do |mask|

				Dir[dir + mask].each do |f|

					out "Deleting %s."%f

					File.delete(f)

				end

			end

		end

		true

	end

end
