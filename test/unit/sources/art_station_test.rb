require 'test_helper'

module Sources
  class ArtStationTest < ActiveSupport::TestCase
    context "The source site for an art station artwork page" do
      setup do
        @site = Sources::Strategies.find("https://www.artstation.com/artwork/04XA4")
      end

      should "get the image url" do
        assert_equal("https://cdna.artstation.com/p/assets/images/images/000/705/368/large/jey-rain-one1.jpg", @site.image_url.sub(/\?\d+/, ""))
      end

      should "get the canonical url" do
        assert_equal("https://jeyrain.artstation.com/projects/04XA4", @site.canonical_url)
      end

      should "get the profile" do
        assert_equal("https://www.artstation.com/jeyrain", @site.profile_url)
      end

      should "get the artist name" do
        assert_equal("jeyrain", @site.artist_name)
      end

      should "get the tags" do
        assert_equal([], @site.tags)
      end

      should "get the artist commentary" do
        assert_equal("pink", @site.artist_commentary_title)
        assert_equal("", @site.dtext_artist_commentary_desc)
      end
    end

    context "The source site for an art station projects page" do
      setup do
        @site = Sources::Strategies.find("https://dantewontdie.artstation.com/projects/YZK5q")
      end

      should "get the image url" do
        url = "https://cdna.artstation.com/p/assets/images/images/006/066/534/large/yinan-cui-reika.jpg?1495781565"
        assert_equal(url, @site.image_url)
      end

      should "get the canonical url" do
        assert_equal("https://dantewontdie.artstation.com/projects/YZK5q", @site.canonical_url)
      end

      should "get the profile" do
        assert_equal("https://www.artstation.com/dantewontdie", @site.profile_url)
      end

      should "get the artist name" do
        assert_equal("dantewontdie", @site.artist_name)
      end

      should "get the tags" do
        assert_equal(%w[gantz Reika], @site.tags.map(&:first))
        assert_equal(%w[gantz reika], @site.normalized_tags)
      end

      should "get the artist commentary" do
        assert_equal("Reika ", @site.artist_commentary_title)
        assert_equal("From Gantz.", @site.dtext_artist_commentary_desc)
      end
    end

    context "The source site for a www.artstation.com/artwork/$slug page" do
      setup do
        @site = Sources::Strategies.find("https://www.artstation.com/artwork/cody-from-sf")
      end

      should "get the image url" do
        url = "https://cdna.artstation.com/p/assets/images/images/000/144/922/large/cassio-yoshiyaki-cody2backup2-yoshiyaki.jpg?1406314198"
        assert_equal(url, @site.image_url)
      end

      should "get the tags" do
        assert_equal(["Street Fighter", "Cody", "SF"].sort, @site.tags.map(&:first).sort)
        assert_equal(["street_fighter", "cody", "sf"].sort, @site.normalized_tags.sort)
      end
    end

    context "The source site for a http://cdna.artstation.com/p/assets/... url" do
      setup do
        @url = "https://cdna.artstation.com/p/assets/images/images/006/029/978/large/amama-l-z.jpg"
        @ref = "https://www.artstation.com/artwork/4BWW2"
      end

      context "with a referer" do
        should "work" do
          site = Sources::Strategies.find(@url, @ref)

          assert_equal(@url, site.image_url)
          assert_equal("https://amama.artstation.com/projects/4BWW2", site.page_url)
          assert_equal("https://amama.artstation.com/projects/4BWW2", site.canonical_url)
          assert_equal("https://www.artstation.com/amama", site.profile_url)
          assert_equal("amama", site.artist_name)
          assert_nothing_raised { site.to_h }
        end
      end

      context "without a referer" do
        should "work" do
          site = Sources::Strategies.find(@url)

          assert_equal(@url, site.image_url)
          assert_nil(site.page_url)
          assert_nil(site.profile_url)
          assert_nil(site.artist_name)
          assert_equal([], site.tags)
          assert_nothing_raised { site.to_h }
        end
      end
    end

    context "The source site for an ArtStation gallery" do
      setup do
        @site = Sources::Strategies.find("https://www.artstation.com/artwork/BDxrA")
      end

      should "get only image urls, not video urls" do
        urls = %w[https://cdnb.artstation.com/p/assets/images/images/006/037/253/large/astri-lohne-sjursen-eva.jpg?1495573664]
        assert_equal(urls, @site.image_urls)
      end
    end

    context "A work that has been deleted" do
      should "work" do
        url = "https://fiship.artstation.com/projects/x8n8XT"
        site = Sources::Strategies.find(url)

        assert_equal("fiship", site.artist_name)
        assert_equal("https://www.artstation.com/fiship", site.profile_url)
        assert_equal(url, site.page_url)
        assert_equal(url, site.canonical_url)
        assert_nil(site.image_url)
        assert_nothing_raised { site.to_h }
      end
    end
  end
end
