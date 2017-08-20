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

    if this_bet == 0
      this_bet = MIN_DEFAULT_BET
    end
    # Write your own codes here
    # turn
    turn = past_cards.length/2+1
    # 판돈
    total_bet = your_total_bet + my_total_bet
    # 단순히 이길 확률
    percent = get_probablity(opposite_play_card,past_cards)
    # 내가 무조건 이기는 남은 나의 돈
    victory_money = get_win_my_money(past_cards)
    # 내가 이길려면 얻어야 할 돈
    win_money = victory_money - my_money
    # 내가 이길려면 걸어야 할 돈
    # deal_money = win_money - total_bet >= bet_history[-1]? win_money - total_bet : bet_history[-1]
    deal_money = win_money - total_bet
    # call
    call = bet_history[-1]

    if my_money >= victory_money
      this_bet = -1
    elsif turn == 10
      this_bet = deal_money >= call ? deal_money : call
    elsif turn >= 7
      if percent > 0.9
        this_bet = deal_money >= call ? deal_money : call
      elsif total_bet > my_money
        this_bet = -1
      elsif percent > 0.7
        if bet_history.length>5
          this_bet = call
        end
        this_bet = deal_money/2 >= call ? deal_money/2 : -1
      elsif percent > 0.4
        this_bet = deal_money/2 >= call ? deal_money/2 : -1
      else
        this_bet = -1
      end
    elsif turn >= 5
      if percent > 0.9
        this_bet = deal_money >= call ? deal_money : call
      elsif total_bet > my_money
        this_bet = -1
      elsif percent > 0.7
        if bet_history.length>5
          this_bet = call
        end
        this_bet = deal_money/2 >= call ? deal_money/2 : -1
      elsif percent > 0.4
        this_bet = deal_money/3 >= call ? deal_money/3 : -1
      else
        this_bet = -1
      end
    else
      if percent > 0.9
        this_bet = deal_money >= call ? deal_money : call
      elsif total_bet > my_money
        this_bet = -1
      elsif percent > 0.7
        this_bet = deal_money/3 >= call ? deal_money/3 : -1
        if bet_history.length>3
          this_bet = call
        end
      elsif percent > 0.4
        this_bet = deal_money/4 >= call ? deal_money/4 : -1
      else
        this_bet = -1
      end
    end
    return this_bet
  end
  def get_name
    "red_screen"
  end

  private
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
    higher_card  = (10 - opposite_play_card)*2
    remain_card = 19
    past_cards.each do |paca|
      remain_card-=1
      if paca > opposite_play_card
        higher_card-=1
      end
    end
    return higher_card.fdiv(remain_card)
  end
  def get_win_my_money(past_cards)
    turn= past_cards.length/2+1
    return 41-turn
  end
end

s.add_handler("indian", MyAi.new)
s.serve
