# save current prompt
ripl_prompt = Ripl.config[:prompt] # FIXME currently not working

# setup default prompt
default_prompt = proc{ |path|
  path.gsub! /#{ File.expand_path('~') }/, '~'
  path + '> '
}

# PS environment variable prompt
ps_prompt = proc{ |prompt_number|
  require 'socket'
  require 'etc'

  prompt = ENV['PS' + prompt_number.to_s].dup
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
}

# feel free to add your own creative one ;)
prompt_collection = {
  :default => default_prompt,
  :ripl    => ripl_prompt,
  :irb     => proc{ IRB.conf[:PROMPT][IRB.conf[:PROMPT_MODE]][:PROMPT_I] },
  :simple  => '>> ',
}

# register proc ;)
Ripl.config[:prompt] = proc{
  fp = Ripl.config[:fresh_prompt]

  # transform symbol to valid prompt
  if fp.is_a? Symbol
    fp_known = prompt_collection[fp]
    if !fp_known
      fp_known = 
        case fp.to_s # maybe it's a special symbol
        when /^PS(\d+)/
          ps_prompt[ $1 ]
        else # really unknown
          Ripl.config[:fresh_prompt] = :default
          default_prompt
        end
    end
    fp = fp_known
  end

  # call if proc or return directly
  if fp.respond_to? :call
    fp.arity == 1 ? fp[ FileUtils.pwd ] : fp.call
  else
    case fp
    when nil, false
      ''
    when String
      fp
    else
      Ripl.config[:fresh_prompt] = :default
      default_proc.call[ FileUtils.pwd ]
    end
  end
}

# J-_-L
