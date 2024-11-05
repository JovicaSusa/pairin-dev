module ApplicationHelper
  include Pagy::Frontend

  def form_with_combobox(object, *args, &block)
    options = args.extract_options!
    simple_form_for(object, *(args << options.merge(builder: Forms::WithCombobox)), &block)
  end
end
