require 'rubygems'
require 'bundler'
Bundler.setup(:default)
Bundler.require(:default)

module FreeTubeTools
  class SubscriptionMerger
    def self.run
      dbs = ARGV
      export_lists = dbs.map { |db| List.new(SubscriptionMerger.serialize(db)) }
      import_list = convert(export_lists, List.new)
      save(import_list)
    end

    def self.serialize(db)
      file = File.open("./#{db}", 'r', &:readlines)
      file.map! { |line| JSON.parse(line) }
      file.map { |hash| hash.deep_transform_keys { |key| key.underscore.to_sym } }
    end

    def self.convert(export_lists = [], import_list)
      export_lists.each do |e_list|
        e_list.categories.each do |e_cat|
          import_cat_matched = import_list.categories.find { |i_cat| i_cat.name == e_cat.name }

          if import_cat_matched
            import_cat_matched.subscriptions = import_cat_matched.subscriptions | e_cat.subscriptions
          else
            new_cat = List::Category.new(name: e_cat.name,
                                         _id: e_cat.id,
                                         bg_color: e_cat.bg_color,
                                         text_color: e_cat.text_color,
                                         subscriptions: e_cat.subscriptions)
            import_list.categories.push(new_cat)
          end
        end
      end
      import_list
    end

    def self.save(list)
      date = Time.now.strftime('%Y-%m-%d_%H%M')
      file = File.open("./ft_merged_#{date}.db", 'w')
      categories = list.categories.map { |c| JSON.generate(c.to_h) }
      file.write categories.join("\n") << "\n"
    end
  end

  class List
    attr_reader :categories

    def initialize(categories = [])
      @categories = categories.map { |c| Category.new(**c) }
    end

    class Category
      attr_accessor :subscriptions
      attr_reader :name, :id, :bg_color, :text_color

      def initialize(name: nil, _id: nil, bg_color: nil, text_color: nil, subscriptions: [])
        @name = name
        @id = _id
        @bg_color = bg_color
        @text_color = text_color
        @subscriptions = subscriptions.map { |s| s.is_a?(Subscription) ? s : Subscription.new(**s) }
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
