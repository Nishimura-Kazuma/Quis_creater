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
  
  # def export
  #   @quiz_collection = QuizCollection.find(params[:id])
  #   @books = @quiz_collection.books.includes(:book_comments)
  
  #   # 整形データの作成
  #   @output_data = @books.map do |book|
  #     {
  #       quiz_name: book.title,
  #       comments: book.book_comments.map do |comment|
  #         {
  #           user_name: comment.user.name,
  #           answer: comment.comment,
  #           correct: comment.correct? ? "0" : "1",
  #           answer_time: comment.answer_time
  #         }
  #       end
  #     }
  #   end
  
  #   respond_to do |format|
  #     format.xlsx { render xlsx: "export", filename: "quiz_collection_#{@quiz_collection.title}_#{Time.now.strftime('%Y%m%d%H%M')}.xlsx" }
  #   end
  # end
  
  
  # def export
  #   @quiz_collection = QuizCollection.find(params[:id])
  #   @books = @quiz_collection.books.includes(book_comments: :user)
  
  #   # Axlsx パッケージ作成
  #   package = Axlsx::Package.new
  #   workbook = package.workbook
  
  #   # 被験者ごとにシートを作成
  #   users = @books.flat_map { |book| book.book_comments.map(&:user) }.uniq
  
  #   users.each do |user|
  #     workbook.add_worksheet(name: user.name) do |sheet|
  #       # ヘッダー行を追加
  #       sheet.add_row ["問題名", "回答", "正誤", "回答時間"]
  
  #       # 被験者のデータをフィルタリングしてシートに追加
  #       @books.each do |book|
  #         book.book_comments.where(user: user).each do |comment|
  #           # 正誤判定
  #           correct = comment.comment.to_s.strip == book.correct_answer.to_s.strip ? 1 : 0
  #           sheet.add_row [book.title, comment.comment, correct, comment.answer_time]
  #         end
  #       end
  #     end
  #   end
  
  #   # ファイルを送信
  #   send_data package.to_stream.read,
  #             filename: "quiz_collection_#{@quiz_collection.title}_#{Time.now.strftime('%Y%m%d%H%M')}.xlsx",
  #             type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  # end
  
def export
  @quiz_collection = QuizCollection.find(params[:id])
  @books = @quiz_collection.books.includes(book_comments: :user)

  # Axlsx パッケージ作成
  package = Axlsx::Package.new
  workbook = package.workbook

  # 被験者ごとにシートを作成
  users = @books.flat_map { |book| book.book_comments.map(&:user) }.uniq

  users.each do |user|
    # 各被験者のコメントを問題ごとに分類
    user_book_comments = @books.each_with_object({}) do |book, hash|
      hash[book] = book.book_comments.where(user: user).order(:created_at)
    end

    # 各カテゴリ（プレテスト、ポストテスト、遅延テスト）に対応するシートを作成
    %w[プレテスト ポストテスト 遅延テスト].each_with_index do |test_type, index|
      workbook.add_worksheet(name: "#{user.name}_#{test_type}") do |sheet|
        # ヘッダー行を追加
        sheet.add_row ["問題名", "回答", "正誤", "回答時間"]

        correct_count = 0
        total_time = 0.0
        response_count = 0

        # 各問題ごとのデータを追加
        user_book_comments.each do |book, comments|
          if comments[index] # 回答が存在する場合のみ追加
            comment = comments[index]
            correct = comment.comment.to_s.strip == book.correct_answer.to_s.strip ? 1 : 0
            sheet.add_row [book.title, comment.comment, correct, comment.answer_time]

            # 正答数と回答時間の統計を計算
            correct_count += correct
            total_time += comment.answer_time.to_f
            response_count += 1
          end
        end

        # 正答率と平均回答時間を計算
        accuracy_rate = response_count > 0 ? (correct_count.to_f / response_count * 100).round(2) : 0
        average_time = response_count > 0 ? (total_time / response_count).round(2) : 0

        # 集計データをシートの下部に追加
        sheet.add_row []
        sheet.add_row ["正答数", correct_count]
        sheet.add_row ["正答率(%)", accuracy_rate]
        sheet.add_row ["平均回答時間", average_time]
      end
    end

    # 4回目以降の回答を確認し、存在する場合のみ「その他」シートを作成
    extra_comments_exist = user_book_comments.any? do |_, comments|
      comments.size > 3
    end

    if extra_comments_exist
      workbook.add_worksheet(name: "#{user.name}_その他") do |sheet|
        # ヘッダー行を追加
        sheet.add_row ["問題名", "回答", "正誤", "回答時間"]

        correct_count = 0
        total_time = 0.0
        response_count = 0

        user_book_comments.each do |book, comments|
          # 4回目以降の回答を取得
          comments[3..].each do |comment|
            correct = comment.comment.to_s.strip == book.correct_answer.to_s.strip ? 1 : 0
            sheet.add_row [book.title, comment.comment, correct, comment.answer_time]

            # 正答数と回答時間の統計を計算
            correct_count += correct
            total_time += comment.answer_time.to_f
            response_count += 1
          end if comments.size > 3
        end

        # 正答率と平均回答時間を計算
        accuracy_rate = response_count > 0 ? (correct_count.to_f / response_count * 100).round(2) : 0
        average_time = response_count > 0 ? (total_time / response_count).round(2) : 0

        # 集計データをシートの下部に追加
        sheet.add_row []
        sheet.add_row ["正答数", correct_count]
        sheet.add_row ["正答率(%)", accuracy_rate]
        sheet.add_row ["平均回答時間", average_time]
      end
    end
  end

  # ファイルを送信
  send_data package.to_stream.read,
            filename: "quiz_collection_#{@quiz_collection.title}_#{Time.now.strftime('%Y%m%d%H%M')}.xlsx",
            type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
end








  private

  def quiz_collection_params
    params.require(:quiz_collection).permit(:title)
  end
end
