# KenpoApi

Ruby binding for kenpo reservation API ([関東ITソフトウェア健康保険組合 施設・レクリエーション](https://as.its-kenpo.or.jp/)).

[![Travis](https://img.shields.io/travis/tearoom6/kenpo_api.svg)](https://travis-ci.org/tearoom6/kenpo_api)
[![Gem](https://img.shields.io/gem/dtv/kenpo_api.svg)](https://rubygems.org/gems/kenpo_api)
![license](https://img.shields.io/github/license/tearoom6/kenpo_api.svg)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kenpo_api'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kenpo_api

## Usage

```ruby
# Resort reservation
resort_names = KenpoApi::Resort.resort_names
KenpoApi::Resort.request_reservation_url(resort_name: 'トスラブ箱根和奏林', email: 'matsuno_osomatsu@example.com')
url = 'https://as.its-kenpo.or.jp/apply/new?c=aaaaaaaa-bbbb-cccc-dddd-012345678901'
criteria = KenpoApi::Resort.check_reservation_criteria(url)
reservation_data = {
  sign_no:       6666,
  insured_no:    666,
  office_name:   '株式会社FLAG',
  kana_name:     'マツノ オソマツ',
  birth_year:    1962,
  birth_month:   5,
  birth_day:     24,
  gender:        :man,
  relationship:  :myself,
  contact_phone: '666-6666-6666',
  postal_code:   '180-0004',
  state:         13,
  address:       '武蔵野市本町666-666',
  join_time:     '2017-04-15',
  night_count:   1,
  stay_persons:  6,
  room_persons:  6, (1 room) # or [3, 3] (2 rooms) or [2, 2, 2] (3 rooms) ...
  meeting_dates: nil, # (none) or [1] (first day only) or [1, 2] (both days) ...
  must_meeting:  false,
}
KenpoApi::Resort.apply_reservation(url, reservation_data)

# Sport reservation
sport_names = KenpoApi::Sport.sport_names
KenpoApi::Sport.request_reservation_url(sport_name: 'サマディ門前仲町', email: 'matsuno_osomatsu@example.com')
url = 'https://as.its-kenpo.or.jp/apply/new?c=aaaaaaaa-bbbb-cccc-dddd-901234567890'
criteria = KenpoApi::Sport.check_reservation_criteria(url)
reservation_data = {
  sign_no:       6666,
  insured_no:    666,
  office_name:   '株式会社FLAG',
  kana_name:     'マツノ オソマツ',
  birth_year:    1962,
  birth_month:   5,
  birth_day:     24,
  contact_phone: '666-6666-6666',
  postal_code:   '180-0004',
  state:         13,
  address:       '武蔵野市本町666-666',
  join_time:     '2017-03-11',
  use_time_from: '13:00',
  use_time_to:   '15:00',
}
KenpoApi::Sport.apply_reservation(url, reservation_data)

# Low-level APIs
category = KenpoApi::ServiceCategory.find(:resort_reserve)
category.available?
category.service_groups

group = KenpoApi::ServiceGroup.find(category, 'トスラブ箱根ビオーレ')
group.available?
group.services
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Use Docker env

```sh
$ docker-compose up -d
$ docker-compose exec ruby sh

# # Start interactive console.
# pry --gem
# # Execute tests.
# rake spec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tearoom6/kenpo_api.

