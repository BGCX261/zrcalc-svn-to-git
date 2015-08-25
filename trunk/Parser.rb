#!/usr/bin/ruby

# Parser_0605.rb(适配RCalc.rb)
# Written by 龙第九子, 2009-06-05

# --------------------------------------------------------------------
# class Token （标记）
# ttype   标记类型，目前有 :op :pa :fun :num 等四种
# value  标记的词法值，是原始字符串的一个子串
#        :op分为5种 + - * / ^
#        :pa分为2种 ( )
#        :fun分为5种 sin cos tan log ln
# index  标记的位置，是标记在原始字符串中的下标
Token = Struct.new("Token", :ttype, :value, :index)

# --------------------------------------------------------------------
# class Lexer （词法分析器）
# pull      # 尝试从当前@cursor位置取出一个token
# lex       # 一次解析完毕（循环调用pull直至串末尾）
# error?    # 词法分析过程中是否检测到错误（非法字符）
# eof?      # 是否匹配器指针@cursor已到达串末尾
# pos       # 返回tokens[index]在原始字串中的地址
#
# Lexer是个比较安静的词法分析器，在检测到错误时不会抛异常，
# 也不会返回错误码，甚至不会停止，在记录错误后继续向后解析
# 所有标记存放在@tokens里，所有错误存放在@errors里

class Lexer
  attr_reader :raw_str, :text, :tokens, :errors
  def initialize(raw_str, autorun=nil)
    # 保留原始字符串的副本
    @raw_str = raw_str

    # 清除空白字符，另存为@text
    @text = raw_str
    @text = @text.sub(/[ \t]+/, '') while @text =~ /[ \t]+/

    # 建立下标映射表（@text中的各字符在@raw_str中的位置）
    @index_map = []
    idx, len = 0, @raw_str.size
    while idx < len
      @index_map.push(idx) if @raw_str[idx..idx] !~ /[ \t]/
      idx += 1
    end

    # 初始化其他数据成员
    @cursor = 0    # 指针，表示正解析@text的哪个位置
    @tokens = []   # 所有正确识别出的标记放在这里

    # 记录错误（无法识别的子串）
    @errors = []   # 所有错误以[position, substr]的单元形式堆放
    @err_beg = @err_end = -1  # 错误状态

    # 是否自动开始解析
    lex if autorun == true
  end

  # 取出一个token（能够记忆当前指针位置和错误状态）
  def pull
    tail = @text[@cursor..-1]
    token = Token.new
    error = false

    case tail
      when /^[+\-*\/\^]/
        token.ttype = :op
      when /^[()]/
        token.ttype = :pa
      when /^(sin|cos|tan|log|ln)/
        token.ttype = :fun
      when /^\d+(\.\d+)?([Ee][+\-]?\d+)?/
        token.ttype = :num
      else
        error = true
        @err_beg = @cursor if @err_beg == -1
        @err_end = @cursor
    end

    if error
      @cursor += 1
      if eof?
        err_substr = @text[@err_beg..@err_end]
        errors.push([@err_beg, err_substr])
      end
      return nil
    else
      token.value = $&
      token.index = @index_map[@cursor]
      @tokens.push(token)
      @cursor += $&.length

      if @err_beg != -1
        err_substr = @text[@err_beg..@err_end]
        @errors.push([@err_beg, err_substr])
        @err_beg = @err_end = -1
      end
      return token
    end
  end

  # 一次性解析出所有标记
  def lex
    pull until eof?
  end

  # 是否出现过错误？
  def error?
    @errors != []
  end

  # 是否已解析完毕（到达字串末尾）？
  def eof?
    @cursor == @text.length
  end

  # 返回tokens[index]在原始字串中的地址
  def pos(index)
    return 'EOF' if index == @tokens.length
    @tokens[index].index
  end
end # of class Lexer

# 测试Lexer类
#lexer = Lexer.new('1+(2.53e-8-3*4)/5-sin6^311', true)
#p lexer.tokens
#p lexer.errors

# --------------------------------------------------------------------
class Tree
  attr_accessor :ttype, :root, :lchild, :rchild
  def initialize(ttype=nil, root=nil, lchild=nil, rchild=nil)
      @ttype   = ttype
      @root   = root
      @lchild = lchild
      @rchild = rchild
  end

  # 返回此树的一个精确副本
  def Tree.copy(tree)
    tree if tree.class != Tree
    new_lchild = tree.lchild == nil ? nil : Tree.copy(tree.lchild)
    new_rchild = tree.rchild == nil ? nil : Tree.copy(tree.rchild)
    Tree.new(tree.ttype, tree.root, new_lchild, new_rchild)
  end

  def to_s
      return @root.to_s if @ttype == 'Number'
      "#{ttype}(" + "#{@root} #{@lchild} #{@rchild}".strip + ")"
#      "(" + "#{@root} #{@lchild} #{@rchild}".strip + ")"
  end
end

