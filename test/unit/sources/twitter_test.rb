require 'test_helper'

module Sources
  class TwitterTest < ActiveSupport::TestCase
    setup do
      skip "Twitter credentials are not configured" if !Sources::Strategies::Twitter.enabled?
    end

    context "An extended tweet" do
      should "extract the correct image url" do
        @site = Sources::Strategies.find("https://twitter.com/onsen_musume_jp/status/865534101918330881")
        assert_equal(["https://pbs.twimg.com/media/DAL-ntWV0AEbhes.jpg:orig"], @site.image_urls)
      end

      should "extract all the image urls" do
        @site = Sources::Strategies.find("https://twitter.com/aoimanabu/status/892370963630743552")

        urls = %w[
          https://pbs.twimg.com/media/DGJWp59UIAA_-en.jpg:orig
          https://pbs.twimg.com/media/DGJWqGLUwAAn2RL.jpg:orig
          https://pbs.twimg.com/media/DGJWqT_UMAAvmSK.jpg:orig
        ]

        assert_equal(urls, @site.image_urls)
      end
    end

    context "A video" do
      setup do
        @site = Sources::Strategies.find("https://twitter.com/CincinnatiZoo/status/859073537713328129")
      end

      should "get the correct urls" do
        assert_equal("https://video.twimg.com/ext_tw_video/859073467769126913/pu/vid/1280x720/cPGgVROXHy3yrK6u.mp4", @site.image_url)
        assert_equal("https://twitter.com/CincinnatiZoo/status/859073537713328129", @site.canonical_url)
      end
    end

    context "An animated gif" do
      setup do
        @site = Sources::Strategies.find("https://twitter.com/DaniStrawberry1/status/859435334765088769")
      end

      should "get the image url" do
        assert_equal("https://video.twimg.com/tweet_video/C-1Tns7WsAAqvqn.mp4", @site.image_url)
      end
    end

    context "A twitter summary card from twitter with a :large image" do
      setup do
        @site = Sources::Strategies.find("https://twitter.com/aranobu/status/817736083567820800")
      end

      should "get the image url" do
        assert_equal("https://pbs.twimg.com/media/C1kt72yVEAEGpOv.jpg:orig", @site.image_url)
      end

      should "get the preview url" do
        assert_equal("https://pbs.twimg.com/media/C1kt72yVEAEGpOv.jpg:small", @site.preview_url)
      end

      should "get the canonical url" do
        assert_equal("https://twitter.com/aranobu/status/817736083567820800", @site.canonical_url)
      end
    end

    context "The source site for a restricted twitter" do
      setup do
        @site = Sources::Strategies.find("https://mobile.twitter.com/Strangestone/status/556440271961858051")
      end

      should "get the urls" do
        assert_equal("https://pbs.twimg.com/media/B7jfc1JCcAEyeJh.png:orig", @site.image_url)
        assert_equal("https://twitter.com/Strangestone/status/556440271961858051", @site.page_url)
        assert_equal("https://twitter.com/Strangestone/status/556440271961858051", @site.canonical_url)
      end
    end

    context "A tweet without any images" do
      should "not fail" do
        @site = Sources::Strategies.find("https://twitter.com/teruyo/status/1058452066060853248")

        assert_nil(@site.image_url)
        assert_nothing_raised { @site.to_h }
      end
    end

    context "The source site for twitter" do
      setup do
        @site = Sources::Strategies.find("https://mobile.twitter.com/nounproject/status/540944400767922176")
      end

      should "get the main profile url" do
        assert_equal("https://twitter.com/nounproject", @site.profile_url)
      end

      should "get the profile urls" do
        assert_includes(@site.profile_urls, "https://twitter.com/nounproject")
        assert_includes(@site.profile_urls, "https://twitter.com/intent/user?user_id=88996186")
      end

      should "get the artist name" do
        assert_equal("nounproject", @site.artist_name)
      end

      should "get the image url" do
        assert_equal("https://pbs.twimg.com/media/B4HSEP5CUAA4xyu.png:orig", @site.image_url)
      end

      should "get the canonical url" do
        assert_equal("https://twitter.com/nounproject/status/540944400767922176", @site.canonical_url)
      end

      should "get the tags" do
        assert_equal([], @site.tags)
      end

      should "get the artist commentary" do
        assert_not_nil(@site.artist_commentary_desc)
      end

      should "convert a page into a json representation" do
        assert_nothing_raised do
          @site.to_json
        end
      end
    end

    context "The source site for a direct image and a referer" do
      setup do
        @site = Sources::Strategies.find("https://pbs.twimg.com/media/B4HSEP5CUAA4xyu.png:large", "https://twitter.com/nounproject/status/540944400767922176")
      end

      should "get the artist name" do
        assert_equal("nounproject", @site.artist_name)
      end

      should "get the image url" do
        assert_equal("https://pbs.twimg.com/media/B4HSEP5CUAA4xyu.png:orig", @site.image_url)
      end
    end

    context "The source site for a direct image url (pbs.twimg.com/media/*.jpg) without a referer url" do
      setup do
        @site = Sources::Strategies.find("https://pbs.twimg.com/media/B4HSEP5CUAA4xyu.png:large")
      end

      should "work" do
        assert_equal("https://pbs.twimg.com/media/B4HSEP5CUAA4xyu.png:orig", @site.image_url)
        assert_equal(["https://pbs.twimg.com/media/B4HSEP5CUAA4xyu.png:orig"], @site.image_urls)
        assert(@site.artist_name.blank?)
        assert(@site.profile_url.blank?)
        assert(@site.artists.empty?)
        assert(@site.tags.empty?)
        assert(@site.artist_commentary_desc.blank?)
        assert(@site.dtext_artist_commentary_desc.blank?)
        assert_nothing_raised { @site.to_h }
      end
    end

    context "The source site for a direct image url (pbs.twimg.com/media/*?format=jpg&name=*) without a referer url" do
      setup do
        @site = Sources::Strategies.find("https://pbs.twimg.com/media/EBGp2YdUYAA19Uj?format=jpg&name=small")
      end

      should "work" do
        assert_equal("https://pbs.twimg.com/media/EBGp2YdUYAA19Uj.jpg:orig", @site.image_url)
        assert_equal(["https://pbs.twimg.com/media/EBGp2YdUYAA19Uj.jpg:orig"], @site.image_urls)
        assert_equal("https://pbs.twimg.com/media/EBGp2YdUYAA19Uj.jpg:orig", @site.canonical_url)
      end

      should "work for filenames containing dashes" do
        @site = Sources::Strategies.find("https://pbs.twimg.com/media/EAjc-OWVAAAxAgQ.jpg", "https://twitter.com/asteroid_ill/status/1155420330128625664")
        assert_equal("https://pbs.twimg.com/media/EAjc-OWVAAAxAgQ.jpg:orig", @site.image_url)
      end
    end

    context "The source site for a https://twitter.com/i/web/status/:id url" do
      setup do
        @site = Sources::Strategies.find("https://twitter.com/i/web/status/943446161586733056")
      end

      should "fetch the source data" do
        assert_equal("https://twitter.com/motty08111213", @site.profile_url)
      end

      should "get the canonical url" do
        assert_equal("https://twitter.com/motty08111213/status/943446161586733056", @site.canonical_url)
      end
    end

    context "A deleted tweet" do
      should "still find the artist name" do
        @site = Sources::Strategies.find("https://twitter.com/masayasuf/status/870734961778630656")
        @artist = FactoryBot.create(:artist, name: "masayasuf", url_string: @site.url)

        assert_equal("masayasuf", @site.artist_name)
        assert_equal("https://twitter.com/masayasuf", @site.profile_url)
        assert_equal([@artist], @site.artists)
      end
    end

    context "A tweet" do
      setup do
        @site = Sources::Strategies.find("https://twitter.com/noizave/status/875768175136317440")
      end

      should "convert urls, hashtags, and mentions to dtext" do
        desc = 'test "#foo":[https://twitter.com/hashtag/foo] "#ホワイトデー":[https://twitter.com/hashtag/ホワイトデー] "@noizave":[https://twitter.com/noizave]\'s blah http://www.example.com <>& 😀'
        assert_equal(desc, @site.dtext_artist_commentary_desc)
      end

      should "get the tags" do
        tags = [
          %w[foo https://twitter.com/hashtag/foo],
          %w[ホワイトデー https://twitter.com/hashtag/ホワイトデー]
        ]

        assert_equal(tags, @site.tags)
      end
    end

    context "A tweet containing non-normalized Unicode text" do
      should "be normalized to nfkc" do
        site = Sources::Strategies.find("https://twitter.com/aprilarcus/status/367557195186970624")
        desc1 = "𝖸𝗈 𝐔𝐧𝐢𝐜𝐨𝐝𝐞 𝗅 𝗁𝖾𝗋𝖽 𝕌 𝗅𝗂𝗄𝖾 𝑡𝑦𝑝𝑒𝑓𝑎𝑐𝑒𝑠 𝗌𝗈 𝗐𝖾 𝗉𝗎𝗍 𝗌𝗈𝗆𝖾 𝚌𝚘𝚍𝚎𝚙𝚘𝚒𝚗𝚝𝚜 𝗂𝗇 𝗒𝗈𝗎𝗋 𝔖𝔲𝔭𝔭𝔩𝔢𝔪𝔢𝔫𝔱𝔞𝔯𝔶 𝔚𝔲𝔩𝔱𝔦𝔩𝔦𝔫𝔤𝔳𝔞𝔩 𝔓𝔩𝔞𝔫𝔢 𝗌𝗈 𝗒𝗈𝗎 𝖼𝖺𝗇 𝓮𝓷𝓬𝓸𝓭𝓮 𝕗𝕠𝕟𝕥𝕤 𝗂𝗇 𝗒𝗈𝗎𝗋 𝒇𝒐𝒏𝒕𝒔."
        desc2 = "Yo Unicode l herd U like typefaces so we put some codepoints in your Supplementary Wultilingval Plane so you can encode fonts in your fonts."

        assert_equal(desc1, site.artist_commentary_desc)
        assert_equal(desc2, site.dtext_artist_commentary_desc)
      end

      should "normalize full-width hashtags" do
        site = Sources::Strategies.find("https://twitter.com/corpsmanWelt/status/1037724260075069441")
        desc1 = %{新しいおともだち\n＃けものフレンズ https://t.co/sEAuu16yAQ}
        desc2 = %{新しいおともだち\n"#けものフレンズ":[https://twitter.com/hashtag/けものフレンズ]}

        assert_equal(desc1, site.artist_commentary_desc)
        assert_equal(desc2, site.dtext_artist_commentary_desc)
      end
    end

    context "A twitter post with a pixiv referer" do
      should "use the twitter strategy" do
        site = Sources::Strategies.find("https://twitter.com/Mityubi/status/849630665603665920", "https://www.pixiv.net/member_illust.php?mode=medium&illust_id=56735489")

        assert_equal(site.site_name, "Twitter")
        assert_equal("https://pbs.twimg.com/media/C8p-gPhVoAMZupS.png:orig", site.image_url)
      end
    end

    context "A tweet from a suspended user" do
      should "not fail" do
        site = Sources::Strategies.find("https://twitter.com/tanso_panz/status/1192429800717029377")

        assert_equal(site.site_name, "Twitter")
        assert_equal("tanso_panz", site.artist_name)
        assert_equal("https://twitter.com/tanso_panz", site.profile_url)
        assert_nil(site.image_url)
      end
    end
  end
end
