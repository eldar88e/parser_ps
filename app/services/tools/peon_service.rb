module Tools
  class PeonService
    def initialize(storehouse)
      @store = "#{storehouse}store/"
      @trash = "#{storehouse}trash/"

      FileUtils.mkdir_p @store
      FileUtils.mkdir_p @trash
    end

    # @peon.put(file: "id_347_d_2020_05_13.html", content: "<p>Your HTML here!</p>", subfolder: "run_id_2")
    def put(**args)
      file_name = check_file(args[:file])
      content   = check_content(args[:content])
      subfolder = check_dir_path(args[:subfolder])
      chmod     = !args[:chmod].nil?

      store_path = "#{@store}#{subfolder}"

      FileUtils.mkdir_p store_path
      FileUtils.chmod_R 'g+w', store_path if chmod

      Zlib::GzipWriter.open(gz_file(store_path, file_name, '*')) { |gz| gz.write(content) }
      File.rename(gz_file(store_path, file_name, '*'), gz_file(store_path, file_name))
      gz_file(store_path, file_name)
    end

    def list(**args)
      subfolder = check_dir_path(args[:subfolder])
      dir       = "#{@store}#{subfolder}"

      Dir.children(dir)
    end

    def move_all_to_trash(subfolder=nil)
      subfolder = check_dir_path(subfolder)
      dest_path = "#{@trash}#{subfolder}"

      begin
        FileUtils.makedirs dest_path
        FileUtils.move Dir.glob("#{@store}*"), dest_path
      rescue Errno::EEXIST => e
        Hamster.logger.error e
        dest_path += "copy_#{Time.current.to_i}/"
        retry
      end
    end

    # @peon.give(file: "id_347_d_2020_05_13.html", subfolder: "run_id_2")
    def give(**args)
      file_name = check_file(args[:file])
      subfolder = check_dir_path(args[:subfolder])

      store_path = "#{@store}#{subfolder}"
      if Dir[store_path].empty?
        raise "You don't have such subfolder(s) in your project's Storage. Check that they exist or run `@peon.give()` with correct parameters before this method."
      else
        Zlib::GzipReader.open(gz_file(store_path, file_name), &:read)
      end
    end

    # @peon.give_any([subfolder: "#{`store` subfolder(s)}"])
    def give_any(**args)
      subfolder = check_dir_path(args[:subfolder])

      store_path = "#{@store}#{subfolder}"
      if Dir[store_path].empty?
        raise "You don't have such subfolder(s) in your project's Storage. Check that they exist or run `@peon.put()` with correct parameters before this method."
      else
        list = give_list(subfolder: subfolder)
        if list.empty?
          "No files found in`#{store_path}`. Check that your `@peon.put()` runs correctly."
        else
          file_name = list.first
          content   = Zlib::GzipReader.open(gz_file(store_path, file_name), &:read)
          { file_name: file_name, content: content }
        end
      end
    end

    # @peon.give_list(subfolder: "run_id_2")
    def give_list(**args)
      subfolder = check_dir_path(args[:subfolder])
      store_path = "#{@store}#{subfolder}"
      Dir.glob("#{store_path}/*").select { |p| p[-3..-1] == '.gz' }.map { |p| File.basename(p) }
    end

    def give_list_year(**args)
      subfolder = check_dir_path(args[:subfolder])
      store_path = "#{@store}#{subfolder}"
      year = args[:year]
      Dir.glob("#{store_path}/*").select { |p| (p[-3..-1] == '.gz' &&  p[-17..-14] == year.to_s ) }
         .map { |p| File.basename(p) }
    end

    # @peon.move(file: "id_347_d_2020_05_13.html", s_subfolder: "run_id_2", t_subfolder: "run_id_2_2020_05_13/0_10k")
    def move(**args)
      file_name = check_file(args[:file])
      from      = check_dir_path(args[:from])
      to        = check_dir_path(args[:to])
      chmod     = !args[:chmod].nil?

      store_path = "#{@store}#{from}"
      trash_path = "#{@trash}#{to}"

      FileUtils.mkdir_p trash_path
      FileUtils.chmod_R 'g+w', trash_path if chmod

      FileUtils.mv(gz_file(store_path, file_name), gz_file(trash_path, file_name)) if give(file: file_name, subfolder: from)
      nil
    end

    # @peon.copy(file: "id_347_d_2020_05_13.html", s_subfolder: "run_id_2", t_subfolder: "run_id_2_2020_05_13/0_10k")
    def copy(**args)
      file_name = check_file(args[:file])
      from      = check_dir_path(args[:from])
      to        = check_dir_path(args[:to])
      chmod     = !args[:chmod].nil?

      store_path = "#{@store}#{from}"
      trash_path = "#{@trash}#{to}"

      FileUtils.mkdir_p trash_path
      FileUtils.chmod_R 'g+w', trash_path if chmod

      FileUtils.cp_r(gz_file(store_path, file_name), gz_file(trash_path, file_name)) if give(file: file_name, subfolder: from)
      nil
    end

    # @peon.copy_and_unzip_temp
    def copy_and_unzip_temp(**args)
      file_name = check_file(args[:file])
      file_path = gz_file("#{@trash}#{args[:to]}", file_name)
      temp_path = file_path.gsub('.gz', '').gsub('/store/', '/trash/')

      copy(args)

      Zlib::GzipReader.open(file_path) do |gz|
        File.open(temp_path, "w+") { |f| f.write(gz.read) }
      end

      temp_path
    end

    # @peon.move_and_unzip_temp
    def move_and_unzip_temp(**args)
      file_name = check_file(args[:file])
      file_path = gz_file("#{@trash}#{args[:to]}", file_name)
      temp_path = file_path.gsub('.gz', '').gsub('/store/', '/trash/')

      move(args)

      Zlib::GzipReader.open(file_path) do |gz|
        File.open(temp_path, "w+") { |f| f.write(gz.read) }
      end

      temp_path
    end

    # @peon.throw_temps
    def throw_temps
      Dir.glob("#{@trash}**").each {|p| File.delete(p) if File.file?(p) && p[-3..-1] != '.gz'}
    end

    # @peon.throw_trash(over_n_days: #{number of days (int)})
    def throw_trash(days = -1)
      days = days.to_i == 0 ? -1 : days

      res = ['start']

      until res.empty? || res.size == Dir.glob("#{@trash}**/*").size
        res = Dir.glob("#{@trash}**/*").sort_by { |p| [-p.count('/'), p.length] }
                 .map { |p| [p, File.ctime(p), Dir.empty?(p)] }
                 .each do |a|
          if (Date.today - Date.parse(a[1].to_s)).to_i >= days && (a.first[-3..-1] == '.gz' || a.last)
            FileUtils.remove_dir(a.first)
          end
        end
      end
    end

    private

    def check_file(file)
      file =~ /\A[-‑[:word:]\.\_]+(\.\w{1,4})*\z/ ? file : raise("File name that you are giving is incorrect. Please note that it must contain only letters, digits, hyphens, underscores, and optional extension (1-4 letters).")
    end

    def check_content(content)
      content.is_a?(String) && content.length > 0 ? content : raise("Content that you are giving isn't a string or it is empty string. Please use `to_s` method if you want save not String type objects. Also make sure that length of text is at least 1 symbol. We aren't creating empty files.")
    end

    def check_dir_path(path)
      return path if path.nil?
      path =~ /\A\/?(\w+\/?)+\z/ ? "/#{path}/".squeeze('/')[1..-1] : raise("Incorrect subfolder path. Check it carefully.")
    end

    def gz_file(dir, name, suffix = nil)
      (dir + name + "#{suffix}.gz").gsub('.gz.gz', '.gz')
    end
  end
end