# --------------------------------------------------------------------
class ParseError < RuntimeError
  def initialize(token, position)
    @token = token
    @position = position
  end

  def to_s
    "Syntax error! #{@token} expected at position #{@position}"
  end
end

# --------------------------------------------------------------------
#以递归形式定义的LL(1)语法：
#
#expr: term
#    | term + expr
#    | term - expr         ;;  从左向右算出每个term，再做加减即可
#    ;                     ;;  
#
#term: fact
#    | fact * term         ;;  -sin-5^-sin-5 * -sin-6^-sin-6
#    | fact / term         ;;  从左向右算出每个fact，再做乘除即可
#    ;
#
#fact: func
#    | func ^ fact         ;;  -sin-5^-sin-5^-sin-5
#    ;                     ;;  先算指数，再算全部，最后看是否乘-1
#
#func: atom                ;;  -5
#    | FUNCTOR func        ;;  sin-5, sinsin-5
#    | SIGN func           ;;  -sinsin-5
#    ;                     ;;  从右向左计算，最后看是否乘-1
#
#atom: NUMBER
#    | ( expr )
#    ;
#
#FUNCTOR: sin | cos | tan | log | ln ;
#SIGN: + | - ;
#NUMBER: \d+(\.\d+)?([Ee][+\-]?\d+)?


class Parser
  def initialize(text)
    @lexer = Lexer.new(text, true)  # lexical analysis, no exceptions
    @tokens = @lexer.tokens  # get a reference of the token array
    # puts @tokens
    @index = 0
  end

  def parse
    # lexical analysis
    if @lexer.error?
      err_pos = @lexer.errors[0][0]
      err_str = @lexer.errors[0][1]
      raise "Lexical error! Position #{err_pos}: #{err_str}"
    end

    raise "Don't play with me!" if @tokens == []

    # syntactical analysis
    begin
      tree = expression
      puts tree
      return tree
    rescue => e
      raise RuntimeError.new("Syntax error! "+e.message)
    end
  end

  def expression
    # 先按原定规程构造expr
    tree = rotate(expr)

    # 然后归约其中的Atom结点
    eliminate_atom(tree)
  end

  #expr: term
  #    | term + expr
  #    | term - expr         ;;  从左向右算出每个term，再做加减即可
  #    ;                     ;;  
  def expr
    begin
      first = rotate(term)
      return first if ended?
      # puts "first: #{first}"
      op = @tokens[@index]
      # puts "op: #{op}"
      if op.value == '+' || op.value == '-'
        @index += 1
        successors = expr
        Tree.new('Expr', op.value, first, successors)
      else
        raise
      end
    rescue
      raise "Position: " + @lexer.pos(@index).to_s
    end
  end

  #非终结符term表示一系列因子的乘积，例如 -5/2*cos3^2/8 就是一个term
  #term: fact
  #    | fact * term         ;;  -sin-5^-sin-5 * -sin-6^-sin-6
  #    | fact / term         ;;  从左向右算出每个fact，再做乘除即可
  #    ;
  def term
    begin
      first = justify_fact(fact)
      return first if ended?
      op = @tokens[@index]
      return first if op.value != '*' && op.value != '/'
      @index += 1
      successors = term
      Tree.new('Term', op.value, first, successors)
    rescue
      raise "Term expected at position " + @lexer.pos(@index).to_s
    end
  end

  #fact: func
  #    | func ^ fact         ;;  -sin-5^-sin-5^-sin-5
  #    ;                     ;;  先算指数，再算全部，最后看是否乘-1
  def fact
    begin
      base = func
      if !ended? && @tokens[@index].value == '^'
        @index += 1
        exponent = fact
        tree = Tree.new('Factor', '^', base, exponent)
      else
        return base
      end
    rescue
      raise "Factor expected at position " + @lexer.pos(@index).to_s
    end
  end

  #func: atom                ;;  -5
  #    | FUNCTOR func        ;;  sin-5, sinsin-5
  #    | SIGN func           ;;  -sinsin-5
  #    ;                     ;;  从右向左计算，最后看是否乘-1
  def func
    begin
      token = @tokens[@index]
      # puts token
      # p token
      if token.ttype == :fun
        if token.value == 'sin'
          @index += 1
          subtree = func
          return Tree.new('Funcall', 'sin', subtree)
        elsif token.value == 'cos'
          @index += 1
          subtree = func
          return Tree.new('Funcall', 'cos', subtree)
        elsif token.value == 'tan'
          @index += 1
          subtree = func
          return Tree.new('Funcall', 'tan', subtree)
        elsif token.value == 'log'
          puts 'fuck'
          @index += 1
          subtree = func
          return Tree.new('Funcall', 'log', subtree)
        elsif token.value == 'ln'
          @index += 1
          subtree = func
          return Tree.new('Funcall', 'ln', subtree)
        else  # 类型为:fun，值却不属于以上5种，显然是一个错误的标记
          raise  
        end
      elsif token.ttype == :op
        if token.value == '+'
          @index += 1
          subtree = func
          return Tree.new('Sign', '+', subtree)
        elsif token.value == '-'
          @index += 1
          subtree = func
          return Tree.new('Sign', '-', subtree)
        else
          raise
        end
      else
        atom
      end
    rescue
      raise "Function expected at position " + @lexer.pos(@index).to_s
    end
  end

  #atom: NUMBER
  #    | ( expr )
  #    ;
  def atom
    begin
      token = @tokens[@index]
      if token.ttype == :num
        number
      elsif token.value == '('
        @index += 1
        tree = rotate(expr)
        if !ended? && @tokens[@index].value == ')'
          @index += 1
          return Tree.new('Atom', tree)  # 防止2-(3-4)被旋转成(- (- 2 3) 4)
        else
          raise "')' expected at position " + @lexer.pos(@index).to_s
        end
      else
        raise "Atom expected at position " + @lexer.pos(@index).to_s
      end
    rescue => e
      raise e
    end
  end

  def number
    begin
      token = @tokens[@index]
      # p token
      raise if token.ttype != :num
      @index += 1
      Tree.new('Number', token.value)
    rescue
      raise "Number expected at position " + @lexer.pos(@index).to_s
    end
  end

