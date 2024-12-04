class BooksController < ApplicationController
  # before_action :correct_user, only: [:edit, :update]


  # def index
  #   @user = current_user
  #   @books = Book.all
  #   @book = Book.new
  # end

  def create
    @book = Book.new(book_params)
    @book.user_id = current_user.id
    
    unless current_user.quiz_collections.exists?(id: @book.quiz_collection_id)
      flash[:alert] = "無効なクイズコレクションです。"
      redirect_to request.referer || root_path and return
    end
    if @book.save
      flash[:notice] = "You have created book successfully."
      # redirect_to book_path(@book.id)
      redirect_to quiz_collection_path(@book.quiz_collection_id)
    else
      @user = current_user
      @quiz_collection = QuizCollection.new 
      @quiz_collections = @user.quiz_collections
      redirect_to user_path(@user)
    end
  end

  def show
    @book = Book.new
    @book_detail = Book.find(params[:id])
    @user = @book_detail.user
    @book_comment = BookComment.new
  end

  def edit
    @now_user = current_user
    @book = Book.find(params[:id])
    if @now_user != @book.user
      @user = current_user
      @quiz_collection = QuizCollection.new 
      @quiz_collections = @user.quiz_collections
      redirect_to user_path(@user)
    end
  end

  def update
    @book = Book.find(params[:id])
    if @book.update(book_params)
      flash[:notice] = "You have updated book successfully."
      redirect_to quiz_collection_path(@book.quiz_collection)
    else
      @book = @book
      render :edit
    end
  end


  def destroy
    @book = Book.find(params[:id])
    @book.destroy
    @user = current_user
    @quiz_collection = @book.quiz_collection
    redirect_to quiz_collection_path(@quiz_collection)
  end


  private
  # ストロングパラメータ
  def book_params
    params.require(:book).permit(:title, :body, :image, :quiz_collection_id, :choices_count, :correct_answer)
  end

  # def correct_user
  #   @book = Book.find(params[:id])
  #   @user = @book.user
  #   redirect_to(books_path) unless @user == current_user
  # end

end
