require 'ripl'
require 'fileutils'
require 'socket'

module Ripl
  module Fresh
    VERSION = '0.1.1'

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
        # single words, and main regex to match shell commands
        when /^(\w+)$/i, Ripl.config[:fresh_match_regexp]
          if Ripl.config[:fresh_ruby_words].include?($1)
            :ruby
          elsif Ripl.config[:fresh_mixed_words].include?($1)
            :mixed
          elsif Ripl.config[:fresh_system_words].include?($1)
            :system
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

# load :mixed commands
require File.dirname(__FILE__) + '/fresh/commands'

## fresh config ###

# prefixes
Ripl.config[:fresh_system_prefix]  = %w[^]
Ripl.config[:fresh_ruby_prefix]    = [' ']
# single words
Ripl.config[:fresh_ruby_words]     = %w[begin case class def for if module undef unless until while puts warn print p pp ap raise fail loop require load lambda proc system]
Ripl.config[:fresh_system_words]   =
  ENV['PATH'].split(File::PATH_SEPARATOR).uniq.map {|e|
    File.directory?(e) ? Dir.entries(e) : []
  }.flatten.uniq - ['.', '..'] 
# catch mix words
Ripl.config[:fresh_mixed_words]    = %w[cd] 
# main regexp
Ripl.config[:fresh_match_regexp]    = /^([a-z_-]+)\s+(?!(?:[=%*]|!=|\+=|-=|\/=))/i
# regex matched but word not in one of the three arrays, possible values: :ruby, :system, :mixed
Ripl.config[:fresh_match_default]   = :ruby 
# regex did not match
Ripl.config[:fresh_default]         = :ruby 
# configure directory prompt
Ripl.config[:prompt] = proc{
  # If the $PS1 environment variable is set, attempt to respect it
  if ENV['PS1']
    prompt = ENV['PS1'].dup
    prompt.gsub!('\a', '')                              # unsupported
    prompt.gsub!('\d', Time.now.strftime("%a %b %d"))
    prompt.gsub!(/\\D\{([^}]+)\}/){Time.now.strftime($1)}
    prompt.gsub!('\e', "\033")
    prompt.gsub!('\h', Socket.gethostname.split('.')[0])
    prompt.gsub!('\H', Socket.gethostname.chomp)
    prompt.gsub!('\j', '')                              # unsupported
    prompt.gsub!('\l', '')                              # unsupported
    prompt.gsub!('\n', "\n")
    prompt.gsub!('\r', "\r")
    prompt.gsub!('\s', 'fresh')
    prompt.gsub!('\t', Time.now.strftime("%H:%M:%S"))
    prompt.gsub!('\T', Time.now.strftime("%I:%M:%S"))
    prompt.gsub!('\@', Time.now.strftime("%I:%M %p"))
    prompt.gsub!('\A', Time.now.strftime("%H:%M"))
    prompt.gsub!('\u', Etc.getlogin)
    prompt.gsub!('\v', `#{`echo $SHELL`.chomp} --version`.gsub(/(.*(\d+\.\d+)\..*)/m){$2})
    prompt.gsub!('\V', `#{`echo $SHELL`.chomp} --version`.gsub(/(.*(\d+\.\d+\.\d+).*)/m){$2})
    prompt.gsub!('\w', FileUtils.pwd.gsub(/#{ File.expand_path('~') }/, '~'))
    prompt.gsub!('\W', File.basename(FileUtils.pwd.gsub(/#{ File.expand_path('~') }/, '~')))
    prompt.gsub!('\!', '')                              # unsupported
    prompt.gsub!('\#', '')                              # unsupported
    prompt.gsub!('\$'){uid = nil; Etc.passwd{|u| uid = u.uid if u.name == Etc.getlogin}; uid == 0 ? '#' : '$'}
    prompt
  # Otherwise if $PS1 is not set in the calling shell, use a default prompt syntax
  else
    path = FileUtils.pwd
    path.gsub! /#{ File.expand_path('~') }/, '~'
    path + '> '
  end
}

# J-_-L
