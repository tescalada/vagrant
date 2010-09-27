require 'mario'

module Vagrant
  # Vagrant UIs handle communication with the outside world (typically
  # through a shell). They must respond to the typically logger methods
  # of `warn`, `error`, `info`, and `confirm`.
  class UI
    attr_accessor :env

    def initialize(env)
      @env = env
    end

    [:warn, :error, :info, :confirm, :say_with_vm, :report_progress, :ask, :no?, :yes?].each do |method|
      # By default these methods don't do anything. A silent UI.
      define_method(method) { |*args| }
    end

    # A shell UI, which uses a `Thor::Shell` object to talk with
    # a terminal.
    class Shell < UI
      def initialize(env, shell)
        super(env)

        @shell = shell
      end

      [[:warn, :yellow], [:error, :red], [:info, nil], [:confirm, :green]].each do |method, color|
        class_eval <<-CODE
          def #{method}(message, opts=nil)
            @shell.say("\#{line_reset}\#{format_message(message, opts)}", #{color.inspect})
          end
        CODE
      end

      [:ask, :no?, :yes?].each do |method|
        class_eval <<-CODE
          def #{method}(message, opts=nil)
            opts ||= {}
            @shell.send(method, format_message(message, opts), opts[:color])
          end
        CODE
      end

      def report_progress(progress, total, show_parts=true)
        percent = (progress.to_f / total.to_f) * 100
        line = "Progress: #{percent.to_i}%"
        line << " (#{progress} / #{total})" if show_parts
        line = "#{line_reset}#{line}"

        @shell.say(line, nil, false)
      end

      protected

      def format_message(message, opts=nil)
        opts = { :prefix => true }.merge(opts || {})
        message = "[#{env.resource}] #{message}" if opts[:prefix]
        message
      end

      def line_reset
        reset = "\r"
        reset += "\e[0K" unless Mario::Platform.windows?
        reset
      end
    end
  end
end
