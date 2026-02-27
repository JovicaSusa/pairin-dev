class ApplicationResource
  include Alba::Resource
  
  include Alba::Inertia::Resource

  def format_url(url)
    return url if url.blank?
    url.match?(/\Ahttps?:\/\//) ? url : "https://#{url}"
  end
end
