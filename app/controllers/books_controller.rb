class BooksController < ApplicationController
  # before_action :correct_user, only: [:edit, :update]


  def index
    @user = current_user
    @books = Book.all
    @book = Book.new
  end

  def create
    @book = Book.new(book_params)
    @book.user_id = current_user.id
    if @book.save
      flash[:notice] = "You have created book successfully."
      redirect_to book_path(@book.id)
    else
      @user = current_user
      @books = Book.all
      @book = @book
      render :index
    end
  end

  def show
    @book = Book.new
    @book_detail = Book.find(params[:id])
    @user = @book_detail.user
  end

  def edit
    @now_user = current_user
    @book = Book.find(params[:id])
    if @now_user != @book.user
      redirect_to books_path
    end
  end

  def update
    @book = Book.find(params[:id])
    if @book.update(book_params)
      flash[:notice] = "You have updated book successfully."
      redirect_to book_path(id: @book.id)
    else
      @book = @book
      render :edit
    end
  end


  def destroy
    @book = Book.find(params[:id])
    @book.destroy
    redirect_to books_path
  end


  private
  # ストロングパラメータ
  def book_params
    params.require(:book).permit(:title, :body)
  end

  # def correct_user
  #   @book = Book.find(params[:id])
  #   @user = @book.user
  #   redirect_to(books_path) unless @user == current_user
  # end

end
