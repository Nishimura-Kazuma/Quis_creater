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





def export_user_based
  @quiz_collections = QuizCollection.includes(books: { book_comments: :user })

  # Axlsx パッケージ作成
  package = Axlsx::Package.new
  workbook = package.workbook

  # :include_in_export フラグがオンの問題に対するコメントをカウント
  users_with_comments = User.all.select do |user|
    @quiz_collections.any? do |collection|
      collection.books.where(include_in_export: true).any? do |book|
        book.book_comments.exists?(user: user)
      end
    end
  end

  # コメントがあるユーザーのみシートを作成
  users_with_comments.each do |user|
    workbook.add_worksheet(name: user.name) do |sheet|
      test_types = %w[プレテスト ポストテスト 遅延テスト その他]

      # ヘッダー行を作成
      header = ["問題名"]
      test_types.each do |test_type|
        header += ["#{test_type} 回答", "#{test_type} 正誤", "#{test_type} 回答時間"]
      end
      sheet.add_row header

      # 問題ごとに回答を分類して出力
      all_test_data = {}
      test_types.each { |test_type| all_test_data[test_type.to_sym] = [] } # 初期化

      @quiz_collections.each do |collection|
        collection.books.where(include_in_export: true).each do |book|
          row = [book.title]
          test_data = { プレテスト: nil, ポストテスト: nil, 遅延テスト: nil, その他: [] }

          # コメントを分類
          book.book_comments.where(user: user).order(:created_at).each_with_index do |comment, index|
            case index
            when 0 then test_data[:プレテスト] = comment
            when 1 then test_data[:ポストテスト] = comment
            when 2 then test_data[:遅延テスト] = comment
            else        test_data[:その他] << comment
            end
          end

          test_types.each do |test_type|
            if test_type == "その他"
              if test_data[:その他].is_a?(Array) && test_data[:その他].any?
                test_data[:その他].each do |comment|
                  correct = comment.comment.to_s.strip == book.correct_answer.to_s.strip ? 1 : 0
                  row += [comment.comment, correct, comment.answer_time]
                  all_test_data[:その他] << { comment: comment, correct: correct }
                end
              else
                row += [nil, nil, nil]
              end
            elsif test_data[test_type.to_sym].is_a?(BookComment)
              comment = test_data[test_type.to_sym]
              correct = comment.comment.to_s.strip == book.correct_answer.to_s.strip ? 1 : 0
              row += [comment.comment, correct, comment.answer_time]
              all_test_data[test_type.to_sym] << { comment: comment, correct: correct }
            else
              row += [nil, nil, nil]
            end
          end

          sheet.add_row row
        end
      end

      # 各テストタイプごとの集計を計算して追加
      sheet.add_row []
      sheet.add_row ["テストタイプ別集計"]

      test_types.each do |test_type|
        data = all_test_data[test_type.to_sym]
        if data.any?
          correct_count = data.count { |entry| entry[:correct] == 1 }
          response_count = data.size
          total_time = data.sum { |entry| entry[:comment].answer_time.to_f }

          accuracy_rate = response_count > 0 ? (correct_count.to_f / response_count * 100).round(2) : 0
          average_time = response_count > 0 ? (total_time / response_count).round(2) : 0

          sheet.add_row [
            test_type,
            "正答数: #{correct_count}",
            "正答率(%): #{accuracy_rate}",
            "平均回答時間: #{average_time}"
          ]
        else
          sheet.add_row [test_type, "データなし"]
        end
      end
    end
  end

  # ファイルを送信
  send_data package.to_stream.read,
            filename: "quiz_collections_user_based_#{Time.now.strftime('%Y%m%d%H%M')}.xlsx",
            type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
end









def export_user_based_with_labels
  @quiz_collections = QuizCollection.includes(books: { book_comments: :user })

  # Axlsx パッケージ作成
  package = Axlsx::Package.new
  workbook = package.workbook

  # 被験者ごとにシートを作成 (一問も回答していない被験者を除外)
  users = @quiz_collections.flat_map { |collection| collection.books.flat_map { |book| book.book_comments.map(&:user) } }
                           .tally
                           .select { |user, count| count > 0 } # 回答が1つ以上あるユーザーを選択
                           .keys

  users.each do |user|
    # 各被験者のデータをテストタイプとラベルごとに分ける
    user_data = { プレテスト: {}, ポストテスト: {}, 遅延テスト: {}, その他: {} }

    @quiz_collections.each do |collection|
      collection.books.where(include_in_export: true).each do |book| # チュートリアルを除外
        book.book_comments.where(user: user).order(:created_at).each_with_index do |comment, index|
          test_type =
            case index
            when 0 then :プレテスト
            when 1 then :ポストテスト
            when 2 then :遅延テスト
            else        :その他
            end

          # ラベルごとにデータを分類
          label = book.label.presence || "未分類"
          user_data[test_type][label] ||= [] # ラベルごとの配列を初期化
          user_data[test_type][label] << { book: book, comment: comment }
        end
      end
    end

    # 各テストタイプとラベルごとにシートを作成
    user_data.each do |test_type, labels|
      labels.each do |label, data|
        next if data.empty? # データがない場合はシート作成をスキップ

        workbook.add_worksheet(name: "#{user.name}_#{test_type}_#{label}") do |sheet|
          # ヘッダー行
          sheet.add_row ["問題名", "回答", "正誤", "回答時間"]

          # データ行
          data.each do |entry|
            book = entry[:book]
            comment = entry[:comment]
            correct = comment.comment.to_s.strip == book.correct_answer.to_s.strip ? 1 : 0
            sheet.add_row [book.title, comment.comment, correct, comment.answer_time]
          end

          # 集計データをシート下部に追加
          if data.any?
            correct_count = data.count { |entry| entry[:comment].comment.to_s.strip == entry[:book].correct_answer.to_s.strip }
            response_count = data.size
            total_time = data.sum { |entry| entry[:comment].answer_time.to_f }

            accuracy_rate = response_count > 0 ? (correct_count.to_f / response_count * 100).round(2) : 0
            average_time = response_count > 0 ? (total_time / response_count).round(2) : 0

            sheet.add_row []
            sheet.add_row ["正答数", correct_count]
            sheet.add_row ["正答率(%)", accuracy_rate]
            sheet.add_row ["平均回答時間", average_time]
          end
        end
      end
    end
  end

  # ファイルを送信
  send_data package.to_stream.read,
            filename: "quiz_collections_user_based_with_labels_#{Time.now.strftime('%Y%m%d%H%M')}.xlsx",
            type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
end



  private

  def quiz_collection_params
    params.require(:quiz_collection).permit(:title)
  end
end
