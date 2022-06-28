require 'json'

class FreeTubeDBMerger
  def self.merge
    FreeTubeDBMerger.new(*ARGV).run
  end

  def self.serialize(db)
    file = File.open("./#{db}", 'r', &:readlines)
    file.map { |line| JSON.parse(line) }
  end

  def initialize(db1, db2)
    @list1, @list2 = [db1, db2].map { |db| List.new(FreeTubeDBMerger.serialize(db)) }
    @unified_list = List.new([])
    @unified_subs = []
  end

  def run
    unify_categories
    unify_subs
    save_to_file
  end

  private

  def unify_categories
    categories1 = @list1.categories
    categories2 = @list2.categories
    unified_categories = (categories1 + categories2).uniq
    @unified_list.categories = unified_categories
  end

  def unify_subs
    @unified_list.categories.map do |u_c|
      cat1 = @list1.categories.find(proc { List::Category.new({}) }) { |c| c.name == u_c.name }
      cat2 = @list2.categories.find(proc { List::Category.new({}) }) { |c| c.name == u_c.name }
      u_c.subscriptions = (cat1.subscriptions + cat2.subscriptions).uniq
    end
  end

  def save_to_file
    date = Time.now.strftime('%Y-%m-%d_%H%M')
    file = File.new("./ft_merged_#{date}.db", 'w')
    @unified_list.categories.map! { |category| JSON.generate(category.to_h) }
    file.write @unified_list.categories.join("\n") << "\n"
    file.close
  end
end

class List
  attr_accessor :categories

  def initialize(categories)
    @categories = categories.map { |category| Category.new(category) }
  end

  class Category
    attr_accessor :subscriptions
    attr_reader :name

    def initialize(category)
      @name = category['name']
      @id = category['_id']
      @bg_color = category['bgColor']
      @text_color = category['textColor']
      @subscriptions = category.fetch('subscriptions', []).map { |subscription| Subscription.new(subscription) }
    end

    def eql?(other)
      @name == other.name
    end

    def hash
      @name.hash
    end

    def to_h
      { 'name' => @name,
        '_id' => @id,
        'bgColor' => @bg_color,
        'textColor' => @text_color,
        'subscriptions' => self.subscriptions.map(&:to_h) }
    end

    class Subscription
      attr_reader :name

      def initialize(subscriptions)
        @id = subscriptions['id']
        @name = subscriptions['name']
        @thumbnail = subscriptions['thumbnail']
        @selected = subscriptions['selected']
      end

      def eql?(other)
        @name == other.name
      end

      def hash
        @name.hash
      end

      def to_h
        atr = { 'name' => @name, 'id' => @id, 'thumbnail' => @thumbnail }
        atr['selected'] = @selected unless @selected.nil?
        atr
      end
    end
  end
end

FreeTubeDBMerger.merge