###############  Utility Methods  ###############

  # 消除Atom封装，将Atom()下的子树解放出来，因为Atom对求值器没有
  def eliminate_atom(tree)
    return tree if tree.class != Tree

    return tree.root if tree.ttype == 'Atom'

    tree.lchild = eliminate_atom(tree.lchild)
    tree.rchild = eliminate_atom(tree.rchild)
    return tree
  end

  # 将右递归树转化成左递归树（仅限于Expr和Term顶点树）
  def rotate(tree)
    begin
      while tree.rchild.rchild != nil && tree.ttype == tree.rchild.ttype && (tree.ttype == 'Expr' || tree.ttype == 'Term')
        newtree = tree.rchild
        tree.rchild = newtree.lchild
        newtree.lchild = tree
        tree = newtree
      end
    rescue
    ensure
      return tree
    end
  end

  # 直接用fact解析--2^-3^-4得到的语法树是(^ (- (- 2)) (^ (- 3) (- 4)))
  #                                         ^^^^^^^^^
  # 而正确的结果应当是(- (- (^ 2 (^ (- 3) (- 4)))))
  #                    ^^^^    ^
  # 这是当前采用的语法本身的缺陷，只能通过调整语法树来修正这个错误
  # 函数justify_fact的作用正是调整语法树
  def justify_fact(tree)
    # puts "justify_fact: " + tree.to_s
    if tree.ttype == 'Factor' && tree.lchild.ttype == 'Sign'
      branch = newtree = tree.lchild
      branch = branch.lchild while branch.lchild.ttype == 'Sign'
      tree.lchild = branch.lchild
      branch.lchild = tree
      newtree
    else tree end
  end

  # 判断是否已经“吃进”所有token，或者说是否已经没有token可用
  def ended?
    @index >= @tokens.size
  end

end # of class Parser

# --------------------------------------------------------------------
class Evaluator
  def Evaluator.eval(tree)
    begin
      case tree.ttype

        when 'Number'
          tree.root.to_f

        when 'Sign'
          param = eval(tree.lchild)
          if tree.root == '+'
            param
          elsif tree.root == '-'
            -1 * param
          else
            raise "Malformed syntax tree!"
          end

        when 'Funcall'
          param = eval(tree.lchild)
          case tree.root
            when 'sin'
              Math.sin(param)
            when 'cos'
              Math.cos(param)
            when 'tan'
              Math.tan(param)
            when 'log'
              Math.log10(param)
            when 'ln'
              Math.log(param)
            else
              raise "Malformed syntax tree!"
          end

        when 'Factor'
          raise "Malformed syntax tree!" if tree.root != '^'
          base = eval(tree.lchild)
          power = eval(tree.rchild)
          base ** power

        when 'Term'
          param1 = eval(tree.lchild)
          param2 = eval(tree.rchild)
          if tree.root == '*'
            param1 * param2
          elsif tree.root == '/'
            param1 / param2
          else
            raise "Malformed syntax tree!"
          end

        when 'Expr'
          param1 = eval(tree.lchild)
          param2 = eval(tree.rchild)
          if tree.root == '+'
            param1 + param2
          elsif tree.root == '-'
            param1 - param2
          else
            raise "Malformed syntax tree!"
          end

        else # unknown tree.ttype
          raise "Malformed syntax tree!"

      end # of the big case block

    rescue => e
      raise e
    end # of begin-rescue-end block
  end # of method `eval'
end # of class Evaluator


# --------------------------------------------------------------------
class RCalc
  def RCalc.calc(text)
    begin
      parser = Parser.new(text)
      tree = parser.parse
      result = Evaluator.eval(tree)
      result = result.to_s.sub(/\.0$/, '')
      puts "Result=#{result}"
      return result
    rescue
      $stderr.puts $!
      return $!
    end
  end
end
# --------------------------------------------------------------------

# Test
RCalc.calc(ARGV[0].to_s)
