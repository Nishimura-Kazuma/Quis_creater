class BookCommentsController < ApplicationController

  def create
    book = Book.find(params[:book_id])
    comment = current_user.book_comments.new(book_comment_params)
    comment.book_id = book.id
    quiz_collection = book.quiz_collection
   
    if comment.save
      next_book = book.next_book
      if next_book.present?
        # 次の問題が存在する場合、その詳細ページにリダイレクト
        redirect_to book_path(next_book), notice: "回答を送信しました。次の問題に進みます。"
      else
        # 次の問題が存在しない場合、クイズコレクションのトップページにリダイレクト
        redirect_to quiz_collection_path(book.quiz_collection), notice: "クイズが終了しました。お疲れ様でした！"
      end
      # redirect_to quiz_collection_path(quiz_collection)
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
