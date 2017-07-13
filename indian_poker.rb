# Encoding: UTF-8
require 'gosu'
require 'chipmunk'
require 'singleton'
require 'slave'
require "xmlrpc/client"
require 'childprocess'
require 'rbconfig'

WIDTH, HEIGHT = 1000, 700
NUM_OF_DECKS = 6
UI_PIVOT = 50
INITIAL_MONEY = 500000
BET_UNIT = 1000

# Layering of sprites
module ZOrder
  Board, Card, Mouse = 0, 1, 2
end

def is_port_open?(port)
  begin
    s = TCPServer.new("127.0.0.1", port)
  rescue Errno::EADDRINUSE
    return false
  end
  s.close
  return true
end

# Detection of OS
def is_windows?
  case RbConfig::CONFIG['host_os']
  when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
    return true
  else
    return false
  end
end

class IndianPoker < Gosu::Window

  def shuffle_cards
    @future_deck = Array.new
    (1..10).to_a.each do |x|
      NUM_OF_DECKS.times do |y|
        @future_deck << x
      end
    end
    @future_deck.shuffle!
    @current_deck = @future_deck.pop(2)
    if @sun_player == @players[0] 
      @players[0].card_number = @current_deck[0]
      @players[1].card_number = @current_deck[1]
    else
      @players[0].card_number = @current_deck[1]
      @players[1].card_number = @current_deck[0]
    end
    @past_deck = Array.new
  end

  def init_game
    @servers = Array.new
		@players.clear
		@players[0] = Player.new(0)
		@players[1] = Player.new(1)
    @play_turn = @players[0]
    @play_next = @players[1]
    @current_bet_money = 10000
    @bet_money_history = Array.new
    @current_time_for_longbutton = Time.now
    @bet_violation_cnt = 0
    @gameover = false
    @betover = false
    @sun_player = @players[0] #선플레이어

    shuffle_cards

    #Load AI
    ais = Dir.entries(".").map {|x| x if /^ai_[[:alnum:]]+.rb$/.match(x)}.compact
    xml_port = 8000
    slaves = Array.new
    ais.each do |x|
      (xml_port..8080).to_a.each do |p|
        if is_port_open?(p)
          xml_port = p
          break
        end
      end
      if is_windows?
        slaves << ChildProcess.build("ruby", x, xml_port.to_s).start
      else
        slaves << Slave.object(:async => true){ `ruby #{x} #{xml_port}` }
      end
      @servers << XMLRPC::Client.new("localhost", "/", xml_port)
      xml_port += 1
    end

    0.upto(@servers.size - 1) do |count|
      server_connection = false
      while !server_connection
        begin
          @players[count].player_name = @servers[count].call("indian.get_name")
          @players[count].ai_flag = true
          server_connection = true
        rescue Errno::ECONNREFUSED
        end
      end
    end
  end
  
  def initialize
    super(WIDTH, HEIGHT, false)
    self.caption = '인디언포커!'

    @players = Array.new(2)
    @board  = Board.instance
    @font = Gosu::Font.new(self, Gosu::default_font_name, 18)

    init_game
  end

  def draw
    @board.draw
    
    @players.each { |player| player.draw }
    if @betover or @gameover
      @font.draw("===============================베팅끝===============================", 40, 600, 1.0, 1.0, 1.0)
    end

    @font.draw("현재 턴 : #{@play_turn.player_name}", 720, UI_PIVOT + 40, 1.0, 1.0, 1.0)
    @font.draw("왼쪽카드 히든 : Q", 720, UI_PIVOT + 60, 1.0, 1.0, 1.0)
    @font.draw("오른쪽카드 히든 : W", 720, UI_PIVOT + 80, 1.0, 1.0, 1.0)

    pivot_font_y_position = [UI_PIVOT + 150, UI_PIVOT + 220]
    ui_index = 0
    position = ["LEFT", "RIGHT"]
    total_bet = Array.new
    total_bet[0] = if @play_turn == @players[1] then get_your_total_bet else get_my_total_bet end
    total_bet[1] = if @play_turn == @players[1] then get_my_total_bet else get_your_total_bet end
    @players.each do |player|
      @font.draw("#{position[ui_index]} : #{player.player_name}", 720, 
                    pivot_font_y_position[ui_index], 1.0, 1.0, 1.0)
      @font.draw("Total Money : #{player.money}", 720, 
                    pivot_font_y_position[ui_index] + 20, 1.0, 1.0, 1.0)
      @font.draw("Total Bet Money : #{total_bet[ui_index]}", 720, 
                    pivot_font_y_position[ui_index] + 40, 1.0, 1.0, 1.0)
      ui_index += 1
      unless player.hide
        left_position = [80, 380] 
        @font.draw(player.player_name, left_position[player.number], 140, 1.0, 1.0, 1.0)
      end
    end

    total_bet_money = 0
    @bet_money_history.each {|x| total_bet_money += x.to_i}
    @font.draw("판돈 : #{total_bet_money}", 720, UI_PIVOT + 310, 1.0, 1.0, 1.0)
    @font.draw("배팅 위반 : #{@bet_violation_cnt}", 720, UI_PIVOT + 330, 1.0, 1.0, 1.0)
    @font.draw("새로 시작하기 : R", 720, UI_PIVOT + 370, 1.0, 1.0, 1.0)
    @font.draw("턴 넘기기 : P", 720, UI_PIVOT + 390, 1.0, 1.0, 1.0)
    @font.draw("다음 턴 연산하기 : N", 720, UI_PIVOT + 410, 1.0, 1.0, 1.0)
    @font.draw("(사람) 배팅금액 : ", 720, UI_PIVOT + 450, 1.0, 1.0, 1.0)
    @font.draw("#{@current_bet_money}", 830, UI_PIVOT + 450, 1.0, 1.0, 1.0)
    @font.draw("(사람) 배팅금액 업 : Up, 다운 : Down", 720, UI_PIVOT + 470, 1.0, 1.0, 1.0)
    @font.draw("(사람) 콜 : C", 720, UI_PIVOT + 490, 1.0, 1.0, 1.0)
    @font.draw("(사람) 다이 : D", 720, UI_PIVOT + 510, 1.0, 1.0, 1.0)
    @font.draw("제작 : 멋쟁이사자처럼", 780, 670, 1.0, 1.0, 1.0)
  end

  def needs_cursor?
    false
  end

  def restart
    init_game
  end

  def pass_turn
    @bet_violation_cnt = 0
    @play_turn, @play_next = if @play_turn == @players[0]
                      [@players[1], @players[0]]
                   elsif @play_turn == @players[1]
                      [@players[0], @players[1]]
                   end
  end

  def set_sun(id)
    if id == 1
      @sun_player = @players[1]
      @play_turn = @players[1]
      @play_next = @players[0]
    elsif id == 0 
      @sun_player = @players[0]
      @play_turn = @players[0]
      @play_next = @players[1]
    else
      @play_turn = @sun_player
      if @play_turn == @players[0]
        @play_next = @players[1]
      else
        @play_next = @players[0]
      end
    end
  end

  def calculate
    if @gameover
      #돈 나눠주기
      total_money = 0
      @bet_money_history.each { |x| total_money += x.to_i }
      @bet_money_history.clear
      if @players[0].died
        @players[1].money += total_money
        set_sun(1)
      elsif @players[1].died
        @players[0].money += total_money
        set_sun(0)
      elsif @players[0].card_number > @players[1].card_number
        @players[0].money += total_money
        set_sun(0)
      elsif @players[0].card_number < @players[1].card_number
        @players[1].money += total_money
        set_sun(1)
      else
        @players[0].money += total_money / 2
        @players[1].money += total_money / 2
        set_sun(-1)
      end

      #다시 시작
      @gameover = false
      if @future_deck.size < 2
        shuffle_cards
      else
        @past_deck << @current_deck
        @past_deck.flatten!
        @current_deck = @future_deck.pop(2)
        if @sun_player == @players[0] 
          @players[0].card_number = @current_deck[0]
          @players[1].card_number = @current_deck[1]
        else
          @players[0].card_number = @current_deck[1]
          @players[1].card_number = @current_deck[0]
        end
        [0, 1].each do |x|
          @players[x].hide = true
          @players[x].died = false
        end
      end
    elsif @betover
      @gameover = true
      @betover = false
      [0, 1].each {|x| @players[x].hide = false }
    else
      if @play_turn.ai_flag 
        bet_money, message = 
            @servers[@play_turn.number].call(
                    "indian.calculate", 
                    [@play_next.card_number] + [@past_deck] + [@play_turn.money] + [@bet_money_history]
                  )
        #Log
        puts "\n[BEGIN] MESSAGE FROM AI"
        puts message
        puts "[END] MESSAGE FROM AI\n"
      else
        bet_money = @current_bet_money
      end
      
      # Update Game Status
      if bet_money.to_i < 0 #DIE
        @play_turn.died = true
        @betover = true
        pass_turn
      elsif get_your_total_bet > (get_my_total_bet + bet_money.to_i) 
        #이런일이 발생하면 안된다. # 배팅액은 맞춰야 한다
        @bet_violation_cnt += 1
      else
        if get_your_total_bet == (get_my_total_bet + bet_money.to_i)
          @betover = true
        end
        @bet_money_history << bet_money.to_i
        @play_turn.money -= bet_money.to_i if bet_money.to_i > 0
        pass_turn
      end
    end
  end

  def hide_toggle(id)
    @players[id].hide_toggle
  end

  def button_down(id) 
    case id 
    when Gosu::KbR 
      restart
    when Gosu::KbP 
      pass_turn
    when Gosu::KbN 
      calculate
    when Gosu::KbQ
      hide_toggle(0)
    when Gosu::KbW
      hide_toggle(1)
    when Gosu::KB_UP
      @current_bet_money += BET_UNIT
    when Gosu::KB_DOWN
      @current_bet_money -= BET_UNIT
    when Gosu::KbC
      if @bet_money_history.empty?
        @current_bet_money = 0
      else 
        @current_bet_money = get_your_total_bet - get_my_total_bet
      end
    when Gosu::KbD
      @current_bet_money = 0 - BET_UNIT
    end 
  end

  def update
    if Gosu.button_down? Gosu::KB_UP
      @current_bet_money += BET_UNIT if Time.now - @current_time_for_longbutton > 0.5
    elsif Gosu.button_down? Gosu::KB_DOWN
      @current_bet_money -= BET_UNIT if Time.now - @current_time_for_longbutton > 0.5 
    else
      @current_time_for_longbutton = Time.now
    end
  end

  private
  def get_your_total_bet
    total = 0
    1.upto(@bet_money_history.size) do |index|
      total += @bet_money_history[0 - index] if index.odd?
    end
    return total
  end

  def get_my_total_bet
    total = 0
    1.upto(@bet_money_history.size) do |index|
      total += @bet_money_history[0 - index] unless index.odd?
    end
    return total
  end
end

class Board
  include Singleton
  def initialize
    @image = Gosu::Image.new("media/board_logo.jpg")
  end

  def draw
    image_resize_ratio = HEIGHT / @image.height.to_f
    @image.draw(0, 0, ZOrder::Board, image_resize_ratio, image_resize_ratio)
  end 
end

class Player 
  attr_reader :stones, :color
  attr_accessor :player_name, :ai_flag, :number, :money, :hide, :card_number, :died
  def initialize(number)
    @died = false
    @hide = true
    @money = INITIAL_MONEY
    @number = number
    @stones = Array.new
    @player_name = "사람_#{Array.new(6){rand(10)}.join}"
    @ai_flag = false

    #initialize images

    @images = Array.new
    (1..10).to_a.each do |x|
      @images[x] = Gosu::Image.new("media/#{x}_of_spades.png")
    end
  end
  
  def draw
    unless @hide
      left_position = [80, 380] 
      @images[@card_number].draw(left_position[@number], 160, ZOrder::Card, 0.5, 0.5)
    end
  end

  def hide_toggle
    @hide = !@hide
  end

end

@window = IndianPoker.new
@window.show
