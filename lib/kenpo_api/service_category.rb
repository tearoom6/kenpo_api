module KenpoApi
  class ServiceCategory
    CATEGORIES = {
      resort_reserve:       '直営・通年・夏季保養施設(抽選申込)',
      resort_search_vacant: '直営・通年・夏季保養施設(空き照会)',
      sport_reserve:        'スポーツ施設(抽選申込)',
      sport_search_vacant:  'スポーツ施設(空き照会)',
      resort_alliance:      '契約保養施設（補助金対象施設）',
      travel_pack:          'ＩＴＳ旅行パック（補助申請）',
      golf_course:          'ＩＴＳ契約ゴルフ場',
      camp_site:            'ＩＴＳ契約オートキャンプ場',
      laforet:              'ラフォーレ倶楽部',
      thalassotherapy:      'タラソテラピー',
      recreation:           '体育奨励イベント',
    }

    attr_reader :category_code, :name, :path

    def initialize(name:, path:)
      @category_code = CATEGORIES.key(name)
      @name = name
      @path = path
    end

    def self.list
      Client.instance.fetch_document(path: '/service_category/index').xpath('//div[@class="request-box"]//a').map do |link|
        self.new(
          name: link.text,
          path: link['href'],
        )
      end
    end

    def self.find(category_code)
      self.list.find { |category| category.category_code == category_code }
    end

    def service_groups
      ServiceGroup.list(self)
    end

    def find_service_group(name)
      ServiceGroup.find(self, name)
    end

    def available?
      self.service_groups.any?
    end

  end
end
