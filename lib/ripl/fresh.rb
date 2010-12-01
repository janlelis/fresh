require 'ripl'
require 'fileutils'

module Ripl
  module Fresh
    VERSION = '0.1.2'

    class << self
      # helper to parse options
      def option_array_to_regexp(option)
        case option
        when Regexp # note: some options still _have_ to be arrays
          option
        when Array, Set
          /^(#{
            option.map{ |char|
              Regexp.escape char.to_s
            }*'|'
          })/
        else
          option.to_s
        end
      end
    end

    module Shell
      def before_loop
        @command_mode = :ruby
        super
        # register bond completion
        Ripl.config[:completion][:gems] ||= []
        Ripl.config[:completion][:gems] << 'ripl-fresh'
      end

      # determine @command_mode
      def get_input
        command_line = super

        return command_line  if @buffer # ripl-multi_line TODO allow system commands

        # This case statement decides the command mode,
        #  and which part of the input should be used for what...
        #  Note: Regexp match groups are used!
        @result_storage = @result_operator = nil

        @command_mode = case command_line
        # force ruby with a space
        when /^ /
          :ruby
        # regexp match shell commands
        when *Array( Ripl.config[:fresh_patterns] )
          command_line     = $~[:command_line]     if $~.names.include? 'command_line'
          command          = $~[:command]          if $~.names.include? 'command'
          @result_operator = $~[:result_operator]  if $~.names.include? 'result_operator'
          @result_storage  = $~[:result_storage]   if $~.names.include? 'result_storage'
          forced           = !! $~[:force]         if $~.names.include? 'force'

          if forced
            :system
          elsif Ripl.config[:fresh_ruby_commands].include?( command )
            :ruby
          elsif Ripl.config[:fresh_mixed_commands].include?( command )
            :mixed
          elsif Ripl.config[:fresh_system_commands].include?( command )
            :system
          elsif Kernel.respond_to? command.to_sym
            :ruby
          else
            Ripl.config[:fresh_unknown_command_mode]
          end
        # default is still ruby ;)
        else
          Ripl.config[:fresh_default_mode]
        end

        command_line
      end

      # get result (depending on @command_mode)
      def loop_eval(input)
        if input == ''
          @command_mode = :system and return
        end
        status = nil

        case @command_mode
        when :system # execute command
          
          if @result_storage
            temp_file = "/tmp/ripl-fresh_#{ rand 12345678901234567890 }"
            status    = system input, :out => temp_file
            # TODO stderr: either
            # * merge with stdout
            # * just display on real stderr
            # * abort command execution
            
            # assign result to result storage variable
            case @result_operator
            when '=>', '=>>'
              result_literal   = "[]"
              formatted_result = "File.read('#{ temp_file }').split($/)"
              operator = @result_operator == '=>>' ? '+=' : '='
            when '~>', '~>>'
              result_literal = "''"
              formatted_result = "File.read('#{ temp_file }')"
              operator = @result_operator == '~>>' ? '<<' : '='
            end

            Ripl.shell.binding.eval "
              #{ @result_storage } ||= #{ result_literal }
              #{ @result_storage } #{ operator } #{ formatted_result }"
            
            FileUtils.rm temp_file
          else
            status = system input
          end

          case status
          when false
            warn '[non-nil exit status]' # too verbose?
          when nil
            warn "[command error #{$?.exitstatus}]" # add message?
          end

          status

        when :mixed # call the ruby method, but with shell style arguments TODO more shell like (e.g. "")
          m, *args = *input.split
          super "#{m}(*#{args.to_s})"

        else # good old :ruby
          super
        end
      end

      # system commands don't have output values and Ruby is displayed normally
      def print_result(result)
        if @error_raised ||
             @command_mode == :system ||
             @command_mode == :mixed && (!result || result == '')
          # don't display anything
        else
          super # puts(format_result(result))
        end
      end

      # catch ctrl+c
      def loop_once(*args)
        super
      rescue Interrupt
        @buffer = @error_raised = nil
        puts '[C]'
        retry
      end
    end
  end
end

# hook in (and work around readline loading behaviour)
Ripl.config[:readline] = false
require 'ripl/readline'
Ripl::Shell.send :include, Ripl::Fresh::Shell

# load :mixed commands
require File.dirname(__FILE__) + '/fresh/commands'

# fresh config
require File.dirname(__FILE__) + '/fresh/config'

# fresh_prompt management
require File.dirname(__FILE__) + '/fresh/prompt'

# J-_-L
#
# TODO: test on jruby + rbx
#       readme
#       multi_line
#       bond
#       stderr
