class QuizCollectionsController < ApplicationController
  def index
    @quiz_collections = QuizCollection.all
  end

  def show
    @quiz_collection = QuizCollection.find(params[:id])
    @books = @quiz_collection.books
    @book = Book.new
    @user = @quiz_collection.user
  end


  def create
    @quiz_collection = QuizCollection.new(quiz_collection_params)
    @quiz_collection.user_id = current_user.id
    if @quiz_collection.save
      redirect_to quiz_collection_path(@quiz_collection.id)
    else
      @quiz_collections = QuizCollection.all
      render :index
    end
  end
  
  def destroy
    @quiz_collection = QuizCollection.find(params[:id])
    if @quiz_collection.destroy
      flash[:notice] = "クイズコレクションを削除しました。"
      redirect_to quiz_collections_path
    else
      flash[:alert] = "クイズコレクションの削除に失敗しました。"
      redirect_to quiz_collection_path(@quiz_collection)
    end
  end

  private

  def quiz_collection_params
    params.require(:quiz_collection).permit(:title)
  end
end
