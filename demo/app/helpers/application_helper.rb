module ApplicationHelper
  def format_currency(amount)
    return "N/A" unless amount
    "$" + sprintf('%.2f', amount)
  end

  def format_date(date)
    return "N/A" unless date
    date.strftime("%B %d, %Y")
  end

  def truncate_with_tooltip(text, length: 50)
    return "N/A" unless text
    if text.length > length
      content_tag :span, truncate(text, length: length), title: text
    else
      text
    end
  end
end
