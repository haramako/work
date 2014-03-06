
require 'gnuplot'

def df(w)
  r = w.clone
  dt = 0.3
  w.size.times do |x|
    next 0 if x == 0
    r[x] = w[x] + (w[x-1] - w[x]) * dt
  end
  r
end

def delta(w)
  (0...w.size).map do |x|
    next 0 if x == 0
    next 0 if x >= w.size-1
    ( w[x+1] - w[x-1] )/2.0
    # w[x] - w[x-1] 
  end
end

def cip(w, step)
  u = 1
  dt = 0.3
  g = Array.new(w.size){0}
  # g = delta(w)
  step.times do |i|
    wn = w.clone
    gn = g.clone
    w.size.times do |x|
      next if x == 0
      next if x == w.size-1
      s = 1
      a1 = -2*( w[x] - w[x-s] )*s  +  (   g[x] + g[x-s] )
      b1 = -3*( w[x] - w[x-s] )    +  ( 2*g[x] + g[x-s] )*s
      c1 = g[x]
      d1 = w[x]
      xi = -u*dt
      wn[x] = a1 * (xi**3) + b1*(xi**2) + c1*xi + d1
      gn[x] = 3*a1*(xi**2) + 2*b1*xi + g[x]
    end
    g = gn
    w = wn
  end
  w
end

def wave(size)
  (0..size).map do |x|
    if x > 5 and x < size/4
      10.0
    else
      0.0
    end
  end
end


Gnuplot.open do |gnuplot|
  
  Gnuplot::Plot.new( gnuplot ) do |plot|
    plot.title 'CIP'
    plot.yrange '[-2:15.0]'

    w0 = wave(400)
    step = 800
    
    plot.data << Gnuplot::DataSet.new( w0 ) do |ds|
      ds.with = 'lines'
    end

    plot.data << Gnuplot::DataSet.new( cip(w0, step) ) do |ds|
      ds.with = 'lines'
    end

    w2 = w0
    step.times { w2 = df(w2) }
    
    plot.data << Gnuplot::DataSet.new( w2 ) do |ds|
      ds.with = 'lines'
    end
  end

end

sleep 10





