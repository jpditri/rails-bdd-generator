# Application-specific icon helper with custom SVG icons
module IconHelper
  # Primary icon method - renders SVG icons with proper accessibility
  def app_icon(name, **options)
    classes = options[:class] || options[:classes] || "w-6 h-6"
    title = options[:title] || options[:alt] || name.to_s.humanize

    content_tag :div, class: "inline-flex items-center justify-center" do
      raw(svg_icon_content(name, classes: classes, title: title))
    end
  end

  private

  def svg_icon_content(name, classes:, title:)
    icon_path = Rails.root.join('app', 'assets', 'images', 'icons', "#{name}.svg")

    if File.exist?(icon_path)
      svg_content = File.read(icon_path)
      # Add classes and title to the SVG
      svg_content.gsub('<svg', "<svg class='#{classes}' title='#{title}'")
    else
      # Fallback to a generic icon if specific icon doesn't exist
      fallback_icon(classes: classes, title: title)
    end
  end

  def fallback_icon(classes:, title:)
    <<~SVG
      <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="#{classes}" title="#{title}">
        <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2"/>
        <path d="M12 6v6l4 2" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>
    SVG
  end

  # Semantic helper methods for common actions
  def success_icon(**options)
    app_icon(:success, **options)
  end

  def error_icon(**options)
    app_icon(:error, **options)
  end

  def info_icon(**options)
    app_icon(:info, **options)
  end

  def warning_icon(**options)
    app_icon(:warning, **options)
  end

  def edit_icon(**options)
    app_icon(:edit, **options)
  end

  def delete_icon(**options)
    app_icon(:delete, **options)
  end

  def add_icon(**options)
    app_icon(:add, **options)
  end

  def search_icon(**options)
    app_icon(:search, **options)
  end

  # Entity-specific icon helpers

def user_icon(**options)
  app_icon(:user, **options)
end

end
