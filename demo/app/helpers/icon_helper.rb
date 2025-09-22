module IconHelper
  def app_icon(name, **options)
    classes = options[:class] || options[:classes] || "w-6 h-6"
    title = options[:title] || options[:alt] || name.to_s.humanize

    content_tag :div, class: "inline-flex items-center justify-center" do
      raw(svg_icon_content(name, classes: classes, title: title))
    end
  end

  # Semantic helper methods for common UI icons
  def edit_icon(**options)
    app_icon(:edit, **options)
  end

  def delete_icon(**options)
    app_icon(:delete, **options)
  end

  def plus_icon(**options)
    app_icon(:plus, **options)
  end

  def view_icon(**options)
    app_icon(:view, **options)
  end

  def list_icon(**options)
    app_icon(:list, **options)
  end

  def search_icon(**options)
    app_icon(:search, **options)
  end

  def star_icon(**options)
    app_icon(:star, **options)
  end

  def book_icon(**options)
    app_icon(:book, **options)
  end

  def shopping_cart_icon(**options)
    app_icon(:shopping_cart, **options)
  end

  def payment_icon(**options)
    app_icon(:payment, **options)
  end

  def delivery_icon(**options)
    app_icon(:delivery, **options)
  end

  def gaming_icon(**options)
    app_icon(:gaming, **options)
  end

  def trophy_icon(**options)
    app_icon(:trophy, **options)
  end

  def users_icon(**options)
    app_icon(:users, **options)
  end

  def sparkle_icon(**options)
    app_icon(:sparkle, **options)
  end

  def rocket_icon(**options)
    app_icon(:rocket, **options)
  end

  def lightbulb_icon(**options)
    app_icon(:lightbulb, **options)
  end

  private

  def svg_icon_content(name, classes:, title:)
    icon_path = Rails.root.join("app/assets/images/icons/#{name}.svg")

    if File.exist?(icon_path)
      svg_content = File.read(icon_path)
      # Add classes and ensure proper accessibility
      svg_content.gsub('<svg', "<svg class=\"#{classes}\" aria-label=\"#{title}\"")
    else
      # Fallback to a simple icon if file doesn't exist
      <<~SVG
        <svg class="#{classes}" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-label="#{title}">
          <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2"/>
          <text x="12" y="16" text-anchor="middle" fill="currentColor" font-size="12">?</text>
        </svg>
      SVG
    end
  end
end