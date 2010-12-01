# prefixes
Ripl.config[:fresh_system_prefix]  = %w[^]
Ripl.config[:fresh_ruby_prefix]    = [' ']

# word arrays
Ripl.config[:fresh_ruby_words]     = %w[begin case class def for if module undef unless until while puts warn print p pp ap raise fail loop require load lambda proc system]
Ripl.config[:fresh_system_words]   =
  ENV['PATH'].split(File::PATH_SEPARATOR).uniq.map {|e|
    File.directory?(e) ? Dir.entries(e) : []
  }.flatten.uniq - ['.', '..'] 
Ripl.config[:fresh_mixed_words]    = %w[cd] 

# main regexes
# $1: whole command_line
# $2: only the command
# $3: (optional) result operator
# $4: (optional) variable to store command result
# please note: although the regexp looks pretty complicated, it's just an detailed version of
#  /\w+\s+(=> \w)?/
command  = '([a-zA-Z\/_-]+)'
store_in = '(?:([=|~]>{1,2})\s*([a-zA-Z@\$_][a-zA-Z0-9@_\[\]:"\']*))?'  # matches for example: "=> here"
Ripl.config[:fresh_match_regexp]    = [
  /^(#{ command })\s*#{ store_in }$/,                                 # single word
  /^(#{ command }\s+(?!(?:[=%*]|!=|\+=|-=|\/=)).*?)#{ store_in }$/,   # command + space
]

# regex matched but word not in one of the three arrays, possible values: :ruby, :system, :mixed
Ripl.config[:fresh_match_default]   = :ruby

# regex did not match
Ripl.config[:fresh_default]         = :ruby

# configure prompt
Ripl.config[:fresh_prompt] = :default

# J-_-L
