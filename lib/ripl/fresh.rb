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
        input = super

        return input  if @buffer # ripl-multi_line TODO allow system commands

        # This case statement decides the command mode,
        #  and which part of the input should be used for what... # TODO refactor
        @result_storage = @result_operator = nil
        @command_mode = case input
        # force system with a single ^
        when Ripl::Fresh.option_array_to_regexp( Ripl.config[:fresh_system_prefix] )
          input = input[$1.size..-1] # TODO refactor, too hacky?
          :system
        # force ruby with a space
        when Ripl::Fresh.option_array_to_regexp( Ripl.config[:fresh_ruby_prefix] )
          input = input[$1.size..-1]
          :ruby
        # single words, and main regex to match shell commands
        when *Array( Ripl.config[:fresh_match_regexp] )
          input            = $1
          @result_operator = $3
          @result_storage  = $4
          if Ripl.config[:fresh_ruby_words].include?($2)
            :ruby
          elsif Ripl.config[:fresh_mixed_words].include?($2)
            :mixed
          elsif Ripl.config[:fresh_system_words].include?($2)
            :system
          elsif Kernel.respond_to? $2.to_sym
            :ruby
          else
            Ripl.config[:fresh_match_default]
          end
        # default is still ruby ;)
        else
          Ripl.config[:fresh_default]
        end

        input
      end

      # get result (depending on @command_mode)
      def loop_eval(input)
        if input == ''
          @command_mode = :system and return
        end
        ret = nil

        case @command_mode
        when :system # execute command
          
          if @result_storage
            temp_file = "/tmp/ripl-fresh_#{ rand 12345678901234567890 }"
            ret       = system input, :out => temp_file
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
            ret = system input
          end

          case ret
          when false
            warn '[non-nil exit status]' # too verbose?
          when nil
            warn "[command error #{$?.exitstatus}]" # add message?
          end

          ret

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
#       forced commands
#       readme
#       multi_line
#       bond
