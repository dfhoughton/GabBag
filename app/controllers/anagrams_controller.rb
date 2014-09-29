class AnagramsController < ApplicationController
  before_action :authenticate_user!, :except => [:trial]

  def trial
    ana = SocialAnagrams::ANA
    original = params[:trial][:text]
    phrase = ana.clean(original)
    trial_max = SocialAnagrams::Application.config.trial_max
    if phrase.length > trial_max
      @error = "#{original} exceeds the maximum character count of #{trial_max} for free trial use"
    else
      batch_size = SocialAnagrams::Application.config.trial_batch
      max_length = SocialAnagrams::Application.config.trial_threshold
      @anagrams = []
      if phrase.length > max_length
        i = ana.iterator phrase, :random => true
        while (@anagrams.length < batch_size) && (n = i.())
          @anagrams << n
        end
      else
        @anagrams = ana.anagrams phrase
      end
    end
  end

  def full
    ana = SocialAnagrams::ANA
    original = params[:full][:text]
    phrase = ana.clean(original)
    max = SocialAnagrams::Application.config.max
    if phrase.length > max
      render json: {error: "#{original} exceeds the maximum character count of #{max}"}
    else
      batch_size = SocialAnagrams::Application.config.batch
      max_length = SocialAnagrams::Application.config.max
      @anagrams = []
      if phrase.length > max_length
        i = ana.iterator phrase, :random => true
        while (@anagrams.length < batch_size) && (n = i.())
          @anagrams << n
        end
      else
        @anagrams = ana.anagrams phrase
      end
      render json: {anagrams: @anagrams}
    end
  end

  # really find or create
  # responds to a JSON request to create or find an anagram, returning the anagram as a JSON object
  def share
    anagram = params[:id] ? Anagram.find(params[:id]) : Anagram.fetch(params[:source], params[:anagram])
    return render json: {error: 'Unsuitable anagram.'} if anagram.nil?
    recipients = params[:recipients]
    return render json: {error: 'Ill-formed request.'} if recipients.nil? || !recipients.is_a?(Array)
    return render json: {error: 'No recipients.'} if recipients.length == 0
    recipients = current_user.friends.where(id: recipients)
    shares = 0
    recipients.each do |recipient|
      return render json: {error: 'Unsuitable recipient.'} unless recipient.mutual
      message = {
          type: :share,
          from: current_user.email,
          anagram: {
              id: anagram.id,
              source: anagram.phrase.text,
              anagram: anagram.child.text,
              favored: anagram.favored
          }
      }
      Notification.create user: recipient.other, body: message.to_json
      shares += 1
    end
    return render json: {error: 'No suitable recipients.'} if shares == 0
    anagram.update shared: anagram.shared + shares
    render json: {message: 'Shared anagram.'}
  end

end
