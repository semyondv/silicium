require 'silicium'
require 'chunky_png'
require 'ruby2d'


module Silicium
  module Plotter
    #
    # Factory method to return a color value, based on the arguments given.
    #
    # @overload Color(r, g, b, a)
    #   @param (see ChunkyPNG::Color.rgba)
    #   @return [Integer] The rgba color value.
    #
    # @overload Color(r, g, b)
    #   @param (see ChunkyPNG::Color.rgb)
    #   @return [Integer] The rgb color value.
    #
    # @overload Color(hex_value, opacity = nil)
    #   @param (see ChunkyPNG::Color.from_hex)
    #   @return [Integer] The hex color value, with the opacity applied if one
    #     was given.
    #
    # @overload Color(color_name, opacity = nil)
    #   @param (see ChunkyPNG::Color.html_color)
    #   @return [Integer] The hex color value, with the opacity applied if one
    #     was given.
    #
    # @overload Color(color_value, opacity = nil)
    #   @param [Integer, :to_i] The color value.
    #   @return [Integer] The color value, with the opacity applied if one was
    #     given.
    #
    # @return [Integer] The determined color value as RGBA integer.
    # @raise [ArgumentError] if the arguments weren't understood as a color.
    def Color(*args)
      case args.length
      when 1; ChunkyPNG::Color.parse(args.first)
      when 2; (ChunkyPNG::Color.parse(args.first) & 0xffffff00) | args[1].to_i
      when 3; ChunkyPNG::Color.rgb(*args)
      when 4; ChunkyPNG::Color.rgba(*args)
      else raise ArgumentError, "Don't know how to create a color from #{args.inspect}!"
      end
    end
    ##
    # A class representing canvas for plotting bar charts and function graphs
    class Image
      ##
      # Creates a new plot with chosen +width+ and +height+ parameters
      # with background colored +bg_color+
      def initialize(width, height, bg_color = ChunkyPNG::Color::TRANSPARENT)
        @image = ChunkyPNG::Image.new(width, height, bg_color)
      end

      def rectangle(x, y, width, height, color)
        x_end = x + width - 1
        y_end = y + height - 1
        (x..x_end).each do |i|
          (y..y_end).each do |j|
            @image[i, j] = color
          end
        end
      end

      ##
      # Draws a bar chart in the plot using provided +bars+,
      # each of them has width of +bar_width+ and colored +bars_color+
      def bar_chart(bars, bar_width, bars_color = ChunkyPNG::Color('red @ 1.0'), axis_color = ChunkyPNG::Color::BLACK)
        if bars.count * bar_width > @image.width
          raise ArgumentError, 'Not enough big size of image to plot these number of bars'
        end

        padding = 5
        # Values of x and y on borders of plot
        minx = [bars.collect { |k, _| k }.min, 0].min
        maxx = [bars.collect { |k, _| k }.max, 0].max
        miny = [bars.collect { |_, v| v }.min, 0].min
        maxy = [bars.collect { |_, v| v }.max, 0].max
        dpux = Float((@image.width - 2 * padding)) / (maxx - minx + bar_width) # Dots per unit for X
        dpuy = Float((@image.height - 2 * padding)) / (maxy - miny) # Dots per unit for Y
        rectangle(padding, @image.height - padding - (miny.abs * dpuy).ceil, @image.width - 2 * padding, 1, axis_color) # Axis OX
        rectangle(padding + (minx.abs * dpux).ceil, padding, 1, @image.height - 2 * padding, axis_color) # Axis OY

        bars.each do |x, y| # Cycle drawing bars
          rectangle(padding + ((x + minx.abs) * dpux).floor,
                    @image.height - padding - (([y, 0].max + miny.abs) * dpuy).ceil + (y.negative? ? 1 : 0),
                    bar_width, (y.abs * dpuy).ceil, bars_color)
        end
      end

      ##
      # Exports plotted image to file +filename+
      def export(filename)
        @image.save(filename, :interlace => true)
      end
    end
    class Plot

      @img = nil
      @center_x = nil
      @center_y = nil
      @mul = nil

      def initialize(width=1280, height=720, bg_color = ChunkyPNG::Color::TRANSPARENT)
        @img = ChunkyPNG::Image.new(width, height, bg_color)
        @center_x = @img.width / 2
        @center_y = @img.height / 2
        @mul = @img.height  / 15
      end

      def draw_point(x, y)
        @img[x + @center_x, @center_y - y] = ChunkyPNG::Color.rgb(0,0,0)
      end

      def draw_axes
        (-@center_x...@center_x).each do |i|
          draw_point(i, 0)
        end
        (-(@center_y - 1)...@center_y).each do |i|
          draw_point(0, i)
        end
      end

      def save(fname)
        @img.save(fname, :interlace => true)
      end

      def fn(x)
        #Math::asin(Math::sqrt(x))
        Math::cos(x)
        #x**2
        #14/x
      end

      def reset_step(x, st, &f)
        y1 = f.call(x)
        y2 = f.call(x + st)

        if (y1 - y2).abs > 1.0
          [st / (y1 - y2).abs, 0.001].max
        else
          st
        end
      end

      def draw_fn(a, b, &func)
        step = 0.12
        c_step = step
        arg = a

        while arg < b do
          c_step = step
          begin
            c_step = reset_step(arg, step) {|xx| fn(xx)}
          rescue Math::DomainError
            arg += c_step * 0.1
          else
            draw_point(arg * @mul, func.call(arg) * @mul)
          ensure
            arg += c_step
          end
        end
      end

    end
  end
end