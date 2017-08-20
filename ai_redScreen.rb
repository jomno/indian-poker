require "xmlrpc/server"
require "socket"

s = XMLRPC::Server.new(ARGV[0])
MIN_DEFAULT_BET = 1

class MyAi
  def calculate(info)
    opposite_play_card = info[0] # 상대방이 들고 있는 카드의 숫자
    past_cards = info[1]         # 지금까지 지나간 카드들 (배열)
    my_money = info[2]           # 내가 가지고 있는 칩
    bet_history = info[3]        # 이때까지 나와 상대방이 판에 깔았던 칩들 (배열)

    your_total_bet, my_total_bet = get_total_bet_money_per_person bet_history
    this_bet = your_total_bet - my_total_bet

    im=(past_cards.length/2)+1
    if my_money==29&&im==1
      delete_count
    elsif my_money==30&&im==2
      delete_count
    end
    if this_bet == 0
      this_bet = MIN_DEFAULT_BET
    end
    #get_rand ㄱㄱ
    get_rand= rand(2)==1? 1: -1
    # Write your own codes here
    # 회차
    get_data =get_win_my_money(my_money,past_cards)
    count= get_data[0]
    # 라운드
    round = get_data[1]
    # 한 라운드에서의 turn
    turn = bet_history.length
    # 판돈
    total_bet = your_total_bet + my_total_bet
    # 단순히 이길 확률
    percent = get_probablity(opposite_play_card,past_cards)
    # 내가 무조건 이기는 남은 나의 돈
    victory_money = get_data[2]
    # 내가 이길려면 얻어야 할 돈
    win_money = victory_money - my_money
    # 내가 이길려면 걸어야 할 돈
    # deal_money = win_money - total_bet >= bet_history[-1]? win_money - total_bet : bet_history[-1]
    deal_money = win_money - total_bet
    # call
    call = bet_history[-1]

    if my_money >= victory_money
      this_bet = -1
    elsif opposite_play_card == 1
      this_bet = deal_money >= call ? deal_money : call
    elsif count == 1
      if round == 10
        if percent>0.5
          if my_money==28
            no_delete_count round ,count
          end
          this_bet = deal_money >= call ? deal_money : call
        else
          if my_money==30
            no_delete_count round ,count
          end
          this_bet = -1
        end
      elsif round >= 7
        if percent > 0.86
          this_bet = deal_money >= call ? deal_money : call
        elsif call >= my_money
          this_bet = -1
        elsif percent > 0.8
          this_bet = deal_money/2 >= call ? deal_money/2 : call
        elsif percent > 0.7
          if call <= deal_money
            this_bet = deal_money/2 >= call ? deal_money/2 : call
          elsif your_total_bet <= deal_money
            this_bet = call
          else
            this_bet = -1
          end
        elsif percent > 0.4
          if bet_history.length>=2
            this_bet = -1
          else
            this_bet = deal_money/2 >= call ? deal_money/2 : -1
          end
        else
          this_bet = this_bet==0? get_rand : -1
        end
      elsif round >= 5
        if percent > 0.86
          this_bet = deal_money >= call ? deal_money : call
        elsif percent > 0.8
          this_bet = deal_money/2 >= call ? deal_money/2 : call
        elsif call > my_money
          this_bet = -1
        elsif percent > 0.7
          if call <= deal_money
            this_bet = deal_money/2 >= call ? deal_money/2 : call
          elsif your_total_bet <= deal_money
            this_bet = call
          else
            this_bet = -1
          end
        elsif percent > 0.4
          this_bet = deal_money/3 >= call ? deal_money/3 : -1
        else
          this_bet = this_bet==0? get_rand : -1
        end
      else
        if percent > 0.83
          this_bet = deal_money >= call ? deal_money : call
        elsif call >= my_money
          this_bet = -1
        elsif percent > 0.8
          this_bet = deal_money/2 >= call ? deal_money/2 : call
        elsif percent > 0.7
          if call <= deal_money
            this_bet = deal_money/3 >= call ? deal_money/3 : call
          elsif your_total_bet <= deal_money
            this_bet = call
          else
            this_bet = -1
          end
        elsif percent > 0.4
          this_bet = deal_money/4 >= call ? deal_money/4 : -1
        else
          this_bet = this_bet==0? get_rand : -1
        end
      end
    else
      if round >= 9
        this_bet = deal_money >= call ? deal_money : call
        if my_money==30&&this_bet==0
          this_bet = -1
        end
      elsif round >= 7
        if percent > 0.86
          this_bet = deal_money >= call ? deal_money : call
        elsif call >= my_money
          this_bet = -1
        elsif percent > 0.8
          this_bet = deal_money/2 >= call ? deal_money/2 : call
        elsif percent > 0.7
          if call <= deal_money
            this_bet = deal_money/2 >= call ? deal_money/2 : call
          elsif your_total_bet <= deal_money
            this_bet = call
          else
            this_bet = -1
          end
        elsif percent > 0.4
          this_bet = deal_money/2 >= call ? deal_money/2 : -1
        else
          this_bet = this_bet==0? get_rand : -1
        end
      elsif round >= 5
        if percent > 0.86
          this_bet = deal_money >= call ? deal_money : call
        elsif percent > 0.8
          this_bet = deal_money/2 >= call ? deal_money/2 : call
          this_bet = -1
        elsif percent > 0.7
          if call <= deal_money
            this_bet = deal_money/2 >= call ? deal_money/2 : call
          elsif your_total_bet <= deal_money*3/4
            this_bet = call
          else
            this_bet = -1
          end
        elsif percent > 0.4
          this_bet = deal_money/3 >= call ? deal_money/3 : -1
        else
          this_bet = this_bet==0? get_rand : -1
        end
      else
        if percent > 0.83
          this_bet = deal_money >= call ? deal_money : call
        elsif call >= my_money
          this_bet = -1
        elsif percent > 0.8
          this_bet = deal_money/2 >= call ? deal_money/2 : call
        elsif percent > 0.7
          if call <= deal_money
            this_bet = deal_money/3 >= call ? deal_money/3 : call
          elsif your_total_bet <= deal_money
            this_bet = call
          else
            this_bet = -1
          end
        elsif percent > 0.4
          this_bet = deal_money/4 >= call ? deal_money/4 : -1
        else
          this_bet = this_bet==0? get_rand : -1
        end
      end
    end
    return this_bet
  end

  def get_name
    "red_screen"
  end

  private
  def disk_count
    a=0
    File.open "y.csv" ,"a+" do |f|
      while line = f.gets
          last_line=line
      end
      a = last_line.to_s.split(',').last.to_i
    end

    if a==99
      return 1
    else
      return 0
    end
  end

  def no_delete_count round , count
    File.open "y.csv" ,"a+" do |f|
        f.print round,',',count,',',99
        f.puts ""
    end
  end

  def delete_count
    if disk_count==1
    else
      File.delete('y.csv')
    end
  end


  def get_total_bet_money_per_person bet_history
    bet_history_object = bet_history.clone #Clone Object
    total_bet_money = [0, 0]
    index = 0
    while (bet_history_object.size > 0) do
      money = bet_history_object.pop
      total_bet_money[0] += money if index.even?
      total_bet_money[1] += money if index.odd?
      index += 1
    end
    total_bet_money
  end
  # 확률 구하기 by_sungjun
  def get_probablity(opposite_play_card,past_cards=[])
    higher_card  = (10 - opposite_play_card)*2+1
    remain_card = 19
    past_cards.each do |paca|
      remain_card-=1
      if paca >= opposite_play_card
        higher_card-=1
      end
    end
    return higher_card.fdiv(remain_card)
  end

  # def get_rand
  #   a=rand(2)
  #   result = a==1? 1 : -1
  #   return result
  # end
  def get_count round
    a=0
    b=0
    File.open "y.csv","a+" do |f|
        while line = f.gets
            last_line=line
        end
        a = last_line.to_s.split(',').first.to_i
        b = last_line.to_s.split(',').last.to_i
    end
    File.open "y.csv" ,"a+" do |f|
      if a>round.to_i
        b+=1
      end
        f.print round,',',b
        f.puts ""
    end
    return b
  end
  # 회차, 회차의 round, 이길 머니
  def get_win_my_money(my_money,past_cards)
    round= past_cards.length/2+1
    count = get_count(round).even?? 1 : 2
    all_round = count*10+round-10
    return [count,round,51-all_round]
  end
end

s.add_handler("indian", MyAi.new)
s.serve
