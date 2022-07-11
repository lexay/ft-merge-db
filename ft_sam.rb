require 'rubygems'
require 'bundler'
Bundler.setup(:default)
Bundler.require(:default)

module FreeTubeTools
  class SubscriptionMerger
    def self.run
      backup_dbs = ARGV
      imported_lists = backup_dbs.map { |db| List.new(deserialize(db)) }
      merged_list = merge(imported_lists, List.new)
      save(merged_list)
    end

    def self.deserialize(db)
      lines = File.open("./#{db}", 'r', &:readlines)
      lines.map do |line|
        hash = JSON.parse(line)
        hash.deep_transform_keys { |key| key.underscore.to_sym }
      end
    end

    def self.merge(imported_lists = [], merged_list)
      imported_lists.each do |i_list|
        i_list.categories.each do |i_cat|
          merged_cat_matched = merged_list.categories.find { |m_cat| m_cat.name == i_cat.name }

          if merged_cat_matched
            merged_cat_matched.subscriptions = merged_cat_matched.subscriptions | i_cat.subscriptions
          else
            new_cat = List::Category.new(name: i_cat.name,
                                         _id: i_cat.id,
                                         bg_color: i_cat.bg_color,
                                         text_color: i_cat.text_color,
                                         subscriptions: i_cat.subscriptions)
            merged_list.categories.push(new_cat)
          end
        end
      end
      merged_list
    end

    def self.save(list)
      date = Time.now.strftime('%Y-%m-%d_%H%M')
      new_backup_db = File.open("./ft_merged_#{date}.db", 'w')
      new_backup_db.write(list.to_s)
    end
  end

  class List
    attr_reader :categories

    def initialize(categories = [])
      @categories = categories.map { |c| Category.new(**c) }
    end

    def to_s
      self.categories.map { |cat| JSON.generate(cat.to_h) }.join("\n") << "\n"
    end

    class Category
      attr_accessor :subscriptions
      attr_reader :name, :id, :bg_color, :text_color

      def initialize(name: nil, _id: nil, bg_color: nil, text_color: nil, subscriptions: [])
        @name = name
        @id = _id
        @bg_color = bg_color
        @text_color = text_color
        @subscriptions = subscriptions.map { |sub| sub.is_a?(Subscription) ? sub : Subscription.new(**sub) }
      end

      def to_h
        { 'name' => @name,
          '_id' => @id,
          'bgColor' => @bg_color,
          'textColor' => @text_color,
          'subscriptions' => self.subscriptions.map(&:to_h) }
      end
    end

    class Subscription
      attr_reader :name

      def initialize(id: nil, name: nil, thumbnail: nil, selected: nil)
        @id = id
        @name = name
        @thumbnail = thumbnail
        @selected = selected
      end

      def eql?(other)
        @name == other.name
      end

      def hash
        @name.hash
      end

      def to_h
        { 'name' => @name, 'id' => @id, 'thumbnail' => @thumbnail }
      end
    end
  end
end
FreeTubeTools::SubscriptionMerger.run
