class AnagramsController < ApplicationController
  before_action :authenticate_user!, :except => [:trial]

  def trial
    ana = SocialAnagrams::ANA
    original = params[:trial][:text]
    phrase = ana.clean(original)
    trial_max = SocialAnagrams::Application.config.trial_max
    max_results = SocialAnagrams::Application.config.trial_max
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
        if @anagrams.length > max_results
          @anagrams = (@anagrams.shuffle)[0...max_results]
          @anagrams.sort! do |a, b|
            ordered = a.length < b.length ? 1 : -1
            d, e = a, b
            d, e = b, a if ordered == -1
            s = -ordered
            (0...d.length).each do |i|
              c = d[i] <=> e[i]
              if c != 0
                s = ordered * c
                break
              end
            end
            s
          end
        end
      end
    end
  end

  def full
    ana = SocialAnagrams::ANA
    puts params.inspect
    original = params[:full][:text]
    phrase = ana.clean(original)
    max = SocialAnagrams::Application.config.max
    max_results = SocialAnagrams::Application.config.max_results
    threshold = SocialAnagrams::Application.config.threshold
    if phrase.length > max
      render json: {error: "#{original} exceeds the maximum character count of #{max}"}
    else
      batch_size = SocialAnagrams::Application.config.batch
      max_length = SocialAnagrams::Application.config.max
      anagrams = []
      rv = {anagrams: anagrams}
      if phrase.length > threshold
        warning = "This phrase has #{phrase.length} characters, which exceeds the #{threshold} threshold.\n"
        warning += "Above this threshold one does not get all anagrams of the phrase but a random sample of at most #{batch_size}."
        rv[:warning] = warning
        i = ana.iterator phrase, :random => true
        while (anagrams.length < batch_size) && (n = i.())
          anagrams << n
        end
        rv[:more] = phrase
      else
        rv[:anagrams] = anagrams = ana.anagrams phrase
        if anagrams.length > max_results
          warning = "#{anagrams.length} anagrams were found. A random sample of #{max_results} has been returned."
          rv[:warning] = warning
          rv[:anagrams] = anagrams = (anagrams.shuffle)[0...max_results]
          anagrams.sort! do |a, b|
            ordered = a.length < b.length ? 1 : -1
            d, e = a, b
            d, e = b, a if ordered == -1
            s = -ordered
            (0...d.length).each do |i|
              c = d[i] <=> e[i]
              if c != 0
                s = ordered * c
                break
              end
            end
            s
          end
        end
      end
      render json: rv
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
      anagram.notify current_user, recipient.other
      shares += 1
    end
    return render json: {error: 'No suitable recipients.'} if shares == 0
    anagram.update shared: anagram.shared + shares
    render json: {message: 'Shared anagram.'}
  end

end
