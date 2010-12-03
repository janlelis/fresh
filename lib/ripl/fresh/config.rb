# configure prompt
Ripl.config[:fresh_prompt] = :default

# word arrays
Ripl.config[:fresh_ruby_commands]     = %w[begin case class def for if module undef unless until while puts warn print p pp ap raise fail loop require load lambda proc]
Ripl.config[:fresh_system_commands]   =
  ENV['PATH'].split(File::PATH_SEPARATOR).uniq.map {|e|
    File.directory?(e) ? Dir.entries(e) : []
  }.flatten.uniq - ['.', '..'] 
Ripl.config[:fresh_mixed_commands]    = %w[cd] 

# a regex matched but command is not in one of the three arrays
#  or regex did not match
#  possible values: :ruby, :system, :mixed
Ripl.config[:fresh_unknown_command_mode] = :ruby
Ripl.config[:fresh_default_mode]         = :ruby

# main regexes
# $<command>: whole command_line
# $<command_line>: only the system command (if possible)
# $<result_operator>: (optional) result operator
# $<result_storage>: (optional) variable to store command result
# $<force>: force system command prefix
# please note: although the main regexp looks pretty complicated, it's just an detailed version of
#  /\w+\s+(=> \w)?/
force           = '(?<force>[\^])'
command         = '(?<command>[a-zA-Z\/_-]+)'
result_operator = '(?<result_operator>[=|~]>{1,2})'
result_storage  = '(?<result_storage>[a-zA-Z@\$_][a-zA-Z0-9@_\[\]:"\']*)'
_store          = "(?:#{ result_operator }\s*#{ result_storage })?"  # matches for example: "=> here"
_anything_but_these = '(?!(?:[=%*]|!=|\+=|-=|\/=)).*?'

Ripl.config[:fresh_patterns] = [
  /^#{ force }(?<command_line>.*?)#{ _store }$/,                             # [0] force system
  nil, nil, nil, nil,
  /^(?<command_line>#{ command })\s*#{ _store }$/,                           # [5] single word
  nil, nil, nil, nil,
  /^(?<command_line>#{ command }\s+#{ _anything_but_these })#{ _store }$/,   # [10] command + space
]

# J-_-L
