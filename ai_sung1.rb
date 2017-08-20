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

    percent = cal_percent(opposite_play_card,past_cards)




    if percent<0.5     #확률이 50 프로 미만이면 무조건 죽음
        this_bet=-1
    elsif percent<0.7
      if this_bet > 5  #50~70프로인데 상대가 5 초과 배팅하면 죽음
        this_bet =-1
      elsif this_bet==0 #내가 먼저 배팅이면 3
        this_bet=3
      end              #5~70 프로인데 그냥 5이하로 배팅하면 콜함
    elsif percent<85
      if this_bet==0
        this_bet=5
      else
      end
    else
      this_bet+=10  #70프로 이상 확률은 10 추가배팅
    end


    # Write your own codes here
    #
    #
    # Return values
    return this_bet

  end


  def get_name
    "Seong Jun!!!"
  end

  private
  def cal_percent (opposite_play_card , past_cards=[0])

    higher_card  = (10 - opposite_play_card)*2

    remain_card = 19

    past_cards.each do |paca|

      remain_card-=1

      if paca > opposite_play_card

        higher_card-=1

      end

    end

    if higher_card==0
      return 0
    else
      return higher_card.fdiv(remain_card)
    end

  end



  def get_total_bet_money_per_person bet_history
    bet_history_object = bet_history.clone #Clone Object
    total_bet_money = [0, 0]
    index = 0
    while (bet_history_object.size > 0) do
      money = bet_history_object.pop #제일 마지막에 있는거 꺼내는거
      total_bet_money[0] += money if index.even? # 홀수면 상대 가 배팅한거에드감
      total_bet_money[1] += money if index.odd?#짝수면 내꺼
      index += 1
    end
    total_bet_money
  end

end

s.add_handler("indian", MyAi.new)
s.serve
