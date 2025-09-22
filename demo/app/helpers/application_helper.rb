module ApplicationHelper
  def flash_class(type)
    case type.to_sym
    when :notice, :success then 'success'
    when :alert, :error then 'danger'
    when :warning then 'warning'
    else 'info'
    end
  end

  def format_currency(amount)
    number_to_currency(amount)
  end

  def format_date(date)
    date.strftime("%B %d, %Y") if date
  end
end
