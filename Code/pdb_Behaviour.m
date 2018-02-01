function ga = pdb_Behaviour(task, isplot)
% Bharath Talluri & Anne Urai
% code accompanying the post-decision bias paper. This code reproduces
% figure 1 of the paper.
close all;
clc; dbstop if error;
% specify the color map and figure properties
cols = linspecer(9, 'qualitative');
myfigureprops;
figure;
% specify the path to the data
behdatapath = '../Data';
behdata = readtable(sprintf('%s/Task_%s.csv', behdatapath, task));
% initialise some variables
subjects = unique(behdata.subj)';
if strcmp(task, 'Perceptual')
    meanevidence = [];
    logisticPoints = NaN(length(subjects), 5);
    x = -20:0.1:20;
    xavg = [-20 -15 -10 -5 0 5 10 15 20];
    estimations = NaN(length(subjects), length(xavg));
end
for sj = subjects
    dat             =  behdata(find(behdata.subj == sj),:);
    if strcmp(task, 'Perceptual')
        % we get all behavioural measures for the perceptual task
        % use only choice trials in this paper
        trls2use = find(abs(dat.condition) == 1 & abs(dat.binchoice) == 1);
        dat = dat(trls2use,:);
        % get the indices for Choice trials
        estimtrls = find((dat.condition == 1 & abs(dat.binchoice) == 1));
        meanevidence = [meanevidence; dat.xavg(estimtrls)];
        % Psychometric function, we define the psychometric function below
        [bias, slope] = fitcumnormal((dat.x1), dat.binchoice>0);
        ga.logisticFit(sj, :)   = [bias, slope];
        dat2 = dat.binchoice;
        dat2(dat2<0) = 0;
        logisticPoints(sj, :) = splitapply(@nanmean, dat2, findgroups(dat.x1));
        % Estimations
        dat = dat(estimtrls,:);
        estimations(sj, :) = splitapply(@nanmedian, dat.estim, findgroups(dat.xavg));
    elseif strcmp(task, 'Cognitive')
        % we are only interested in the psychometric function fits for the
        % cognitive task. For other behavioural measures, refer to Bronfman et al., (2015) Proc. R. Soc. B Biol. Sci. 282, 20150228.
        choicetrls      = find(abs(data.condition) == 1);
        dat.relativex1 = dat.x1 - 50;
        dat.binchoice(dat.binchoice == 1) = -1;
        dat.binchoice(dat.binchoice == 2) = 1;
        dat.relativex1(dat.relativex1 < 0 & dat.relativex1 >= -2) = -1;
        dat.relativex1(dat.relativex1 < -2 & dat.relativex1 >= -4) = -2;
        dat.relativex1(dat.relativex1 < -4 & dat.relativex1 >= -6) = -3;
        dat.relativex1(dat.relativex1 < 2 & dat.relativex1 >= 0) = 1;
        dat.relativex1(dat.relativex1 < 4 & dat.relativex1 >= 2) = 2;
        dat.relativex1(dat.relativex1 < 6 & dat.relativex1 >= 3) = 3;
        % PSYCHOMETRIC FUNCTIONS
        [bias, slope] = fitcumnormal((dat.relativex1(choicetrls)), dat.binchoice(choicetrls)>0);
        
        ga.logisticFit(sj,:) = [bias, slope];
    end
end
%% SHOW THE DATA
if isplot
    subjectidx = 1:length(subjects);
    % psychometric functions
    subplot(4,4,1); hold on;
    plot([0 0],[0 1],'-','color',cols(8,:),'LineWidth',1);
    errbar([-20 -10 0 10 20], median(logisticPoints),std(logisticPoints) ./ sqrt(length(subjects)),'k-','LineWidth',1);
    plot(x, cumnormal(median(ga.logisticFit(subjectidx, :)), x), '-', 'color', [0 0 0],'MarkerSize',5);
    set(gca, 'XLim', [-20 20], 'XTick', -20:10:20, 'ylim',[0 1], 'ytick', 0.0:0.5:1.0);
    xlabel('Stimulus in interval 1 (degrees)'); ylabel('Proportion CW choices');
    axis square;
    offsetAxes;
    
    % Estimations as a function of mean evidence
    subplot(4,4,5); hold on;
    errbar(xavg,mean(estimations(subjectidx,:),1),std(estimations(subjectidx,:),1)/sqrt(length(subjects)),std(estimations(subjectidx,:),1)/sqrt(length(subjects)),'-','Color',[0 0 0],'LineWidth',0.5);
    plot(xavg,mean(estimations(subjectidx,:),1),'-','Color',[0 0 0],'LineWidth',1);
    plot(xavg,mean(estimations(subjectidx,:),1),'o','MarkerFaceColor',[0 0 0],'MarkerEdgeColor',[1 1 1],'MarkerSize',3);
    set(gca, 'XLim', [-20 20], 'XTick', -20:20:20, 'ylim',[-20 20], 'ytick', -20:20:20);
    ylabel('Estimation (degrees)');
    xlabel('Mean Direction (degrees)');
    axis square;EquateAxis;
    offsetAxes;
    
    % Histogram of mean evidence
    subplot(4,4,9);hold on;
    for i = xavg
        plot([i i], [0 length(find(meanevidence == i))],'k-','LineWidth',2);
    end
    ylabel ('Trials')
    xlabel('Mean Evidence (degrees)');
    axis square;
    set(gca, 'XLim', [-25 25], 'XTick', -20:20:20,'YLim',[0 5000],'YTick',0:2500:5000);
    offsetAxes;
end
end

%% Functions used above
function [bias, slope] = fitcumnormal(x,y)
% find the best fitting parameters for the psychometric function by
% maximising the loglikelihood across 10 random starting points for bias
% and slope parameters
niter = 10;
bias_start = datasample(-20:2:20,niter);
slope_start = datasample(0:5:50,niter);
iter_params = NaN(niter,2);
NegLLiter = NaN(niter,1);
for i = 1:niter
    iter_params(i,:) = fminsearchbnd(@(p) cumnormal_LL(p, ...
        x, y), [bias_start(i) slope_start(i)], [-100 0], [100 100],optimset('MaxFunEvals',1000000,'MaxIter',100000));
    NegLLiter(i) = cumnormal_LL(iter_params(i,:),x,y);
end
[~,idx] = min(NegLLiter);
bias        = iter_params(idx,1);
slope       = iter_params(idx,2);
end

function NegLL = cumnormal_LL(p, inputs, responses)
% see http://courses.washington.edu/matlab1/Lesson_5.html#1
% compute the vector of responses for each level of intensity
w   = cumnormal(p, inputs);
% negative loglikelihood, to be minimised
NegLL = -sum(responses.*log(w) + (1-responses).*log(1-w));
end


function y = cumnormal(p, x)
% Parameters: p(1) bias
%             p(2) slope
%             x   inputs.
y = normcdf(x,p(1),p(2));
end