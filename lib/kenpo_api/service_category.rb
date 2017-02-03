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

    attr_reader :name, :text, :path

    def initialize(text:, path:)
      @name = CATEGORIES.key(text)
      @text = text
      @path = path
    end

    def self.list
      Client.instance.fetch_document(path: '/service_category/index').xpath('//div[@class="request-box"]//a').map do |link|
        self.new(
          text: link.text,
          path: link['href'],
        )
      end
    end

    def self.find(name)
      self.list.find { |category| category.name == name }
    end

    def service_groups
      ServiceGroup.list(self)
    end

    def find_service_group(text)
      ServiceGroup.find(self, text)
    end

    def available?
      self.service_groups.any?
    end

  end
end
