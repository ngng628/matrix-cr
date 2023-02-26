class DimensionMismatch < Exception
  def initialize(message = "Dimension Mismatch.")
    super(message)
  end
end

class NotRegular < Exception
  def initialize(message = "Not Regular.")
    super(message)
  end
end

class Matrix(T)
  include Enumerable(T)

  getter row_size : Int32
  getter column_size : Int32
  @mat : Array(Array(T))

  def self.[](*rows : Array(U)) forall U
    mat = Array(Array(U)).new(rows.size)
    rows.each do |row|
      mat << row
    end
    new mat
  end

  def self.zero(row_size : Int, column_size : Int = row_size)
    new row_size, column_size, T.zero
  end

  def self.identity(n : Int)
    mat = Array.new(n) { Array(T).new(n) { T.zero } }
    n.times { |i| mat[i][i] = T.zero + 1 }
    new mat
  end

  def self.build(row_size : Int, column_size : Int = row_size, & : Int32, Int32 -> T)
    mat = Array.new(row_size) { |i|
      Array(T).new(column_size) { |j|
        yield i, j
      }
    }
    new mat
  end

  def self.row_vector(row : Array(T))
    new [row]
  end

  def self.rows(rows : Array(Array(T)), copy = false)
    m = copy ? rows.clone : rows
    new m
  end

  def self.column_vector(column : Array(T))
    new [column].transpose
  end

  def self.columns(columns : Array(Array(T)))
    new columns.transpose
  end

  def self.combine(*matrices, &)
    x = matrices.first
    matrices.each do |m|
      raise DimensionMismatch.new unless x.row_size == m.row_size && x.column_size == m.column_size
    end

    mat = Array.new(x.row_size) { |i|
      Array.new(x.column_size) { |j|
        yield matrices.map { |m| m[i, j] }
      }
    }

    new mat
  end

  def self.diagonal(*values)
    n = values.size
    mat = Array.new(n) { |i|
      row = Array.new(n) { values[i].class.zero }
      row[i] = values[i]
      row
    }
    new mat
  end

  def self.empty(row_size = 0, column_size = 0)
    raise ArgumentError.new("One size must be 0") if row_size != 0 && column_size != 0
    raise ArgumentError.new("Negative size") if row_size < 0 && column_size < 0
    new Array.new(row_size + column_size) { [] of T }, column_size
  end

  def self.hstack(*matrices)
    x = matrices.first
    matrices.each do |m|
      raise DimensionMismatch.new if x.row_size != m.row_size
    end

    mat = Array.new(x.row_size) { |i|
      matrices.flat_map(&.row(i))
    }

    new mat
  end

  def self.scalar(n : Int, value : T)
    mat = Array.new(n) { Array(T).new(n) { T.zero } }
    n.times { |i| mat[i][i] = value }
    new mat
  end

  def self.vstack(*matrices : Matrix(T))
    x = matrices.first
    matrices.each do |m|
      raise DimensionMismatch.new if x.column_size != m.column_size
    end

    mat = matrices.flat_map { |m|
      m.row_size.times.map { |i| m.row(i) }
    }

    new mat
  end

  @[AlwaysInline]
  def row(i : Int)
    @mat[i]
  end

  {% for op in %i(+ - ^ | &) %}
    def {{ op.id }}(other : Matrix(U)) forall U
      n = @row_size
      m = @column_size

      raise DimensionMismatch.new if n != other.row_size || m != other.column_size

      Matrix(T).build(n, m) { |i, j|
        self.unsafe_fetch(i, j) {{ op.id }} other.unsafe_fetch(i, j)
      }
    end
  {% end %}

  def *(other : Matrix(U)) forall U
    n = @row_size
    m = @column_size
    k = other.column_size

    raise DimensionMismatch.new if m != other.row_size

    mat = Matrix(T).zero(n, k)
    n.times do |x|
      m.times do |z|
        k.times do |y|
          a = mat.unsafe_fetch(x, y)
          b = unsafe_fetch(x, z)
          c = other.unsafe_fetch(z, y)
          mat.unsafe_put(x, y, a + b*c)
        end
      end
    end

    mat
  end

  def **(exponent : Int)
    case exponent
    when .<(-1)
      inv ** exponent.abs
    when .==(-1)
      inv
    when .==(0)
      Matrix(T).identity(@row_size)
    else
      power_int(exponent)
    end
  end

  {% for op in %i(* / //) %}
    def {{ op.id }}(other) forall U
      n = @row_size
      m = @column_size

      Matrix(T).build(n, m) { |i, j|
        self.unsafe_fetch(i, j) {{ op.id }} other
      }
    end
  {% end %}

  def ==(other : Matrix(U)) forall U
    return false if @row_size != other.row_size || @column_size != other.column_size
    @row_size.times do |i|
      @column_size.times do |j|
        return false if self[i, j] != other[i, j]
      end
    end
    true
  end

  def each(& : T ->)
    @row_size.times do |i|
      @column_size.times do |j|
        yield @mat[i][j]
      end
    end
  end

  def each(which = :all, &block : T ->)
    case which
    when :all
      @mat.each do |v|
        v.each(&block)
      end
    when :diagonal
      @mat.each_with_index do |v, i|
        break unless i < v.size
        yield v.unsafe_fetch(i)
      end
    when :off_diagonal
      @mat.each_with_index do |v, i|
        @column_size.times do |j|
          yield v[j] unless i == j
        end
      end
    when :lower
      @mat.each_with_index do |v, i|
        (0..::Math.min(i, @column_size - 1)).each do |j|
          yield v[j]
        end
      end
    when :strict_lower
      @mat.each_with_index do |v, i|
        Math.min(i, @column_size).times do |j|
          yield v[j]
        end
      end
    when :struct_upper
      @mat.each_with_index do |v, i|
        (i + 1...@column_size).each do |j|
          yield v[j]
        end
      end
    when :upper
      @mat.each_with_index do |v, i|
        (i...@column_size).each do |j|
          yield v[j]
        end
      end
    else
      raise ArgumentError.new("expected #{which} to be one of :all :diagonal, :lower, :strict_lower, :strict_upper or :upper")
    end
  end

  def each(which = :all)
    ItemIterator(self, T).new(self, which)
  end

  def each_with_index(which = :all, & : T ->)
    case which
    when :all
      @mat.each_with_index do |v, i|
        v.each_with_index do |a, j|
          yield a, i, j
        end
      end
    when :diagonal
      @mat.each_with_index do |v, i|
        break unless i < v.size
        yield v.unsafe_fetch(i), i, i
      end
    when :off_diagonal
      @mat.each_with_index do |v, i|
        @column_size.times do |j|
          yield v[j], i, j unless i == j
        end
      end
    when :lower
      @mat.each_with_index do |v, i|
        (0..::Math.min(i, @column_size - 1)).each do |j|
          yield v[j], i, j
        end
      end
    when :strict_lower
      @mat.each_with_index do |v, i|
        Math.min(i, @column_size).times do |j|
          yield v[j], i, j
        end
      end
    when :struct_upper
      @mat.each_with_index do |v, i|
        (i + 1...@column_size).each do |j|
          yield v[j], i, j
        end
      end
    when :upper
      @mat.each_with_index do |v, i|
        (i...@column_size).each do |j|
          yield v[j], i, j
        end
      end
    else
      raise ArgumentError.new("expected #{which} to be one of :all :diagonal, :lower, :strict_lower, :strict_upper or :upper")
    end
  end

  def adjugate
    raise DimensionMismatch.new unless square?
    Matrix(T).build(@row_size, @column_size) { |i, j|
      cofactor(j, i)
    }
  end

  def cofactor(i : Int, j : Int)
    raise RuntimeError.new("cofactor of empty matrix is not defined") if empty?
    raise DimensionMismatch.new unless square?

    det = first_minor(i, j).det
    det * (-1)**(i + j)
  end

  def first_minor(i : Int, j : Int)
    raise RuntimeError.new("first_minor of empty matrix is not defined") if empty?

    unless (0...@row_size).includes?(i)
      raise ArgumentError.new("invalid row (#{i} for 0..#{@row_size - 1})")
    end

    unless (0...@column_size).includes?(j)
      raise ArgumentError.new("invalid row (#{j} for 0..#{@column_size - 1})")
    end

    a = @mat.clone
    a.delete_at(i)
    a.each do |v|
      v.delete_at(j)
    end

    self.class.rows(a)
  end

  def symmetric?
    raise DimensionMismatch.new unless square?
    each_with_index(:strict_upper) do |a_ij, i, j|
      return false if a_ij != unsafe_fetch(j, i)
    end
    true
  end

  def antisymmetric?
    skew_symmetric?
  end

  def skew_symmetric?
    raise DimensionMismatch.new unless square?
    each_with_index(:strict_upper) do |a_ij, i, j|
      return false if a_ij != -unsafe_fetch(j, i)
    end
    true
  end

  def det
    raise DimensionMismatch.new if @row_size != @column_size
    n = @row_size
    case n
    when 0
      1
    when 1
      self[0, 0]
    when 2
      self[0, 0] * self[1, 1] - self[0, 1] * self[1, 0]
    when 3
      m0 = row(0)
      m1 = row(1)
      m2 = row(2)
      + m0[0] * m1[1] * m2[2] - m0[0] * m1[2] * m2[1] \
      - m0[1] * m1[0] * m2[2] + m0[1] * m1[2] * m2[0] \
      + m0[2] * m1[0] * m2[1] - m0[2] * m1[1] * m2[0]
    when 4
      m0 = row(0)
      m1 = row(1)
      m2 = row(2)
      m3 = row(3)
      + m0[0] * m1[1] * m2[2] * m3[3] - m0[0] * m1[1] * m2[3] * m3[2] \
      - m0[0] * m1[2] * m2[1] * m3[3] + m0[0] * m1[2] * m2[3] * m3[1] \
      + m0[0] * m1[3] * m2[1] * m3[2] - m0[0] * m1[3] * m2[2] * m3[1] \
      - m0[1] * m1[0] * m2[2] * m3[3] + m0[1] * m1[0] * m2[3] * m3[2] \
      + m0[1] * m1[2] * m2[0] * m3[3] - m0[1] * m1[2] * m2[3] * m3[0] \
      - m0[1] * m1[3] * m2[0] * m3[2] + m0[1] * m1[3] * m2[2] * m3[0] \
      + m0[2] * m1[0] * m2[1] * m3[3] - m0[2] * m1[0] * m2[3] * m3[1] \
      - m0[2] * m1[1] * m2[0] * m3[3] + m0[2] * m1[1] * m2[3] * m3[0] \
      + m0[2] * m1[3] * m2[0] * m3[1] - m0[2] * m1[3] * m2[1] * m3[0] \
      - m0[3] * m1[0] * m2[1] * m3[2] + m0[3] * m1[0] * m2[2] * m3[1] \
      + m0[3] * m1[1] * m2[0] * m3[2] - m0[3] * m1[1] * m2[2] * m3[0] \
      - m0[3] * m1[2] * m2[0] * m3[1] + m0[3] * m1[2] * m2[1] * m3[0]
    else
      a = clone
      res = T.zero + 1
      n.times do |i|
        idx = (i...n).to_a.rindex { |j| !a[j, i].zero? }
        return T.zero if idx.nil?
        idx += i

        if i != idx
          res = -res
          a.swap_row(i, idx)
        end

        res *= a[i, i]
        v = a[i, i]

        n.times do |j|
          if v.is_a? Float
            a[i, j] /= v
          else
            a[i, j] //= v
          end
        end

        (i + 1...n).each do |j|
          a_ji = a[j, i]
          n.times do |k|
            a[j, k] -= a[i, k] * a_ji
          end
        end
      end
      res
    end
  end

  def inv
    raise DimensionMismatch.new if @row_size != @column_size

    n = @row_size
    a = clone
    res = Matrix(T).identity(n)
    rank = 0
    n.times do |j|
      pivot = (rank...n).max_by? { |i| a[i, j].abs }
      next if pivot.nil?

      a.swap_row(pivot, rank)
      res.swap_row(pivot, rank)

      fac = a[rank, j]
      n.times do |k|
        if fac.is_a? Float
          a[rank, k] /= fac
          res[rank, k] /= fac
        else
          a[rank, k] //= fac
          res[rank, k] //= fac
        end
      end

      n.times do |i|
        if i != rank && !a[i, j].abs.zero?
          fac = a[i, j]
          n.times do |k|
            a[i, k] -= a[rank, k] * fac
            res[i, k] -= res[rank, k] * fac
          end
        end
      end

      rank += 1
    end

    res
  end

  # def laplace_expansion(i : Int? = nil, j : Int? = nil)
  #   n = i || j
  #
  #   if n.nil? || (i && j)
  #     raise ArgumentError.new("exactly one the row or column arguments must be specified")
  #   end
  #
  #   raise DimensionMismatch.new unless square?
  #   raise RuntimeError.new("laplace_expansion of empty matrix is not defined") if empty?
  #
  #   unless 0 <= n && n < @row_size
  #     raise ArgumentError.new("invalid num (#{n} for 0...#{@row_size})")
  #   end
  #
  # end



  @[AlwaysInline]
  def square?
    @row_size == @column_size
  end

  def diagonal?
    raise DimensionMismatch.new unless square?
    each(:off_diagonal).all?(&.zero?)
  end

  @[AlwaysInline]
  def unsafe_fetch(i : Int, j : Int)
    @mat.unsafe_fetch(i).unsafe_fetch(j)
  end

  @[AlwaysInline]
  def unsafe_put(i : Int, j : Int, value : T)
    @mat.unsafe_fetch(i)[j] = value
  end

  @[AlwaysInline]
  def []=(i : Int, j : Int, value : T)
    @mat[i][j] = value
  end

  @[AlwaysInline]
  def [](i : Int, j : Int)
    @mat[i][j]
  end

  @[AlwaysInline]
  def []?(i : Int, j : Int)
    @mat[i]? ? @mat[i][j]? : nil
  end

  def clone
    Matrix.build(@row_size, @column_size) { |i, j| self[i, j] }
  end

  def to_s(io : IO)
    @mat.each_with_index do |v, x|
      v.each_with_index do |ai, y|
        io << " " if y != 0
        io << ai
      end
      io << "\n"
    end
  end

  @[AlwaysInline]
  def empty?
    @row_size == 0 || @column_size == 0
  end

  @[AlwaysInline]
  def swap_row(i : Int, j : Int)
    @mat.swap(i, j)
  end

  @[AlwaysInline]
  def swap_column(i : Int, j : Int)
    @row_size.times do |x|
      @mat[x, i], @mat[x, j] = @mat[x, j], @mat[x, i]
    end
  end

  private def initialize(@row_size, @column_size, value)
    @mat = Array.new(@row_size) { Array.new(@column_size) { value } }
  end

  private def initialize(@mat : Array(Array(T)), column_count = nil)
    @row_size = @mat.size
    @column_size = column_count || @mat.fetch(0) { [] of T }.size
  end

  private def power_int(exponent : Int)
    mat = Matrix(T).identity(@row_size)
    a = self.clone
    until exponent == 0
      mat *= a if exponent.odd?
      a *= a
      exponent >>= 1
    end
    mat
  end

  private class ItemIterator(M, T)
    include Iterator(T)

    def initialize(@matrix : M, @which = :all, @i = 0, @j = 0)
      if @i == 0 && @j == 0
        case @which
        when :off_diagonal
          @j += 1
          if @j >= @matrix.column_size
            @i += 1
            @j = 0
          end
        when :strict_lower
          @i += 1
        when :struct_upper
          @j += 1
          if @j >= @matrix.column_size
            @i += 1
            @j = @i + 1
          end
        end
      end
    end

    def next
      case @which
      when :all
        if @i >= @matrix.row_size
          stop
        else
          value = @matrix.unsafe_fetch(@i, @j)
          @j += 1
          if @j >= @matrix.column_size
            @j = 0
            @i += 1
          end
          value
        end
      when :diagonal
        if @i >= @matrix.row_size
          stop
        else
          value = @matrix.unsafe_fetch(@i, @j)
          @i += 1
          @j += 1
          value
        end
      when :off_diagonal
        if @i >= @matrix.row_size
          stop
        else
          value = @matrix.unsafe_fetch(@i, @j)
          @j += 1
          @j += 1 if @i == @j
          if @j >= @matrix.column_size
            @i += 1
            @j = 0
          end
        end
      when :lower
        if @i >= @matrix.row_size
          stop
        else
          value = @matrix.unsafe_fetch(@i, @j)
          @j += 1
          if @j >= Math.min(@i + 1, @matrix.column_size)
            @i += 1
            @j = 0
          end
          value
        end
      when :strict_lower
        if @i >= @matrix.row_size
          stop
        else
          value = @matrix.unsafe_fetch(@i, @j)
          @j += 1
          if @j >= Math.min(@i, @matrix.column_size)
            @i += 1
            @j = 0
          end
          value
        end
      when :struct_upper
        if @i >= @matrix.row_size || @j >= @matrix.column_size
          stop
        else
          value = @matrix.unsafe_fetch(@i, @j)
          if @j >= @matrix.column_size
            @i += 1
            @j = @i + 1
          end
          value
        end
      when :upper
        if @i >= @matrix.row_size || @j >= @matrix.column_size
          stop
        else
          value = @matrix.unsafe_fetch(@i, @j)
          if @j >= @matrix.column_size
            @i += 1
            @j = @i
          end
          value
        end
      else
        raise ArgumentError.new("expected #{@which} to be one of :all :diagonal, :lower, :strict_lower, :strict_upper or :upper")
      end
      stop
    end
  end

  # private class ReverseItemIterator(A, T)
  #   include Iterator(T)

  #   def initialize(@array : A, @index : Int32 = array.size - 1)
  #   end

  #   def next
  #     if @index < 0
  #       stop
  #     else
  #       value = @array[@index]
  #       @index -= 1
  #       value
  #     end
  #   end
  # end
end
