require 'ripl'
require 'fileutils'

module Ripl
  module Fresh
    VERSION = '0.1.0'

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
      # setup Fresh
      def before_loop
        @command_mode = :ruby
        super
        # register bond completion
        Ripl.config[:completion][:gems] ||= []
        Ripl.config[:completion][:gems] << 'ripl-fresh'
        # load :mixed commands
        require File.dirname(__FILE__) + '/fresh/commands'
      end

      # determine @command_mode
      def get_input
        input = super

        return input  if @buffer # ripl-multi_line

        @command_mode = case input
        # force system with a single ^
        when Ripl::Fresh.option_array_to_regexp( Ripl.config[:fresh_system_prefix] )
          input = input[$1.size..-1] # TODO refactor, too hacky?
          :system
        # force ruby with a space
        when Ripl::Fresh.option_array_to_regexp( Ripl.config[:fresh_ruby_prefix] )
          input = input[$1.size..-1]
          :ruby
        # single words
        when /^\w+$/i
          if Ripl.config[:fresh_ruby_words].include?($&)
            :ruby
          elsif Ripl.config[:fresh_mixed_words].include?($&)
            :mixed
          elsif Ripl.config[:fresh_system_words].include?($&)
            :system
          else
            :ruby
          end
        # set of commands that call the ruby method but have command line style calling (args without "")
        when Ripl::Fresh.option_array_to_regexp( Ripl.config[:fresh_mixed_words] )
          :mixed
        # here is the important magical regex for shell commands
        when Ripl.config[:fresh_system_regexp]
          if Ripl.config[:fresh_ruby_words].include? $1
            :ruby
          else
            :system
          end
        # default is still ruby ;)
        else
          :ruby
        end

        input
      end

      # get result (depending on @command_mode)
      def loop_eval(input)
        if input == ''
          @command_mode = :system and return
        end

        case @command_mode
        when :system # execute command
          ret = system input
          case ret
          when false
            warn '[non-nil exit status]' # too verbose?
          when nil
            warn "[command error #{$?.exitstatus}]" # add message?
          end
          ret

        when :mixed # call the ruby method, but with shell style arguments
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

## fresh config ###

# prefixes
Ripl.config[:fresh_system_prefix]  = %w[^]
Ripl.config[:fresh_ruby_prefix]    = [' ']
# single words
Ripl.config[:fresh_system_words]  = %w[top ls] 
Ripl.config[:fresh_ruby_words]    = %w[begin case class def for if module undef unless until while puts warn print p pp ap raise fail loop require load lambda proc system]
# catch mix words
Ripl.config[:fresh_mixed_words]   = %w[cd] 
# main regexp
Ripl.config[:fresh_system_regexp]  = /^([a-z_-]+)\s+(?!(?:[=%*]|!=|\+=|-=|\/=))/i
# configure directory prompt
Ripl.config[:prompt] = proc{
  path = FileUtils.pwd
  path.gsub! /#{ File.expand_path('~') }/, '~'
  path + '> '
}

# J-_-L
