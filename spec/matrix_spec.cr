require "../src/matrix.cr"
require "spec"

describe Matrix do
  describe ".[]" do
    it "init" do
      mat = Matrix[[1, 2, 3], [4, 5, 6], [7, 8, 9]]
      puts mat
    end
  end

  describe ".zero" do
    it "zero mat" do
      zero = Matrix(Int32).zero(2)
      puts zero
    end
  end

  describe ".identify" do
    it "identify matrix" do
      id = Matrix(Int32).identity(3)
      puts id
    end
  end

  describe ".build" do
    it "build" do
      mat = Matrix.build(2, 3) { 3 }
      puts mat
      mat = Matrix.build(3, 2) { |i, _| i }
      puts mat
    end
  end

  describe ".row_vector" do
    it "row vector" do
      mat = Matrix.row_vector([1, 2, 3])
      puts mat
    end
  end

  describe ".rows" do
    it "row vector" do
      mat = Matrix.rows([[1, 2, 3], [4, 5, 6]])
      puts mat
    end
  end

  describe ".column_vector" do
    it "column vector" do
      mat = Matrix.column_vector([1, 2, 3])
      puts mat
    end
  end

  describe ".columns" do
    it "column vector" do
      mat = Matrix.columns([[1, 2, 3], [4, 5, 6]])
      puts mat
    end
  end

  describe ".combine" do
    it "combine" do
      m1 = Matrix[[1, 2, 3], [4, 5, 6]]
      m2 = Matrix[[10, 20, 30], [40, 50, 60]]
      mat = Matrix.combine(m1, m2) { |a, b| a + b }
      puts mat
    end
  end

  describe ".diagonal" do
    it "diagonal" do
      mat = Matrix.diagonal(1, 2, 3)
      puts mat
    end
  end

  describe ".empty" do
    it "empty" do
      mat = Matrix(Int32).empty(2, 0)
      puts mat
      mat = Matrix(Int32).empty(0, 3)
      puts mat
    end
  end

  describe ".hstack" do
    it "hstack" do
      a = Matrix[[1, 2], [3, 4]]
      b = Matrix[[5, 6], [7, 8]]
      mat = Matrix(Int32).hstack(a, b)
      mat.should eq Matrix[[1, 2, 5, 6], [3, 4, 7, 8]]
    end
  end

  describe ".scalar" do
    it "scalar" do
      mat = Matrix(Int32).scalar(3, 2)
      mat.should eq Matrix[[2, 0, 0], [0, 2, 0], [0, 0, 2]]
    end
  end

  describe ".vstack" do
    it "vstack" do
      a = Matrix[[1, 2], [3, 4]]
      b = Matrix[[5, 6], [7, 8]]
      mat = Matrix(Int32).vstack(a, b)
      mat.should eq Matrix[[1, 2], [3, 4], [5, 6], [7, 8]]
    end
  end

  describe ".+" do
    it "+" do
      a = Matrix[[1, 2], [3, 4]]
      b = Matrix[[5, 6], [7, 8]]
      (a + b).should eq Matrix[[6, 8], [10, 12]]
    end
  end

  describe ".*" do
    it "*" do
      a = Matrix[[1, 2], [3, 4]]
      (a * 2).should eq Matrix[[2, 4], [6, 8]]
    end
  end

  describe ".**" do
    it "**" do
      m = Matrix[[1, 1], [1, 0]]
      (m ** 8).should eq Matrix[[34, 21], [21, 13]]
      (m ** 0).should eq Matrix[[1, 0], [0, 1]]

      m = Matrix[[1.0, 3.0, 3.0], [-1.0, 1.0, 4.0], [1.0, 2.0, 1.0]]
      (m ** (-1)).should eq Matrix[[7.0, -3.0, -9.0], [-5.0, 2.0, 7.0], [3.0, -1.0, -4.0]]
      (m ** (-2)).should eq (Matrix[[7.0, -3.0, -9.0], [-5.0, 2.0, 7.0], [3.0, -1.0, -4.0]] ** 2)
    end
  end

  describe "#inv" do
    it "inverse" do
      m = Matrix[[1, 0], [0, 1]]
      m.inv.should eq Matrix[[1, 0], [0, 1]]

      m = Matrix[[1.0, 3.0, 3.0], [-1.0, 1.0, 4.0], [1.0, 2.0, 1.0]]
      m.inv.should eq Matrix[[7.0, -3.0, -9.0], [-5.0, 2.0, 7.0], [3.0, -1.0, -4.0]]
    end
  end

  describe "#adjugate" do
    it "adjugate" do
      m = Matrix[[7, 6], [3, 9]]
      m.adjugate.should eq Matrix[[9, -6], [-3, 7]]
    end
  end

  describe "#each" do
    it "each" do
      puts "begin"
      m = Matrix[[1, 2], [3, 4], [5, 6]]
      # m.each(:diagonal) { |i| puts i }
      m.each(:upper) { |i| puts i }
      puts "end"
    end
  end

  describe "#diagonal?" do
    it "diagonal?" do
      Matrix.diagonal(10, -3).diagonal?.should eq true
      Matrix[[1, 0, 0], [0, 2, 0], [3, 3, 3]].diagonal?.should eq true
    end
  end
end
