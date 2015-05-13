module Loyalty
  module ApplicationHelper
    def navigation_bar
      content_tag :nav, class: 'nav navbar-default' do
        content_tag :div, class: 'container-fluid' do
          loyalty_brand + navigation_items
        end
      end
    end

    def flash_messages
      return if flash.keys.empty?
      classes = {
        error: 'danger',
        notice: 'success'
      }

      flash.keys.map do |message|
        messages = parse_message(flash[message])
        messages = messages.join('<br>') if messages.is_a? Array
        content_tag :p, messages.html_safe, class: "alert alert-#{classes[message.to_sym]}"
      end.join.html_safe
    end

    private

    def parse_message(message)
      JSON.parse(message)
    rescue JSON::ParserError
      message
    end

    def items_data
      [
        { path: cards_path, name: 'Карты' },
        { path: certificates_path, name: 'Сертификаты' },
        { path: purchases_path, name: 'Продажи' },
        { path: gifts_path, name: 'Подарки' },
      ]
    end

    def loyalty_brand
      content_tag :div, class: 'navbar-header' do
        link_to 'Лояльность', root_path, class: 'navbar-brand'
      end
    end

    def navigation_items
      content_tag :ul, class: 'nav navbar-nav' do
        items_data.map do |item|
          content_tag :li do
            link_to item[:name], item[:path]
          end
        end.join.html_safe
      end
    end
  end
end
