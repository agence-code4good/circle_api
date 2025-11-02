module ApplicationHelper
  def svg_tag(name)
    file_path = "#{Rails.root}/app/assets/images/#{name}.svg"
    if File.exists?(file_path)
       File.read(file_path).html_safe
    else
      '(not found)'
    end
  end

  def render_turbo_stream_flash_messages
    turbo_stream.prepend "flash", partial: "shared/flashes"
  end
end
