classdef SignalDetection2
    properties
        hits
        misses
        falseAlarms
        correctRejections
    end

    methods
        function obj = SignalDetection2(hits, misses, falseAlarms, correctRejections)
            obj.hits = hits;
            obj.misses = misses;
            obj.falseAlarms = falseAlarms;
            obj.correctRejections = correctRejections; 
        end
	
	function H = hit_rate(obj)
            % calculate hit rate (H)
            H = obj.hits/(obj.hits + obj.misses);
	end
 
	function  FA = FA(obj)
            % calculate false alarm rate (FA)
            FA = obj.falseAlarms/(obj.falseAlarms + obj.correctRejections);
	end
   
        function d_prime = d_prime(obj)
           % calculate d-prime
            d_prime =  norminv(hit_rate(obj)) - norminv(obj.FA());
        end

        function criterion = criterion(obj)
            hitRate = obj.hits / (obj.hits + obj.misses);
            falseAlarmRate = obj.falseAlarms / (obj.falseAlarms + obj.correctRejections);
            criterion = -0.5 * (norminv(hitRate) + norminv(falseAlarmRate));
        end
    end
end
