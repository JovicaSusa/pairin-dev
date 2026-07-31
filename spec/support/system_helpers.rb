module SystemHelpers
  # Picks a date in the following month (always in the future) and a time
  # slot, for the period DatePicker + Select combo on the pair request form.
  def pick_future_period!(day: "15", time: "00:15")
    click_button "Pick a date"
    within(".rdp") do
      click_button "Go to next month"
      click_button day
    end

    click_button "Time"
    find('[role="option"]', text: time, exact_text: true).click
    expect(page).to have_button(time)
    expect(page).not_to have_css('[role="listbox"]')
  end

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
