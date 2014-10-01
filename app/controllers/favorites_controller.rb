class FavoritesController < ApplicationController
  def index
    favorites = []
    current_user.favorites.includes(:anagram, :phrase, :child).each do |f|
      a = f.anagram
      favorites << { id: f.id, source: a.phrase.text, anagram: a.child.text }
    end
    render json: { favorites: favorites }
  end

  def create
    source, child = params[:source], params[:anagram]
    anagram = Anagram.fetch source, child
    return render json: { error: "Unable to save anagram #{source} => #{child}"} if anagram.nil?
    existing = current_user.favorites.where(anagram: anagram).take
    return render json: { message: "Nothing to do." } unless existing.nil?
    f = current_user.favorites.create anagram: anagram
    anagram.notify_all current_user, current_user.subscribers
    anagram = {
        id: f.id,
        source: anagram.phrase.text,
        anagram: anagram.child.text
    }
    return render json: anagram
  end

  def destroy
    source, child = params[:source], params[:anagram]
    anagram = Anagram.fetch source, child
    return render json: { error: "Unable to delete favorite #{source} => #{child}"} if anagram.nil?
    fav = current_user.favorites.where(anagram: anagram).take
    return render json: { error: "This is not one of your favorites." } if fav.nil?
    anagram.update favored: anagram.favored - 1
    return render json: { error: "Unable to delete favorite #{source} => #{child}" } unless fav.destroy
    render json: { message: "Deleted favorite #{source} => #{child}." }
  end

end
