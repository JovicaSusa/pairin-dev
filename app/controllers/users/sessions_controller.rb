module Users
  class SessionsController < Devise::SessionsController
    private

    # The home page isn't part of the Inertia app, so logging out from inside it
    # needs a full page load. A plain redirect showed the home page in a modal
    # over the app.
    def respond_to_on_destroy
      return super unless request.inertia?

      inertia_location after_sign_out_path_for(resource_name)
    end
  end
end
