classdef Metropolis
    properties
        samples % Retained samples
    end
    
    properties (Access = private)
        logTarget % Log of the target distribution
        state % Current state of the Markov chain
        stepSize % Step size of the proposal distribution
        acceptanceRate % Current acceptance rate
    end
    
    
    methods

        function self = Metropolis(logTarget, initialState)
            self.logTarget = logTarget;
            self.state = initialState;
            self.stepSize = 1;
            self.acceptanceRate = 0;
            self.samples = [];
        end
        
        function self = adapt(self, blockLengths)
            for i = 1:length(blockLengths)
                % Run a block of iterations
                for j = 1:blockLengths(i)
                    % Propose a new state
                    proposal = self.state + self.stepSize * randn();
                    % Check whether to accept or reject the proposal
                    if accept(self, proposal)
                        self.state = proposal;
                    end
                end
                
                % Update the step size based on the acceptance rate
                self.acceptanceRate = sum(diff(self.samples) ~= 0) / length(self.samples);
                if self.acceptanceRate > 0.4
                    self.stepSize = self.stepSize * exp(1/length(self.samples));
                else
                    self.stepSize = self.stepSize / exp(1/length(self.samples));
                end
            end
        end
        
        function self = sample(self, n)
            for i = 1:n
                % Propose a new state
                proposal = self.state + self.stepSize * randn();
                % Check whether to accept or reject the proposal
                if accept(self, proposal)
                    self.state = proposal;
                end
                % Retain the current state
                self.samples(end+1) = self.state;
            end
        end
        
        function summ = summary(self)
            summ.mean = mean(self.samples);
            summ.c025 = prctile(self.samples, 2.5);
            summ.c975 = prctile(self.samples, 97.5);
        end

    end
    

    methods (Access = private)
        function yesno = accept(self, proposal)
            % Calculate the log of the acceptance probability
            logAcceptProb = log(rand()) <= min(0, self.logTarget(proposal) - self.logTarget(self.state));
            % Accept or reject the proposal based on the acceptance probability
            if logAcceptProb
                yesno = true;
            else
                yesno = false;
            end

        end
    end
end

