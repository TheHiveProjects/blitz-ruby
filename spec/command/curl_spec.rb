describe "parse_cli" do
    attr_reader :curl
    
    before :each do
        @curl = Blitz::Command::Curl.new
        class << @curl
            def parse args
                parse_cli args
            end
        end
    end
    
    context "url" do
        it "should check that the args are not empty" do
            lambda { curl.parse %w[] }.should raise_error(ArgumentError, /no URL specified!/)
        end
        
        it "should not check for URL when --help is specified" do
            %w[-h --help].each do |h|
                hash = curl.parse [h]
                hash.should include 'help'
            end
        end
        
        it "should succeed when a URL is given" do
            hash = curl.parse %w[blitz.io]
            hash.should include 'steps'
            hash['steps'].should be_a(Array)
            hash['steps'].size.should == 1
            hash['steps'].first.should include 'url'
            hash['steps'].first['url'].should == 'blitz.io'
        end
        
        it "should succeed when multiple URLs are given" do
            hash = curl.parse %w[blitz.io docs.blitz.io]
            hash.should include 'steps'
            hash['steps'].should be_a(Array)
            hash['steps'].size.should == 2
            hash['steps'][0].should include 'url'
            hash['steps'][0]['url'].should == 'blitz.io'
            hash['steps'][1].should include 'url'
            hash['steps'][1]['url'].should == 'docs.blitz.io'
        end
    end
    
    context "user-agent" do
        it "should check that a user-agent is given" do
            lambda { curl.parse %w[--user-agent] }.should raise_error(MiniTest::Assertion, /missing value/)
        end
        
        it "should support one user-agent for each step" do
            hash = curl.parse %w[-A foo blitz.io -A bar /faq]
            hash.should include 'steps'
            hash['steps'].size.should == 2
            hash['steps'][0]['user-agent'] == 'foo'
            hash['steps'][1]['user-agent'] == 'bar'
        end
    end
    
    context "cookie" do
        it "should check that a cookie is given" do
            lambda { curl.parse %w[--cookie] }.should raise_error(MiniTest::Assertion, /missing value/)
        end
        
        it "should be an array of cookies" do
            hash = curl.parse %w[--cookie foo=bar --cookie hello=world blitz.io]
            hash['steps'].size.should == 1
            step = hash['steps'].first
            step['cookies'].should be_a(Array)
            step['cookies'].should == [ 'foo=bar', 'hello=world' ]
        end
        
        it "should support one cookie for each step" do
            hash = curl.parse %w[-b foo=bar blitz.io -b hello=world /faq]
            hash.should include 'steps'
            hash['steps'].size.should == 2
            hash['steps'][0]['cookies'] == [ 'foo=bar' ]
            hash['steps'][1]['cookies'] == [ 'hello=world' ]
        end
    end
    
    context "data" do
        it "should check that a data is given" do
            lambda { curl.parse %w[--data] }.should raise_error(MiniTest::Assertion, /missing value/)
        end
        
        it "should be an array of data" do
            hash = curl.parse %w[--data foo=bar --data hello=world blitz.io]
            hash['steps'].size.should == 1
            step = hash['steps'].first
            step['content'].should be_a(Hash)
            step['content']['data'].should be_a(Array)
            step['content']['data'].should == [ 'foo=bar', 'hello=world' ]
        end
        
        it "should support one data for each step" do
            hash = curl.parse %w[-d foo=bar blitz.io -d hello=world /faq]
            hash.should include 'steps'
            hash['steps'].size.should == 2
            hash['steps'][0]['content']['data'] == [ 'foo=bar' ]
            hash['steps'][1]['content']['data'] == [ 'hello=world' ]
        end
    end
    
    context "referer" do
        it "should check that a referer is given" do
            lambda { curl.parse %w[--referer] }.should raise_error(MiniTest::Assertion, /missing value/)
        end
        
        it "should support one referer for each step" do
            hash = curl.parse %w[-e foo blitz.io -e bar /faq]
            hash.should include 'steps'
            hash['steps'].size.should == 2
            hash['steps'][0]['referer'] == 'foo'
            hash['steps'][1]['referer'] == 'bar'
        end
    end
    
    context "headers" do
        it "should check that a header is given" do
            lambda { curl.parse %w[--header] }.should raise_error(MiniTest::Assertion, /missing value/)
        end
        
        it "should be an array of headers" do
            hash = curl.parse %w[-H foo=bar -H hello=world blitz.io]
            hash['steps'].size.should == 1
            step = hash['steps'].first
            step['headers'].should be_a(Array)
            step['headers'].should == [ 'foo=bar', 'hello=world' ]
        end
        
        it "should support one header for each step" do
            hash = curl.parse %w[-H foo=bar blitz.io -H hello=world /faq]
            hash.should include 'steps'
            hash['steps'].size.should == 2
            hash['steps'][0]['headers'] == [ 'foo=bar' ]
            hash['steps'][1]['headers'] == [ 'hello=world' ]
        end
    end
    
    context "pattern" do
        it "should check that a pattern is given" do
            lambda { curl.parse %w[--pattern] }.should raise_error(MiniTest::Assertion, /missing value/)
        end
        
        it "should add the pattern to the hash" do
            hash = curl.parse %w[-p 1-250:60 blitz.io]
            hash['pattern'].should be_a(Hash)
            hash['pattern']['iterations'].should == 1
            hash['pattern']['intervals'].should be_an(Array)
            hash['pattern']['intervals'].size.should == 1
            hash['pattern']['intervals'].first['iterations'].should == 1
            hash['pattern']['intervals'].first['start'].should == 1
            hash['pattern']['intervals'].first['end'].should == 250
            hash['pattern']['intervals'].first['duration'].should == 60
        end
        
        it "should parse multiple intervals in the pattern" do
            hash = curl.parse %w[-p 1-250:60,500-500:10 blitz.io]
            hash['pattern'].should be_a(Hash)
            hash['pattern']['iterations'].should == 1
            hash['pattern']['intervals'].should be_an(Array)
            hash['pattern']['intervals'].size.should == 2
            hash['pattern']['intervals'].first['iterations'].should == 1
            hash['pattern']['intervals'].first['start'].should == 1
            hash['pattern']['intervals'].first['end'].should == 250
            hash['pattern']['intervals'].first['duration'].should == 60
            hash['pattern']['intervals'].last['iterations'].should == 1
            hash['pattern']['intervals'].last['start'].should == 500
            hash['pattern']['intervals'].last['end'].should == 500
            hash['pattern']['intervals'].last['duration'].should == 10
        end
    end
    
    context "region" do
        it "should check that a region is given" do
            lambda { curl.parse %w[--region] }.should raise_error(MiniTest::Assertion, /missing value/)
        end
        
        it "should verify that it's a valid region" do
            [ 'california', 'oregon', 'virginia', 'ireland', 'singapore', 'japan' ].each do |r|
                lambda { curl.parse ['-r', r, 'blitz.io' ] }.should_not raise_error
            end
                
            lambda { curl.parse %w[-r a ] }.should raise_error(MiniTest::Assertion, /must be one of/)
        end
    end
    
    context "status" do
        it "should check that a status is given" do
            lambda { curl.parse %w[--status] }.should raise_error(MiniTest::Assertion, /missing value/)
        end
        
        it "should support one status for each step" do
            hash = curl.parse %w[-s 302 blitz.io -s 200 /faq]
            hash.should include 'steps'
            hash['steps'].size.should == 2
            hash['steps'][0]['status'] == 302
            hash['steps'][1]['status'] == 200
        end
    end
    
    context "timeout" do
        it "should check that a timeout is given" do
            lambda { curl.parse %w[--timeout] }.should raise_error(MiniTest::Assertion, /missing value/)
        end
        
        it "should support one timeout for each step" do
            hash = curl.parse %w[-T 100 blitz.io -T 200 /faq]
            hash.should include 'steps'
            hash['steps'].size.should == 2
            hash['steps'][0]['timeout'] == 100
            hash['steps'][1]['timeout'] == 200
        end
    end
    
    context "user" do
        it "should check that a user is given" do
            lambda { curl.parse %w[--user] }.should raise_error(MiniTest::Assertion, /missing value/)
        end
        
        it "should support one user for each step" do
            hash = curl.parse %w[-u foo:bar blitz.io -u hello:world /faq]
            hash.should include 'steps'
            hash['steps'].size.should == 2
            hash['steps'][0]['user'] == 'foo:bar'
            hash['steps'][1]['user'] == 'hello:world'
        end
    end
    
    context "request" do
        it "should check that a request is given" do
            lambda { curl.parse %w[--request] }.should raise_error(MiniTest::Assertion, /missing value/)
        end
        
        it "should support one request for each step" do
            hash = curl.parse %w[-X GET blitz.io -X POST /faq]
            hash.should include 'steps'
            hash['steps'].size.should == 2
            hash['steps'][0]['request'] == 'GET'
            hash['steps'][1]['request'] == 'POST'
        end
    end
end