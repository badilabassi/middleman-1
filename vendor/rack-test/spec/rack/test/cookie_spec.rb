require File.dirname(__FILE__) + "/../../spec_helper"

describe Rack::Test::Session do
  def have_body(string)
    simple_matcher "have body #{string.inspect}" do |response|
      response.body.should == string
    end
  end

  context "cookies" do
    it "keeps a cookie jar" do
      get "/cookies/show"
      last_request.cookies.should == {}

      get "/cookies/set", "value" => "1"
      get "/cookies/show"
      last_request.cookies.should == { "value" => "1" }
    end

    it "doesn't send expired cookies" do
      get "/cookies/set", "value" => "1"
      now = Time.now
      Time.stub!(:now => now + 60)
      get "/cookies/show"
      last_request.cookies.should == {}
    end

    it "doesn't send cookies with the wrong domain" do
      get "http://www.example.com/cookies/set", "value" => "1"
      get "http://www.other.example/cookies/show"
      last_request.cookies.should == {}
    end

    it "doesn't send cookies with the wrong path" do
      get "/cookies/set", "value" => "1"
      get "/not-cookies/show"
      last_request.cookies.should == {}
    end

    it "persists cookies across requests that don't return any cookie headers" do
      get "/cookies/set", "value" => "1"
      get "/void"
      get "/cookies/show"
      last_request.cookies.should == { "value" => "1" }
    end

    it "deletes cookies" do
      get "/cookies/set", "value" => "1"
      get "/cookies/delete"
      get "/cookies/show"
      last_request.cookies.should == { }
    end

    xit "respects cookie domains when no domain is explicitly set" do
      request("http://example.org/cookies/count").should     have_body("1")
      request("http://www.example.org/cookies/count").should have_body("1")
      request("http://example.org/cookies/count").should     have_body("2")
      request("http://www.example.org/cookies/count").should have_body("2")
    end

    it "treats domains case insensitively" do
      get "http://example.com/cookies/set", "value" => "1"
      get "http://EXAMPLE.COM/cookies/show"
      last_request.cookies.should == { "value" => "1" }
    end

    it "treats paths case sensitively" do
      get "/cookies/set", "value" => "1"
      get "/COOKIES/show"
      last_request.cookies.should == {}
    end

    it "prefers more specific cookies" do
      get "http://example.com/cookies/set",     "value" => "domain"
      get "http://sub.example.com/cookies/set", "value" => "sub"

      get "http://sub.example.com/cookies/show"
      last_request.cookies.should == { "value" => "sub" }

      get "http://example.com/cookies/show"
      last_request.cookies.should == { "value" => "domain" }
    end

    it "treats cookie names case insensitively" do
      get "/cookies/set", "value" => "lowercase"
      get "/cookies/set-uppercase", "value" => "UPPERCASE"
      get "/cookies/show"
      last_request.cookies.should == { "VALUE" => "UPPERCASE" }
    end

    it "defaults the domain to the request domain" do
      get "http://example.com/cookies/set-simple", "value" => "cookie"
      get "http://example.com/cookies/show"
      last_request.cookies.should == { "simple" => "cookie" }

      get "http://other.example/cookies/show"
      last_request.cookies.should == {}
    end

    it "defaults the domain to the request path up to the last slash" do
      get "/cookies/set-simple", "value" => "1"
      get "/not-cookies/show"
      last_request.cookies.should == {}
    end

    it "supports secure cookies" do
      get "https://example.com/cookies/set-secure", "value" => "set"
      get "http://example.com/cookies/show"
      last_request.cookies.should == {}

      get "https://example.com/cookies/show"
      last_request.cookies.should == { "secure-cookie" => "set" }
    end

    it "keeps separate cookie jars for different domains" do
      get "http://example.com/cookies/set", "value" => "example"
      get "http://example.com/cookies/show"
      last_request.cookies.should == { "value" => "example" }

      get "http://other.example/cookies/set", "value" => "other"
      get "http://other.example/cookies/show"
      last_request.cookies.should == { "value" => "other" }

      get "http://example.com/cookies/show"
      last_request.cookies.should == { "value" => "example" }
    end

    it "allows cookies to be cleared" do
      get "/cookies/set", "value" => "1"
      clear_cookies
      get "/cookies/show"
      last_request.cookies.should == {}
    end

    it "allow cookies to be set" do
      set_cookie "value=10"
      get "/cookies/show"
      last_request.cookies.should == { "value" => "10" }
    end

    it "allows an array of cookies to be set" do
      set_cookie ["value=10", "foo=bar"]
      get "/cookies/show"
      last_request.cookies.should == { "value" => "10", "foo" => "bar" }
    end

    it "supports multiple sessions" do
      with_session(:first) do
        get "/cookies/set", "value" => "1"
        get "/cookies/show"
        last_request.cookies.should == { "value" => "1" }
      end

      with_session(:second) do
        get "/cookies/show"
        last_request.cookies.should == { }
      end
    end

    it "uses :default as the default session name" do
      get "/cookies/set", "value" => "1"
      get "/cookies/show"
      last_request.cookies.should == { "value" => "1" }

      with_session(:default) do
        get "/cookies/show"
        last_request.cookies.should == { "value" => "1" }
      end
    end

    it "accepts explicitly provided cookies" do
      request "/cookies/show", :cookie => "value=1"
      last_request.cookies.should == { "value" => "1" }
    end
  end
end