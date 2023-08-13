# frozen_string_literal: true

require 'json'

# A hangman game
class Game
  def initialize
    dict = File.read('google-10000-english-no-swears.txt').split.filter { |w| w.length >= 5 && w.length <= 12 }

    @word = dict.sample.upcase

    @guesses_left = 13
    @incorrect = []
    @correct = []
  end

  def status
    @word.split('').each { |c| print(@correct.include?(c) ? c : '_') }
    puts
    puts
    puts "Correct: #{@correct.sort.join('')}, Wrong: #{@incorrect.sort.join('')}, Left: #{@guesses_left}"
  end

  def finished?
    @word.split('').all? { |c| @correct.include?(c) }
  end

  def save
    print 'Filename? '
    fn = gets.chomp
    f = File.open("save/#{fn}", 'w')
    f.write(JSON.dump({
                        word: @word,
                        guesses_left: @guesses_left,
                        incorrect: @incorrect,
                        correct: @correct
                      }))
    f.close
  end

  def load
    d = Dir.new('save')
    files = d.to_a.reject { |f| f[0] == '.' }
    puts 'Save files:'
    files.each_with_index { |f, i| puts "#{i}) #{f}" }
    print 'Number? '
    n = gets.to_i
    return unless n >= 0 && n < files.length

    json_string = File.read("save/#{files[n]}")
    values = JSON.parse(json_string, { symbolize_names: true })
    @word = values[:word]
    @guesses_left = values[:guesses_left]
    @incorrect = values[:incorrect]
    @correct = values[:correct]
  end

  def run
    loop do
      status
      print "Enter a letter: ('>' to save, '<' to load)"
      c = gets[0].upcase
      case c
      when '>'
        save
        break
      when '<'
        load
        next
      else
        if @word.include?(c)
          @correct.append(c)
        else
          @incorrect.append(c)
          @guesses_left -= 1
        end
        if finished?
          puts "You guessed #{@word}."
          break
        elsif @guesses_left <= 0
          puts 'You lost.'
          break
        end
      end
    end
  end
end

Game.new.run
