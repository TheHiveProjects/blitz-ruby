class Blitz
class Curl # :nodoc:
# Use this to run a rush (a load test) against your app. The return values
# include the entire timeline containing the average duration, the concurrency,
# the bytes sent/received, etc.
class Rush
    # Per-step (for transactional rushes) metrics of a rush at time[i]
    class Step
        # The duration of this step, when successful
        attr_reader :duration
        
        # Average TCP connect times for this step
        attr_reader :connect
        
        # Cummulative errors for this step
        attr_reader :errors
        
        # Cummulative timeouts for this step
        attr_reader :timeouts
        
        # Cummulative assertion failures on status code for this step
        attr_reader :asserts
        
        def initialize json
            @duration = json['d']
            @connect = json['c']
            @errors = json['e']
            @timeouts = json['t']
            @asserts = json['a']
        end
    end
    
    # Snapshot of a rush at time[i] containing information about hits, errors
    # timeouts, etc.
    class Point
        # The timestamp of this snapshot
        attr_reader :timestamp
        
        # The average response time at this time
        attr_reader :duration
        
        # The total number of hits that were generated
        attr_reader :total
        
        # The number of successful hits
        attr_reader :hits
        
        # The number of errors
        attr_reader :errors
        
        # The number of timeouts
        attr_reader :timeouts
        
        # The concurrency level at this time
        attr_reader :volume
        
        # The total number of bytes sent
        attr_reader :txbytes
        
        # The total number of bytes received
        attr_reader :rxbytes
        
        # Per-step metric at this point in time
        attr_reader :steps
        
        def initialize json # :nodoc:
            @timestamp = json['timestamp']
            @duration = json['duration']
            @total = json['total']
            @hits = json['executed']
            @errors = json['errors']
            @timeouts = json['timeouts']
            @volume = json['volume']
            @txbytes = json['txbytes']
            @rxbytes = json['rxbytes']
            @steps = json['steps'].map { |s| Step.new s }
        end
    end
    
    # Represents the results returned by the rush. Contains the entire timeline
    # of snapshot values from the rush as well as the region from which the
    # rush was executed.
    class Result
        # The region from which the rush was executed
        attr_reader :region
        
        # The timeline of the rush containing various statistics.
        attr_reader :timeline
        
        def initialize json # :nodoc:
            result = json['result']
            @region = result['region']
            @timeline = result['timeline'].map { |p| Point.new p }
        end        
    end
    
    # Primary method for running a rush. The args is very similar to what
    # the Sprint.execute method accepts, except this should also contain
    # the pattern. If a block is given, it's invoked periodically with the
    # partial results of the run (to report progress, perhaps)
    #
    #  result = Blitz::Curl.parse('-r california -p 10-50:30 www.example.com').execute do |partial|
    #      pp [ partial.region, partial.timeline.last.hits ]
    #  end
    #
    # You can easily export the result to JSON, XML or compute the various 
    # rates, etc.
    def execute &block # |result|
        queue
        result &block
    end
    
    def queue # :nodoc:
        if not args.member? 'pattern' and not args.member? :pattern
            raise ArgumentError, 'missing pattern'
        end

        res = Command::API.client.curl_execute args
        raise Error.new(res) if res['error']
        @job_id = res['job_id']
        @region = res['region']
    end
    
    attr_reader :job_id # :nodoc:
    attr_reader :region # :nodoc:
    attr_reader :args # :nodoc:
    
    def initialize args # :nodoc:
        @args = args
    end
    
    def result &block # :nodoc:
        last = nil
        while true
            sleep 2.0

            job = Command::API.client.job_status job_id
            if job['error']
                raise Error
            end
            
            result = job['result']
            next if job['status'] == 'queued'
            next if job['status'] == 'running' and not result

            raise Error if not result

            error = result['error']
            if error
                if error == 'dns'
                    raise Error::DNS.new(result)
                elsif error == 'authorize'
                    raise Error::Authorize.new(result)
                elsif error == 'parse'
                    raise Error::Parse.new(result)
                else
                    raise Error
                end
            end
            
            last = Result.new(job)
            continue = yield last rescue false
            if continue == false
                abort!
                break
            end
            
            break if job['status'] == 'completed'
        end
        
        return last
    end
    
    def abort! # :nodoc:
        Command::API.client.abort_job job_id rescue nil
    end   
end
end # Curl
end # Blitz
