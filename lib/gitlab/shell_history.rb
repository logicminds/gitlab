class Gitlab::Shell
  class History
    DEFAULT_HISTFILESIZE = 200
    DEFAULT_FILE_PATH = File.join(Dir.home, '.gitlab_shell_history')

    def initialize(options = {})
      @file_path = options[:file_path] || DEFAULT_FILE_PATH
      Readline::HISTORY.clear
    end

    def load
      read_from_file { |line| Readline::HISTORY << line.chomp }
    end

    def save
      lines.each { |line| history_file.puts line if history_file }
    end

    def push(line)
      Readline::HISTORY << line
    end
    alias_method :<<, :push

    def lines
      Readline::HISTORY.to_a.last(max_lines)
    end

    private

    def history_file
      if defined?(@history_file)
        @history_file
      else
        @history_file = File.open(history_file_path, 'w', 0600).tap do |file|
          file.sync = true
        end
      end
    rescue Errno::EACCES
      warn 'History not saved; unable to open your history file for writing.'
      @history_file = false
    end

    def history_file_path
      File.expand_path(@file_path)
    end

    def read_from_file
      path = history_file_path

      if File.exist?(path)
        File.foreach(path) { |line| yield(line) }
      end
    rescue => error
      warn "History file not loaded: #{error.message}"
    end

    def max_lines
      (ENV['GITLAB_HISTFILESIZE']|| DEFAULT_HISTFILESIZE).to_i
    end
  end
end
