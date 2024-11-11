class BookCommentsController < ApplicationController

  def create
    book = Book.find(params[:book_id])
    comment = current_user.book_comments.new(book_comment_params)
    comment.book_id = book.id
    quiz_collection = book.quiz_collection
    if comment.save
      redirect_to quiz_collection_path(quiz_collection)
    else
      Rails.logger.info(comment.errors.full_messages) # エラー内容をログに出力
      redirect_to book_path(book), alert: "Failed to save answer."
    end
  end

  def destroy
    BookComment.find(params[:id]).destroy
    redirect_to book_path(params[:book_id])
  end

  private

  def book_comment_params
    params.require(:book_comment).permit(:comment, :answer_time)
  end

end
