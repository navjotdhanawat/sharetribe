module RatyHelper
  def stars_rating_tag(average, options={})
    dimension    = "quality"
    read_only    = options[:readonly]     || true
    show_quantity= options[:show_quantity]|| false
    star         = options[:star]         || 5
    enable_half  = options[:enable_half]  || false
    half_show    = options[:half_show]    || true
    star_path    = options[:star_path]    || "/assets"
    star_on      = options[:star_on]      || "star-on.png"
    star_off     = options[:star_off]     || "star-off.png"
    star_half    = options[:star_half]    || "star-half.png"
    cancel       = options[:cancel]       || false
    cancel_place = options[:cancel_place] || "left"
    cancel_hint  = options[:cancel_hint]  || "Cancel current rating!"
    cancel_on    = options[:cancel_on]    || "cancel-on.png"
    cancel_off   = options[:cancel_off]   || "cancel-off.png"
    noRatedMsg   = options[:noRatedMsg]   || "I am read-only and I haven't rated yet!"
    # round        = options[:round]        || { down: .26, full: .6, up: .76 }
    space        = options[:space]        || false
    single       = options[:single]       || false
    target       = options[:target]       || ''
    targetText   = options[:targetText]   || ''
    targetType   = options[:targetType]   || 'hint'
    targetFormat = options[:targetFormat] || '{score}'
    targetScore  = options[:targetScore]  || '#non-existing'
    scoreName    = options[:scoreName]    || 'DETACHED'
    averageAsDefault = options[:averageAsDefault].nil? ? true : !!options[:averageAsDefault]

    disable_after_rate = options[:disable_after_rate] && true
    disable_after_rate = true if disable_after_rate == nil

    if show_quantity
      total_quantity = quantity
    else
      total_quantity = false
    end

    html_class   = options[:class] || ''
    html_base_class = "star"
    html_class = html_class.present? ? "#{html_base_class} #{html_class}" : html_base_class

    content_tag :div, '', "data-dimension" => dimension, :class => html_class,
                "data-rating" => (averageAsDefault ? average : nil),
                "data-disable-after-rate" => disable_after_rate,
                "data-readonly" => read_only,
                "data-enable-half" => enable_half,
                "data-half-show" => half_show,
                "data-star-count" => star,
                "data-star-path" => star_path,
                "data-star-on" => star_on,
                "data-star-off" => star_off,
                "data-star-half" => star_half,
                "data-cancel" => cancel,
                "data-cancel-place" => cancel_place,
                "data-cancel-hint"  => cancel_hint,
                "data-cancel-on" => cancel_on,
                "data-cancel-off" => cancel_off,
                "data-no-rated-message" => noRatedMsg,
                # "data-round" => round,
                "data-space" => false,
                "data-single" => single,
                "data-target" => target,
                "data-target-text" => targetText,
                "data-target-type" => targetType,
                "data-target-format" => targetFormat,
                "data-target-score" => targetScore,
                "data-score-name" => scoreName,
                "data-url-transaction" => '/',
                "data-quantity" => total_quantity
  end
end
