class UsersController < ApplicationController
  def index
    @user = current_user
    @book = Book.new
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
    @book = Book.new
    @books = @user.books
  end

  def edit
    @book = Book.find(params[:id])
  end
  
  def update
    @book = Book.find(params[:id])
    @user.update(user_params)
    redirect_to user_path(id: @user.id)
  end
  
  
  
  
  
end
