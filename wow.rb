def get_probablity(opposite_play_card,past_cards=[])
  higher_card  = (10 - opposite_play_card)*2
  remain_card = 19
  past_cards.each do |paca|
    remain_card-=1
    if paca > opposite_play_card
      higher_card-=1
    end
  end
  higher_card.fdiv(remain_card)
end
def get_rand
  a=rand(2)
  return result = a==1? 1 : -1
end
puts get_probablity(1)
puts get_rand
