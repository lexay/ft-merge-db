require 'rubygems'
require 'bundler'
Bundler.setup(:default)
Bundler.require(:default)

module FreeTubeTools
  class SubscriptionMerger
    def self.run
      lists = ARGV
      imported = lists.map { |list| List.new deserialize(list) }
      merged = merge(imported, List.new)
      save(merged)
    end

    def self.deserialize(db)
      lines = File.open("./#{db}", 'r', &:readlines)
      lines.map do |line|
        hash = JSON.parse(line)
        hash.deep_transform_keys { |key| key.underscore.to_sym }
      end
    end

    def self.merge(imported = [], merged)
      imported.each do |list|
        list.categories.each do |i_cat|
          match = merged.categories.find { |m_cat| m_cat == i_cat }

          if match
            match.subscriptions = match.subscriptions.union(i_cat.subscriptions)
          else
            merged.categories.push i_cat
          end
        end
      end
      merged
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

      def initialize(name:, _id:, bg_color:, text_color:, subscriptions: [])
        @name = name
        @id = _id
        @bg_color = bg_color
        @text_color = text_color
        @subscriptions = subscriptions.map { |sub| Subscription.new(**sub) }
      end

      def to_h
        { 'name' => @name,
          '_id' => @id,
          'bgColor' => @bg_color,
          'textColor' => @text_color,
          'subscriptions' => self.subscriptions.map(&:to_h) }
      end

      def eql?(other)
        self == other
      end

      def ==(other)
        self.id == other.id
      end

      def hash
        self.id.hash
      end

      class Subscription
        attr_reader :name, :id

        def initialize(id:, name:, thumbnail:, selected: false)
          @id = id
          @name = name
          @thumbnail = thumbnail
          @selected = selected
        end

        def eql?(other)
          self == other
        end

        def ==(other)
          self.id == other.id && self.name == other.name
        end

        def hash
          self.id.hash ^ self.name.hash
        end

        def to_h
          { 'name' => @name, 'id' => @id, 'thumbnail' => @thumbnail }
        end
      end
    end
  end
end
FreeTubeTools::SubscriptionMerger.run
