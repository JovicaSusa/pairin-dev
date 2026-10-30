module SystemHelpers
  # Opens the DatePicker popover behind `trigger_label` and clicks through to
  # `date`, navigating month-by-month (the calendar has no year/month jump).
  def select_calendar_date!(trigger_label, date)
    click_button trigger_label

    months_forward = (date.year - Date.current.year) * 12 + (date.month - Date.current.month)
    nav_label = months_forward.negative? ? "Go to previous month" : "Go to next month"

    within(".rdp") do
      months_forward.abs.times { click_button nav_label }
      find("button:not(.day-outside)", text: date.day.to_s, exact_text: true).click
    end
  end

  def select_option!(trigger_label, option_text)
    click_button trigger_label
    find('[role="option"]', text: option_text, exact_text: true).click
    expect(page).to have_button(option_text)
    expect(page).not_to have_css('[role="listbox"]')
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
end
