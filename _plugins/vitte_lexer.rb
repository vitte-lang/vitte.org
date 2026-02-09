require 'rouge'

module Rouge
  module Lexers
    class Vitte < RegexLexer
      title 'Vitte'
      aliases 'vit', 'vitte'
      filenames '*.vit'
      mimetypes 'text/x-vitte'

      KEYWORDS = %w(
        proc form trait pick enum when loop if else otherwise break continue set let give emit
        from as import export pub fn const type cast match with while for in do is
        return yield assume pragma builtin extern asm inline volatile unsafe
        space pull use share global make entry macro case select field
        true false null undefined void
      ).freeze

      BUILTINS = %w(
        print println eprint eprintln len cap assert panic todo unreachable
        clone copy drop transmute bool i8 i16 i32 i64 i128 isize
        u8 u16 u32 u64 u128 usize f32 f64 string rune byte
        ptr ref mut option result error ok none some err unwrap expect
      ).freeze

      state :root do
        rule %r/\s+/, Text::Whitespace
        rule %r/<<<(?:(?!>>>).)*>>>/m, Comment::Multiline
        rule %r/<<</, Comment::Multiline, :zone_comment
        rule %r/#.*?$/, Comment::Single
        rule %r/\/\/.*?$/, Comment::Single
        rule %r/\/\*/, Comment::Multiline, :comment
        
        rule %r/\b(?:#{KEYWORDS.join('|')})\b/, Keyword
        rule %r/\b(?:#{BUILTINS.join('|')})\b/, Name::Builtin
        
        rule %r/"(?:\\.|[^"\\])*"/, String::Double
        rule %r/'(?:\\.|[^'\\])*'/, String::Char
        rule %r/`[^`]*`/, String::Backtick
        
        rule %r/\b\d+\.\d+([eE][+-]?\d+)?\b/, Num::Float
        rule %r/\b0[xX][0-9a-fA-F]+\b/, Num::Hex
        rule %r/\b0[bB][01]+\b/, Num::Bin
        rule %r/\b\d+\b/, Num::Integer
        
        rule %r/[{}\[\](),.;:]/, Punctuation
        rule %r/::=|->|=>/, Operator
        rule %r/[|?+*~]/, Operator
        rule %r/[-+\/*%^&!<>=]=?/, Operator
        rule %r/[:=]/, Operator
        
        rule %r/[a-zA-Z_]\w*/, Name
      end

      state :comment do
        rule %r{[^*/]+}, Comment::Multiline
        rule %r{\*/}, Comment::Multiline, :pop!
        rule %r{[*/]}, Comment::Multiline
      end

      state :zone_comment do
        rule %r/[^>]+/, Comment::Multiline
        rule %r/>>>/, Comment::Multiline, :pop!
        rule %r/>/, Comment::Multiline
      end
    end
  end
end
