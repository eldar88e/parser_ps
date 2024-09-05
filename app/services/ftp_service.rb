class FtpService
  def initialize(**args)
    @file    = StringIO.new(args[:file]) if args[:file]
    @folder  = args[:folder]
    @user    = args[:user]
    @sony_id = args[:sony_id]
    @size    = args[:size]
  end

  def self.call(**args)
    new(**args).send_file
  end

  def self.clear_cache
    Net::FTP.open(FTP_HOST, FTP_LOGIN, FTP_PASS) do |ftp|
      ftp.chdir('/bitrix/cache/s1/bitrix/catalog.section')
      delete_files(ftp)
    rescue => e
      Rails.logger.error e.message
    end

    nil
  end

  def send_file
    return if @file.nil? || @folder.nil? || @sony_id.nil? || @size.nil?

    Net::FTP.open(FTP_HOST, FTP_LOGIN, FTP_PASS) { |ftp| upload_temp_file(ftp) }
  rescue => e
    Rails.logger.error e.message
    'error'
  end

  def upload_temp_file(ftp)
    file_name     = Digest::MD5.hexdigest("#{@sony_id}_#{@size}.jpg")
    temp_img_path = "/tmp/#{file_name}.jpg"

    File.open(temp_img_path, 'wb') do |file|
      file.write(@file.string)
    end

    begin
      ftp.chdir("/upload/iblock/#{@folder}")
    rescue Net::FTPPermError
      ftp.mkdir("/upload/iblock/#{@folder}")
      Rails.logger.info "Folder #{@folder} created!"
      ftp.chdir("/upload/iblock/#{@folder}")
    end
    ftp.putbinaryfile(temp_img_path)
  ensure
    File.delete(temp_img_path) if File.exist?(temp_img_path)
  end

  private

  def self.delete_files(ftp)
    list = ftp.nlst
    list.each do |i|
      try = 0
      begin
        try += 1
        ftp.delete(i)
      rescue Net::FTPPermError => e
        begin
          ftp.chdir(i)
          delete_files(ftp)
          ftp.chdir("..")
          ftp.rmdir(i)
        rescue Net::FTPPermError => e
          Rails.logger.error e.message
          sleep 5 * try
          retry if try > 3
        end
      end
    end
  end
end
