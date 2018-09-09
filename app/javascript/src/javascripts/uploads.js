import Post from './posts.js.erb'
import RelatedTag from './related_tag.js.erb'

let Upload = {};

Upload.initialize_all = function() {
  if ($("#c-uploads,#c-posts").length) {
    this.initialize_enter_on_tags();
    this.initialize_info_manual();
  }

  if ($("#c-uploads").length) {
    if ($("#image").prop("complete")) {
      this.initialize_image();
    } else {
      $("#image").on("load.danbooru error.danbooru", this.initialize_image);
    }
    this.initialize_info_bookmarklet();
    this.initialize_similar();
    this.initialize_submit();
    $("#related-tags-button").trigger("click");

    $("#toggle-artist-commentary").on("click.danbooru", function(e) {
      Upload.toggle_commentary();
      e.preventDefault();
    });
  }

  if ($("#iqdb-similar").length) {
    this.initialize_iqdb_source();
  }
}

Upload.initialize_submit = function() {
  $("#form").on("submit.danbooru", Upload.validate_upload);
}

Upload.validate_upload = function (e) {
  var error_messages = [];
  if (($("#upload_file").val() === "") && ($("#upload_source").val() === "") && $("#upload_md5_confirmation").val() === "") {
    error_messages.push("Must choose file or specify source");
  }
  if (!$("#upload_rating_s").prop("checked") && !$("#upload_rating_q").prop("checked") && !$("#upload_rating_e").prop("checked") &&
      ($("#upload_tag_string").val().search(/\brating:[sqe]/i) < 0)) {
    error_messages.push("Must specify a rating");
  }
  if (error_messages.length === 0) {
    $("#submit-button").prop("disabled", "true");
    $("#submit-button").prop("value", "Submitting...");
    $("#client-errors").hide();
  } else {
    $("#client-errors").html("<strong>Error</strong>: " + error_messages.join(", "));
    $("#client-errors").show();
    e.preventDefault();
  }
}

Upload.initialize_iqdb_source = function() {
  if (/^https?:\/\//.test($("#upload_source").val())) {
    $.get("/iqdb_queries", {"url": $("#upload_source").val()}).done(function(html) {$("#iqdb-similar").html(html)});
  }
}

Upload.initialize_enter_on_tags = function() {
  var $textarea = $("#upload_tag_string, #post_tag_string");
  var $submit = $textarea.parents("form").find('input[type="submit"]');

  $textarea.on("keydown.danbooru.submit", null, "return", function(e) {
    $submit.click();
    e.preventDefault();
  });
}

Upload.initialize_similar = function() {
  $("#similar-button").on("click.danbooru", function(e) {
    $.get("/iqdb_queries", {"url": $("#upload_source").val()}).done(function(html) {$("#iqdb-similar").html(html).show()});
    e.preventDefault();
  });
}

Upload.initialize_info_bookmarklet = function() {
  $("#upload_source").on("change.danbooru", function (e) {
    $("#fetch-data-manual").click();
  });

  $("#fetch-data-manual").click();
}

Upload.initialize_info_manual = function() {
  $("#fetch-data-manual").on("click.danbooru", function(e) {
    var source = $("#upload_source,#post_source").val();
    var referer = $("#upload_referer_url").val();

    if (/^https?:\/\//.test(source)) {
      $("#source-info span#loading-data").show();
      Upload.fetch_source_data(source, referer);
    }

    e.preventDefault();
  });
}

Upload.fetch_source_data = function(url, referer_url) {
  return $.getJSON("/source.json", { url: url, ref: referer_url })
    .then(Upload.fill_source_info)
    .catch(function(data) {
      $("#source-info span#loading-data").html("Error: " + data.responseJSON.message)
    });
}

Upload.fill_source_info = function(data) {
  $("#source-tags").empty();
  $.each(data.tags, function(i, v) {
    $("<a>").attr("href", v[1]).text(v[0]).appendTo("#source-tags");
  });

  $("#source-artist-profile").attr("href", data.profile_url).text(data.artist_name);

  RelatedTag.process_artist(data.artists);
  RelatedTag.translated_tags = data.translated_tags;
  RelatedTag.build_all();

  if (data.artists.length === 0) {
    var new_artist_params = $.param({
      artist: {
        name: data.unique_id,
        other_names: data.artist_name,
        url_string: $.uniqueSort([data.profile_url, data.normalized_for_artist_finder_url]).join("\n")
      }
    });

    var link = $("<a>").attr("href", "/artists/new?" + new_artist_params).text("Create new artist");
    $("#source-danbooru-artists").html(link);
  } else {
    var artistLinks = data.artists.map(function (artist) {
      return $('<a class="tag-type-1">').attr("href", "/artists/" + artist.id).text(artist.name);
    });

    $("#source-danbooru-artists").html(artistLinks)
  }

  if (data.image_urls.length > 1) {
    $("#gallery-warning").show();
  } else {
    $("#gallery-warning").hide();
  }

  $("#upload_artist_commentary_title").val(data.artist_commentary.dtext_title);
  $("#upload_artist_commentary_desc").val(data.artist_commentary.dtext_description);
  Upload.toggle_commentary();

  $("#source-info span#loading-data").hide();
  $("#source-info ul").show();
}

Upload.update_scale = function() {
  var $image = $("#image");
  var ratio = $image.data("scale-factor");
  if (ratio < 1) {
    $("#scale").html("Scaled " + parseInt(100 * ratio) + "% (original: " + $image.data("original-width") + "x" + $image.data("original-height") + ")");
  } else {
    $("#scale").html("Original: " + $image.data("original-width") + "x" + $image.data("original-height"));
  }
}

Upload.initialize_image = function() {
  var $image = $("#image");
  if (!$image.length) {
    return;
  }
  var width = $image.width();
  var height = $image.height();
  if (!width || !height) {
    // try again later
    $.timeout(100).done(function() {Upload.initialize_image()});
    return;
  }
  $image.data("original-width", width);
  $image.data("original-height", height);
  Post.resize_image_to_window($image);
  Post.initialize_post_image_resize_to_window_link();
  Upload.update_scale();
  $("#image-resize-to-window-link").on("click.danbooru", Upload.update_scale);
}

Upload.toggle_commentary = function() {
  if ($(".artist-commentary").is(":visible")) {
    $("#toggle-artist-commentary").text("show »");
  } else {
    $("#toggle-artist-commentary").text("« hide");
  }

  $(".artist-commentary").slideToggle();
};

$(function() {
  Upload.initialize_all();
});

export default Upload
