#
include Math
require 'gnuplot'
require 'pp'

def j(a,x,y)
  a = a.to_f
  x = x.to_f
  y = y.to_f
  tmp1 = ( (x**2-y**2-4*(a**2))**2 + (2*x*y)**2 )**0.25
  tmp2 = 0.5 * atan( (2*x*y) / (x**2-y**2-4*(a**2)) )
  v1 = 0.5 * ( x + tmp1 * cos( tmp2 ) )
  v2 = 0.5 * ( y + tmp1 * sin( tmp2 ) )
  [v1, v2]
end

def j2(a,x,y)
  v1 = x + ((a**2)*x) / (x**2+y**2)
  v2 = y - ((a**2)*y) / (x**2+y**2)
  [v1,v2]
end

Gnuplot.open do |gnuplot|
  
  Gnuplot::Plot.new( gnuplot ) do |plot|
    plot.grid
    plot.xrange '[-10:10]'
    plot.yrange '[-10:10]'
    
    data = []
    0.upto(10) do |x|
      0.upto(10) do |y|
        d = j(1.0, x, y)
        # data << d unless d[0].nan?
      end
    end
    0.1.step(10, 0.1) do |y|
      #d = j(1.0, 0.5, y)
      #data << d
    end

    0.step(PI*2,0.1) do |r|
      a = 1.0
      x = 0.12
      data << j2(1.0+x, a*cos(r) + x, a*sin(r) + 0.20)
    end

    pp data

    plot.data << Gnuplot::DataSet.new( data.transpose ) do |ds|
      ds.with = 'lines'
    end
  end

end

sleep 300
