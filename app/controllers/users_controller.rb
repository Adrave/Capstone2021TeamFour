class UsersController < ApplicationController

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    # Generate a code that's unique when combined with username
    friend_code = rand(1000...9999)
    while User.where(username: @user.username, code: friend_code).count > 0
      friend_code = rand(1000.9999)
    end
    @user.code = friend_code

    if @user.save
      reset_session
      log_in @user
      flash[:success] = "Caught you on the flippity flip"
      render 'profile'
    else
      render 'new'
    end

  end

  def search
    @user = current_user
    temp_revs = []
    @user.friends.each do |friend|
      temp_revs += friend.reviews
    end
    tags = tags_from_string(params[:search_terms])
    temp_revs = filter_reviews(temp_revs, tags)
    @reviews = temp_revs.sort_by{ |r| r.post_date }.reverse
  end

  def show
    @user = current_user
    temp_revs = []
    @user.friends.each do |friend|
      temp_revs += friend.reviews
    end
    @reviews = temp_revs.sort_by{ |r| r.post_date }.reverse
  end

  def profile
    @reviews = current_user.reviews
    @tag = Tag.new
  end

  def avatar
    @user = current_user
    @user.avatar.attach(params[:avatar][:avatar])
    respond_to do |format|
      format.js
    end
  end

  def friend_profile
    @user = User.all.find_by(id: params[:user_id])
    @reviews = Review.all
  end
  

  private

    def user_params
      params.require(:user).permit(:email, :username, :password,
                                               :password_confirmation)
    end

    def tags_from_string(input_string)
      tags = {}
      input_string.split(" ").each do |pair| 
        pair = pair.gsub("-", " ")
        category, name = pair.split(":")
        tags[category] = name
      end
      tags
    end

    def filter_reviews(reviews, tags)
      result = []
      reviews.each do |review|
        keep = true
        review_tags = review.tags
        tags.each do |category, name|
          if category == "title"
            if name.downcase != review.media.downcase
              keep = false
            end
          else
            if review_tags.find_by(category: category.capitalize,
                                   name: name.capitalize).nil?
              keep = false
            end
          end
        end
        if keep
          result.append(review)
        end
      end
      result
    end

    def selector_html
      "<form enctype=\"multipart/form-data\" action=\"/upload_avatar\" accept-charset=\"UTF-8\" method=\"post\">
         <input id=\"avatar\" type=\"file\" name=\"avatar\">
         <input class=\"btn btn-primary\" type=\"submit\" name=\"commit\" value=\"Change avatar\" data-disable-with=\"Change avatar\">
       </form>"
    end

    def image_html(user)
    end
end
