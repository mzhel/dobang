class SevenZ

  def initialize

  end

  def SevenZString(opts)

    r = "7z a " 

    r << "-p#{opts['PASSWORD']} " if opts['PASSWORD']

    r << opts['ARCHIVE_PATH'] if opts['ARCHIVE_PATH']

    if opts['FILES']

      opts['FILES'].split(" ").each do |file|

        r << " #{file}"

      end

    end
  
    r

  end

  def Do(opts)

    str = SevenZString(opts)

    puts str

    out %x[#{str}]
		
		($?.exitstatus > 0)?(false):(true)

  end

end
