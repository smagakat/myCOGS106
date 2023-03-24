classdef SignalDetection
    properties
        Hits
        Misses
        FalseAlarms
        CorrectRejections
    end

    methods
        function obj = SignalDetection(Hits, Misses, FalseAlarms, ...
                CorrectRejections)
            obj.Hits = Hits;
            obj.Misses = Misses;
            obj.FalseAlarms = FalseAlarms;
            obj.CorrectRejections = CorrectRejections;
        end

        function HitRate = HitRate(obj)
            HitRate = obj.Hits / (obj.Hits + obj.Misses);
        end

        function FARate = FARate(obj)
            FARate = obj.FalseAlarms / (obj.FalseAlarms + ...
                obj.CorrectRejections);
        end

        function D_Prime = D_Prime(obj)
            D_Prime = norminv(obj.HitRate) - norminv(obj.FARate);
        end

        function Criterion = Criterion(obj)
            Criterion = -0.5 * (norminv(obj.HitRate) + norminv(obj.FARate));
        end

        %% Override 
        function Total = plus(obj1, obj2)
            Total = SignalDetection(obj1.Hits + obj2.Hits, obj1.Misses + ...
                obj2.Misses, obj1.FalseAlarms + obj2.FalseAlarms, ...
                obj1.CorrectRejections + obj2.CorrectRejections);
        end

        function Scaled = mtimes(obj, k)
            Scaled = SignalDetection(obj.Hits * k, obj.Misses * k, ...
                obj.FalseAlarms * k, obj.CorrectRejections * k);
        end


        %% Plots
        function Plot_SDT = Plot_SDT(obj)
            x = [-5:.1:5];
            Noise = normpdf(x, 0, 1);
            Signal = normpdf(x, obj.D_Prime, 1);
            
            plot(x, Noise, x, Signal)
            xline(obj.D_Prime/2 + obj.Criterion, '--k', 'HandleVisibility','off')
            line([0 obj.D_Prime],[max(Noise), max(Signal)])
            ylim([0, .5])
            xlabel('Signal Strength')
            ylabel('Probability')
            legend('Noise', 'Signal')
            title('Signal Detection Theory Plot')
        end

        %% Log Likelihood
        function nLogLikelihood = nLogLikelihood(obj, HitRate, FARate)
            nLogLikelihood = - (obj.Hits*log(HitRate) + obj.Misses*log(1 - HitRate)...
                + obj.FalseAlarms*log(FARate) + obj.CorrectRejections*...
                log(1 - FARate));
        end
    end

    methods (Static)
        function sdtList = simulate(dprime, criteriaList, ...
                signalCount, noiseCount)
            sdtList = [];
            for i = 1:length(criteriaList)
                criterion_k = criteriaList(i) + (dprime / 2);
                hit_rate = 1 - normcdf(criterion_k - dprime);
                fa_rate = 1 - normcdf(criterion_k);

                Hits = binornd(signalCount, hit_rate);
                Misses = signalCount - Hits;
                FalseAlarms = binornd(noiseCount, fa_rate);
                CorrectRejections = noiseCount - FalseAlarms;

                sdtList = [sdtList; SignalDetection(Hits, Misses,...
                    FalseAlarms, CorrectRejections)];
            end
        end

        function plot_roc = plot_roc(sdtList)
            x = zeros(1, length(sdtList));
            y = zeros(1, length(sdtList));
            for i = 1:length(sdtList)
                x(i) = FARate(sdtList(i));
                y(i) = HitRate(sdtList(i));
            end
            scatter(x, y, 'filled', 'MarkerFaceColor', 'k');
            line([0, 1], [0, 1], 'LineStyle', '--');

            xlim([0, 1]);
            ylim([0, 1]);
            xlabel('False Alarm Rate')
            ylabel('Hit Rate')
            title('ROC Curve')
        end

        function hitRate = rocCurve(falseAlarmRate, a)
            hitRate = zeros(1, length(falseAlarmRate));
            for i = 1:length(falseAlarmRate)
                hitRate = normcdf(a + norminv(falseAlarmRate));
            end
        end

        function rocLoss = rocLoss(a, sdtList)
            ell = [];
            for i = 1:length(sdtList)
                obs_FARate = FARate(sdtList(i));
                pre_HitRate = SignalDetection.rocCurve(obs_FARate, a);
                ell = [ell; nLogLikelihood(sdtList(i), pre_HitRate, obs_FARate)];
            end
            rocLoss = sum(ell);
        end

        function fit_roc = fit_roc(sdtList)
            fun = @(a)SignalDetection.rocLoss(a, sdtList);
            start = 0;
            fit_roc = fminsearch(fun, start);

            FitCurve_x = linspace(0,1);
            FitCurve_y = SignalDetection.rocCurve(FitCurve_x, fit_roc);
            plot(FitCurve_x, FitCurve_y, 'LineWidth', 2, 'Color', 'r');
            hold on
            SignalDetection.plot_roc(sdtList);
        end
    end
end
