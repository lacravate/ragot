# ragot

A gem to tell on methods and what they do, behind their backs. A universal hack to create hooks around methods.

# Warning

This is pre-pre-pre-alpha software. Use it because it works and it is useful, don't complain because i wrote this.

# Example

Ragot.about(MyObject, :its_method) { puts "#{inspect} output" } # block executed in instance context

